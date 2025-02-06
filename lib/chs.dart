import 'dart:io';
import 'package:chs/dot_chsconfig_file.dart';
import 'package:chs/errors.dart';
import 'package:chs/hook_content.dart';
import 'package:chs/yaml_config.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import 'const.dart';
import 'logger.dart';
import 'utils.dart';

Future<void> uninstall() async {
  final process = logger.progress("Uninstalling hooks...");
  final chsConfig = await DotCHSConfigFile.getConfig();

  if (chsConfig == null) {
    process.finish(message: "Hooks uninstalled!");
    return;
  }

  await _deleteHookFiles(chsConfig.filePaths);
  await chsConfig.delete();

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
  final chsConfig = await DotCHSConfigFile.getConfig();
  final yamlConfig = await YamlConfig.parse();
  gitUrl ??= chsConfig?.gitUrl ?? yamlConfig.gitUrl;

  if (gitUrl == null) {
    throw GitUrlNotSpecifiedException();
  }

  gitRef ??= yamlConfig.ref;
  final hookEntries = yamlConfig.hooksEntries;

  logger.stdout("Starting installation...");

  final clonedHooksDir = await getTemporaryDirectory();
  await cloneHooksRepo(gitUrl, gitRef, clonedHooksDir);

  await _writeHooks(hookEntries, clonedHooksDir, gitUrl);

  logger.stdout("Cleaning up...");
  await clonedHooksDir.delete(recursive: true);
  logger.stdout("Installation completed successfully!");
  exit(0);
}

Future<void> _writeHooks(Map<String, String> hooksEntries,
    Directory clonedHooksDir, String gitUrl) async {
  final localHooksDir = await getLocalHooksDir();
  final configContents = <String>{};
  final process = logger.progress("Copying files...");

  await _copyHookFiles(clonedHooksDir, localHooksDir, configContents);
  await _replaceHookContents(hooksEntries, localHooksDir, configContents);

  process.finish(message: "Files copied");
  await _writeConfigFile(gitUrl, configContents);
}

Future<void> _copyHookFiles(
    Directory srcDir, Directory destDir, Set<String> configContents) async {
  for (final entity in await srcDir.list().toList()) {
    final name = basename(entity.path);
    if (entity is Directory) {
      if (name != kDotGit) {
        await copyPath(entity.path, join(destDir.path, name));
        configContents.add(name);
      }
    } else if (entity is File) {
      await File(join(destDir.path, name))
          .writeAsString(await entity.readAsString());
      configContents.add(name);
    }
  }
}

Future<void> _replaceHookContents(Map<String, String> hooksEntries,
    Directory localHooksDir, Set<String> configContents) async {
  final hookContents = <String, HookContent>{};

  await _removeExistingHooks(localHooksDir, hookContents, configContents);
  await _applyCustomHookOverrides(
      localHooksDir, hooksEntries, hookContents, configContents);
  await _writeUpdatedHooks(localHooksDir, hookContents, configContents);
}

Future<void> _removeExistingHooks(Directory localHooksDir,
    Map<String, HookContent> hookContents, Set<String> configContents) async {
  final existingFiles =
      (await localHooksDir.list().toList()).whereType<File>().toList();

  for (final file in existingFiles) {
    final baseName = basename(file.path);
    final hookName = basenameWithoutExtension(file.path);

    if (kHooksSignature.contains(hookName)) {
      hookContents[hookName] = HookContent(await file.readAsString());
      await file.delete();
      configContents.remove(baseName);
    }
  }
}

Future<void> _applyCustomHookOverrides(
    Directory localHooksDir,
    Map<String, String> hooksEntries,
    Map<String, HookContent> hookContents,
    Set<String> configContents) async {
  for (final entry in hooksEntries.entries) {
    final hookName = entry.key;
    final sourceFilePath = join(localHooksDir.path, entry.value);

    if (!kHooksSignature.contains(hookName)) continue;

    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw FileNotFoundException(sourceFilePath);
    }

    hookContents[hookName] = HookContent(sourceFile.path, isSymlink: true);
  }
}

Future<void> _writeUpdatedHooks(Directory localHooksDir,
    Map<String, HookContent> hookContents, Set<String> configContents) async {
  for (final entry in hookContents.entries) {
    final hookFilePath = join(localHooksDir.path, entry.key);

    if (entry.value.isSymlink) {
      final link = Link(hookFilePath);
      await link.create(entry.value.content);
      await executeCommand('chmod', ['+x', entry.value.content]);
      configContents.add(entry.value.content);
    } else {
      final file = File(hookFilePath);
      await file.writeAsString(entry.value.content);
      configContents.add(entry.key);
    }

    if (!Platform.isWindows) {
      await executeCommand('chmod', ['+x', hookFilePath]);
    }
  }
}

Future<void> _writeConfigFile(String gitUrl, Set<String> configContents) async {
  logger.stdout("Writing config file...");
  final configFile =
      DotCHSConfigFile(gitUrl: gitUrl, filePaths: configContents.toList());
  await configFile.writeConfig();
  logger.stdout("Hooks installed successfully!");
}
