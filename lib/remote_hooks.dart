import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

import 'file_helper.dart';
import 'git_helper.dart';
import 'hooks_ignore/hooks_ignore.dart';
import 'process_helper.dart';
import 'remote_hooks_config.dart';
import 'errors.dart';
import 'logger.dart';
import 'yaml_config.dart';

class RemoteHooks {
  final processHelper = ProcessHelper();
  late final fileHelper = FileHelper(processHelper: processHelper);
  late final gitHelper =
      GitHelper(processHelper: processHelper, fileHelper: fileHelper);

  late final hooksIgnore = HooksIgnore(fileHelper: fileHelper);
  late final hooksConfig = RemoteHooksConfig(fileHelper: fileHelper);
  late final yamlConfig = YamlConfig(gitHelper: gitHelper);

  Future<void> install({String? gitUrl, String? gitRef}) async {
    final localHookDirectory = await gitHelper.getLocalHooksDirectory();
    await hooksConfig.loadConfig(directory: localHookDirectory);

    if (hooksConfig.gitUrl != null) {
      await uninstall();
    }

    await yamlConfig.load(directory: await gitHelper.gitDirectoryRoot);
    gitUrl ??= hooksConfig.gitUrl ?? yamlConfig.gitUrl;
    hooksConfig.gitUrl = gitUrl;

    if (gitUrl == null) {
      throw GitUrlNotSpecifiedException();
    }

    gitRef ??= yamlConfig.ref;

    logger.stdout("Starting installation...");

    final tempDirectory = await fileHelper.createTemporaryDirectory();
    await gitHelper.cloneRepository(gitUrl, gitRef, tempDirectory);

    await hooksIgnore.loadFromDirectory(tempDirectory);

    final List<String> filePaths = [];
    await fileHelper.copy(tempDirectory, localHookDirectory,
        shouldCopy: (entity, _) {
      final name = basename(entity.path);
      if ({
        HooksIgnore.kDotGit,
        HooksIgnore.kGitIgnore,
        HooksIgnore.kHooksIgnore
      }.contains(name)) {
        return false;
      }
      if (hooksIgnore.shouldIgnore(
          join(relative(entity.path, from: tempDirectory.path), '.'))) {
        return false;
      }
      return true;
    }, postCopy: (entity, depth) async {
      if (depth != 0 || entity is! File) {
        filePaths.add(relative(entity.path, from: localHookDirectory.path));
        return;
      }
      final fileNameWithoutExtension = basenameWithoutExtension(entity.path);
      if (GitHelper.kHooksSignature.contains(fileNameWithoutExtension)) {
        final hookFile = await entity
            .copy(join(entity.parent.path, fileNameWithoutExtension));
        await fileHelper.makeExecutable(hookFile);
        filePaths.add(fileNameWithoutExtension);
      } else {
        filePaths.add(relative(entity.path, from: localHookDirectory.path));
      }
    });
    hooksConfig.filePaths = filePaths;

    await hooksIgnore.writeToDirectory(localHookDirectory);
    await hooksConfig.writeConfig(directory: localHookDirectory);

    await gitHelper.executePostInstall(localHookDirectory);

    logger.stdout("Cleaning up...");
    await tempDirectory.delete(recursive: true);
    logger.stdout("Installation completed successfully!");
    exit(0);
  }

  Future<void> uninstall() async {
    final localHookDirectory = await gitHelper.getLocalHooksDirectory();

    logger.stdout("Uninstalling hooks...");

    await hooksConfig.loadConfig(directory: localHookDirectory);
    await hooksIgnore.loadFromDirectory(localHookDirectory);

    await gitHelper.executePreUninstall(localHookDirectory);
    await hooksIgnore.cleanIgnored(localHookDirectory);
    await hooksConfig.cleanUpFiles(localHookDirectory);

    logger.stdout("Hooks uninstalled!");
  }

  Future<void> exitOnFail(FutureOr<void> func) async {
    try {
      await func;
    } catch (err) {
      logger.stderr(err.toString());
      exit(1);
    }
  }
}
