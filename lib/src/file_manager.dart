import 'dart:io';

import 'package:path/path.dart';

typedef FileSystemEntityVisitor = Future<bool> Function(
  FileSystemEntity entity,
  int depth,
);

typedef ShouldCopy = bool Function(FileSystemEntity source, int depth);
typedef PostCopy = Future<void> Function(FileSystemEntity entity, int depth);

class FileManager {
  static const tempDirPrefix = 'remotehooks-';

  File? loadFile({required String path}) {
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<String?> loadFileAsString({required String path}) async {
    final file = loadFile(path: path);
    if (file == null) {
      return null;
    }
    final contents = await file.readAsString();
    return contents;
  }

  Future<Directory> createTemporaryDirectory([Directory? directory]) async {
    return (directory ?? Directory.systemTemp).createTemp(tempDirPrefix);
  }

  Future<void> _performVisit(
    Directory directory,
    FileSystemEntityVisitor visitor,
    int depth,
  ) async {
    if (!directory.existsSync()) {
      return;
    }
    await for (final entity in directory.list()) {
      if (entity is Directory) {
        final shouldVisitChildren = await visitor.call(entity, depth);
        if (!shouldVisitChildren) {
          continue;
        }
        await _performVisit(entity.absolute, visitor, depth + 1);
      } else if (entity is File) {
        await visitor.call(entity, depth);
      }
    }
  }

  Future<void> visit(
    Directory directory,
    FileSystemEntityVisitor visitor,
  ) async {
    return _performVisit(directory, visitor, 0);
  }

  Future<void> copy(
    Directory source,
    Directory destination, {
    ShouldCopy? shouldCopy,
    PostCopy? postCopy,
  }) async {
    if (!source.existsSync()) {
      return;
    }
    if (!destination.existsSync()) {
      await destination.create();
    }
    await visit(source, (entity, depth) async {
      final relativePath = relative(entity.path, from: source.path);
      final shouldCopyEntity = shouldCopy?.call(entity, depth) ?? true;
      if (!shouldCopyEntity) {
        return false;
      }
      if (entity is Directory) {
        final newDirectory =
            Directory(join(destination.absolute.path, relativePath));
        await newDirectory.create();
        await postCopy?.call(newDirectory, depth);
      } else if (entity is File) {
        final copied = await entity.copy(join(destination.path, relativePath));
        await postCopy?.call(copied, depth);
      }
      return true;
    });
  }
}
