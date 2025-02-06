import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import 'const.dart';
import 'utils.dart';

class DotRemoteHooksConfigFile {
  DotRemoteHooksConfigFile({
    required this.gitUrl,
    this.filePaths = const [],
    this.file,
  });

  String gitUrl;
  List<String> filePaths;
  File? file;

  String? get path => file?.path;

  Future<void> delete() async {
    if (file == null) return;
    try {
      await file!.delete();
    } catch (e) {
      stderr.writeln("Error deleting config file: $e");
    }
  }

  Future<void> writeConfig() async {
    final localHooksDir = await _getGitHooksDirectory();
    file = File(join(localHooksDir.path, kRemoteHooksConfig));
    final configContents = [gitUrl, ...filePaths].join('\n');
    await file!.writeAsString(configContents);
  }

  static Future<DotRemoteHooksConfigFile?> getConfig() async {
    final hooksDir = await _getGitHooksDirectory();
    final chsConfig = File(join(hooksDir.path, kRemoteHooksConfig));

    if (!await chsConfig.exists()) return null;

    final lines = (await chsConfig.readAsLines())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    return DotRemoteHooksConfigFile(
      gitUrl: lines.first,
      filePaths: lines.skip(1).toList(),
      file: chsConfig,
    );
  }

  static Future<Directory> _getGitHooksDirectory() async {
    final repositoryRoot = await getGitDirectoryRoot();
    return Directory(join(repositoryRoot, '.git/hooks'));
  }
}
