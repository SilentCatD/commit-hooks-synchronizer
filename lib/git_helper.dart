import 'dart:io';

import 'package:path/path.dart';
import 'package:remote_hooks/file_helper.dart';
import 'package:remote_hooks/process_helper.dart';

class GitHelper {
  GitHelper({
    required this.processHelper,
    required this.fileHelper,
  });

  /// Set of supported Git hooks
  static const Set<String> kHooksSignature = {
    "applypatch-msg",
    "commit-msg",
    "fsmonitor-watchman",
    "post-update",
    "pre-applypatch",
    "pre-commit",
    "pre-merge-commit",
    "pre-push",
    "pre-rebase",
    "pre-receive",
    "prepare-commit-msg",
    "push-to-checkout",
    "update",
    // new supported
    "post-install",
    "post-uninstall",
  };

  static const postInstall = 'post-install';
  static const postUninstall = 'post-uninstall';

  final ProcessHelper processHelper;
  final FileHelper fileHelper;
  Directory? _gitDirectoryRoot;

  Future<Directory> get gitDirectoryRoot async {
    if (_gitDirectoryRoot != null) {
      return _gitDirectoryRoot!;
    }
    final rootPath = await processHelper.executeCommand(
        'git', ['rev-parse', '--show-toplevel'],
        processMessage: "Locating repository root");
    _gitDirectoryRoot ??= Directory(rootPath);
    return _gitDirectoryRoot!;
  }

  Future<void> setCoreHooksPath(Directory directory) async {
    final repositoryRoot = await gitDirectoryRoot;
    final relativePath = relative(directory.path, from: repositoryRoot.path);
    await processHelper.executeCommand(
      "git",
      ["config", "core.hooksPath", relativePath],
      workingDirectory: repositoryRoot.path,
    );
  }

  Future<Directory> getLocalHooksDirectory() async {
    final repositoryRoot = await gitDirectoryRoot;
    final directory = Directory((join(repositoryRoot.path, '.git/hooks')));
    if (!await directory.exists()) {
      await directory.create();
    }
    await setCoreHooksPath(directory);
    return directory;
  }

  Future<void> executePostInstall(Directory directory) async {
    final file = File(join(directory.path, postInstall));
    await processHelper.executeFileIfExist(file);
  }

  Future<void> executePreUninstall(Directory directory) async {
    final file = File(join(directory.path, postUninstall));
    await processHelper.executeFileIfExist(file);
  }

  Future<void> cloneRepository(
      String gitUrl, String? ref, Directory cloneDir) async {
    await processHelper.executeCommand('git', ['clone', gitUrl, cloneDir.path],
        processMessage: "Cloning $gitUrl");
    if (ref != null) {
      await processHelper.executeCommand('git', ['checkout', ref],
          workingDirectory: cloneDir.path,
          processMessage: "Checking out ref: $ref");
    }
  }
}
