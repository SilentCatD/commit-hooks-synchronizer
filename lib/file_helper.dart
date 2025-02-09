import 'dart:io';

import 'package:path/path.dart';
import 'package:remote_hooks/logger.dart';
import 'package:remote_hooks/process_helper.dart';
import 'package:uuid/uuid.dart';

// return false to stop visit children
typedef FileSystemEntityVisitor = Future<bool> Function(
    FileSystemEntity entity, int depth);

typedef ShouldCopy = bool Function(FileSystemEntity source, int depth);
typedef PostCopy = Future<void> Function(FileSystemEntity entity, int depth);

class FileHelper {
  final ProcessHelper processHelper;

  FileHelper({required this.processHelper});

  Future<Directory> createTemporaryDirectory() async {
    final tempDirPath =
        join(Directory.systemTemp.path, "TemporaryDirectory-${Uuid().v4()}");
    final tempDir = Directory(tempDirPath);
    await tempDir.create();
    return tempDir;
  }

  Future<void> _performVisit(
      Directory directory, FileSystemEntityVisitor visitor, int depth) async {
    await for (var entity in directory.list(recursive: false)) {
      if (entity is Directory) {
        final shouldVisitChildren = await visitor.call(entity, depth);
        if (!shouldVisitChildren) {
          continue;
        }
        // visitor may delete entity
        if (await entity.exists()) {
          await _performVisit(entity.absolute, visitor, depth + 1);
        }
      } else if (entity is File) {
        await visitor.call(entity, depth);
      }
    }
  }

  Future<void> visit(
      Directory directory, FileSystemEntityVisitor visitor) async {
    return _performVisit(directory, visitor, 0);
  }

  Future<void> copy(Directory source, Directory destination,
      {ShouldCopy? shouldCopy, PostCopy? postCopy}) async {
    await visit(source, (entity, depth) async {
      final name = basename(entity.path);
      final shouldCopyEntity = shouldCopy?.call(entity, depth) ?? true;
      if (!shouldCopyEntity) {
        return false;
      }
      if (entity is Directory) {
        var newDirectory = Directory(join(destination.absolute.path, name));
        await newDirectory.create();
        await postCopy?.call(newDirectory, depth);
      } else if (entity is File) {
        final copied = await entity.copy(join(destination.path, name));
        await postCopy?.call(copied, depth);
      }
      return true;
    });
  }

  Future<void> makeExecutable(File file) async {
    if (!Platform.isWindows) {
      await processHelper.executeCommand('chmod', ['+x', file.path],
          processMessage: "Granting ${basename(file.path)} execute permission");
    }
  }
}
