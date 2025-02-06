import 'dart:async';
import 'dart:io';

import 'package:chs/utils.dart';
import 'package:path/path.dart';

import 'const.dart';

class DotCHSConfigFile {
  DotCHSConfigFile({
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
    file = File(join(localHooksDir.path, kChsConfig));
    final configContents = [gitUrl, ...filePaths].join('\n');
    await file!.writeAsString(configContents);
  }

  static Future<DotCHSConfigFile?> getConfig() async {
    final hooksDir = await _getGitHooksDirectory();
    final chsConfig = File(join(hooksDir.path, kChsConfig));

    if (!await chsConfig.exists()) return null;

    final lines = (await chsConfig.readAsLines())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    return DotCHSConfigFile(
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
