import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import 'file_helper.dart';

class RemoteHooksConfig {
  RemoteHooksConfig({
    this.gitUrl,
    List<String> filePaths = const [],
    required this.fileHelper,
  }) {
    this.filePaths.addAll(filePaths);
  }

  String? gitUrl;
  List<String> filePaths = [];
  final FileHelper fileHelper;
  static const String kRemoteHooksConfig = '.remotehooks';

  Future<void> cleanUpFiles(Directory directory) async {
    await fileHelper.visit(directory, (entity, depth) async {
      if (depth != 0) {
        return false;
      }
      final relativePath = relative(entity.path);
      if (filePaths.contains(relativePath) ||
          relativePath == kRemoteHooksConfig) {
        await entity.delete();
      }
      return true;
    });
  }

  Future<File> writeConfig({required Directory directory}) async {
    final file = File(join(directory.path, kRemoteHooksConfig));
    final configContents = [gitUrl, ...filePaths].join('\n');
    await file.writeAsString(configContents);
    return file;
  }

  Future<void> loadConfig({required Directory directory}) async {
    final configFile = File(join(directory.path, kRemoteHooksConfig));

    if (!await configFile.exists()) return;

    final lines = (await configFile.readAsLines())
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return;
    }
    gitUrl = lines.first;
    filePaths.addAll(lines.skip(1));
  }
}
