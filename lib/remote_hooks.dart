import 'dart:io';
import 'package:path/path.dart';

import 'const.dart';
import 'dot_remote_hooks_config_file.dart';
import 'errors.dart';
import 'ignore.dart';
import 'logger.dart';
import 'utils.dart';
import 'yaml_config.dart';

Future<void> uninstall() async {
  final process = logger.progress("Uninstalling hooks...");
  final chsConfig = await DotRemoteHooksConfigFile.getConfig();

  if (chsConfig == null) {
    process.finish(message: "Hooks uninstalled!");
    return;
  }

  await _deleteHookFiles(chsConfig.filePaths);
  await chsConfig.delete();
  final hooksDir = await getLocalHooksDir();
  await _runUninstallScript(hooksDir);

  process.finish(message: "Hooks uninstalled!");
}

Future<void> _deleteHookFiles(List<String> filePaths) async {
  if (filePaths.isEmpty) return;

  final hooksDir = await getLocalHooksDir();
  final pathsToDelete = filePaths.toSet();
  final hookDirEntities = await hooksDir.list().toList();

  for (final entity in hookDirEntities) {
    if (pathsToDelete.contains(basename(entity.path))) {
      await entity.delete(recursive: true);
    }
  }
}

Future<void> install({String? gitUrl, String? gitRef}) async {
  final remoteHooksConfigFile = await DotRemoteHooksConfigFile.getConfig();

  if (remoteHooksConfigFile != null) {
    await uninstall();
  }

  final yamlConfig = await YamlConfig.parse();
  gitUrl ??= remoteHooksConfigFile?.gitUrl ?? yamlConfig.gitUrl;

  if (gitUrl == null) {
    throw GitUrlNotSpecifiedException();
  }

  gitRef ??= yamlConfig.ref;

  logger.stdout("Starting installation...");

  final clonedHooksDir = await getTemporaryDirectory();
  await cloneHooksRepo(gitUrl, gitRef, clonedHooksDir);

  await _writeHooks(clonedHooksDir, gitUrl);

  logger.stdout("Cleaning up...");
  await clonedHooksDir.delete(recursive: true);
  logger.stdout("Installation completed successfully!");
  exit(0);
}

Future<void> _writeHooks(Directory clonedHooksDir, String gitUrl) async {
  final localHooksDir = await getLocalHooksDir();
  final configContents = <String>{};
  final process = logger.progress("Copying files...");

  final ignorePatterns = await loadIgnorePatterns(clonedHooksDir);
  final ignores = Ignore(ignorePatterns);
  await _copyHookFiles(
      clonedHooksDir, clonedHooksDir, localHooksDir, configContents, ignores);
  await _replaceHookContents(clonedHooksDir, localHooksDir, configContents);
  await _replaceInstallAndUninstallFiles(
      clonedHooksDir, localHooksDir, configContents);
  await _replaceInstallAndUninstallFiles(
      clonedHooksDir, localHooksDir, configContents);
  process.finish(message: "Files copied");
  await _writeConfigFile(gitUrl, configContents);
  logger.stdout("Hooks installed successfully!");
  await _runInstallScript(localHooksDir);
}

Future<void> _replaceInstallAndUninstallFiles(Directory clonedHooksDir,
    Directory localHookDir, Set<String> configContents) async {
  final existingFiles =
      (await clonedHooksDir.list().toList()).whereType<File>().toList();

  final Map<String, String> scripts = {};

  for (final file in existingFiles) {
    final fileName = basename(file.path);
    final scriptName = basenameWithoutExtension(file.path);

    if ({kHooksInstallScripts, kHooksUninstallScripts}.contains(scriptName)) {
      final localFile = File(join(localHookDir.path, fileName));
      scripts[scriptName] = await localFile.readAsString();
      configContents.remove(fileName);
      configContents.add(scriptName);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }
  }

  for (final scriptEntry in scripts.entries) {
    final localFile = File(join(localHookDir.path, scriptEntry.key));
    await localFile.writeAsString(scriptEntry.value);
    await _makeExecutable(localFile.path);
  }
}

Future<void> _runInstallScript(Directory localDir) async {
  final installFile = File(join(localDir.path, kHooksInstallScripts));
  if (!await installFile.exists()) {
    return;
  }
  logger.stdout("Running install script...");
  await Process.run(installFile.path, []);
}

Future<void> _runUninstallScript(Directory localDir) async {
  final uninstallFile = File(join(localDir.path, kHooksUninstallScripts));
  if (!await uninstallFile.exists()) {
    return;
  }
  logger.stdout("Running uninstall script...");
  await Process.run(uninstallFile.path, []);
}

// https://gist.github.com/thosakwe/681056e86673e73c4710cfbdfd2523a8
Future<void> _copyHookFiles(Directory rootSrcDir, Directory srcDir,
    Directory destDir, Set<String> configContents, Ignore ignores) async {
  await for (var entity in srcDir.list(recursive: false)) {
    final name = basename(entity.path);
    final rootRelative = relative(entity.path, from: rootSrcDir.path);
    if (entity is Directory) {
      if (name == kDotGit) {
        continue;
      }
      if (ignores.ignores(join(rootRelative, '.'))) {
        continue;
      }
      var newDirectory = Directory(join(destDir.absolute.path, name));
      await newDirectory.create();
      configContents.add(rootRelative);
      await _copyHookFiles(
          rootSrcDir, entity.absolute, newDirectory, configContents, ignores);
    } else if (entity is File) {
      if (ignores.ignores(rootRelative)) {
        continue;
      }
      if (name == kHooksIgnore) {
        continue;
      }
      if (name == kGitIgnore) {
        continue;
      }
      await entity.copy(join(destDir.path, name));
      configContents.add(rootRelative);
    }
  }
}

Future<void> _replaceHookContents(Directory clonedHooksDir,
    Directory localHooksDir, Set<String> configContents) async {
  final hookContents = <String, String>{};

  await _removeExistingHooks(
      clonedHooksDir, localHooksDir, hookContents, configContents);
  await _writeUpdatedHooks(localHooksDir, hookContents, configContents);
}

Future<void> _removeExistingHooks(
    Directory clonedHooksDir,
    Directory localHookDir,
    Map<String, String> hookContents,
    Set<String> configContents) async {
  final existingFiles =
      (await clonedHooksDir.list().toList()).whereType<File>().toList();

  for (final file in existingFiles) {
    final fileName = basename(file.path);
    final hookName = basenameWithoutExtension(file.path);

    if (kHooksSignature.contains(hookName)) {
      hookContents[hookName] = await file.readAsString();
      final localHookFile = File(join(localHookDir.path, fileName));
      if (await localHookFile.exists()) {
        await localHookFile.delete();
      }
    }
  }
}

Future<void> _writeUpdatedHooks(Directory localHooksDir,
    Map<String, String> hookContents, Set<String> configContents) async {
  for (final entry in hookContents.entries) {
    final hookFilePath = join(localHooksDir.path, entry.key);

    final file = File(hookFilePath);
    await file.writeAsString(entry.value);
    configContents.add(entry.key);
    await _makeExecutable(hookFilePath);
  }
}

Future<void> _makeExecutable(String path) async {
  if (!Platform.isWindows) {
    await executeCommand('chmod', ['+x', path]);
  }
}

Future<void> _writeConfigFile(String gitUrl, Set<String> configContents) async {
  logger.stdout("Writing config file...");
  final configFile = DotRemoteHooksConfigFile(
      gitUrl: gitUrl, filePaths: configContents.toList());
  await configFile.writeConfig();
}
