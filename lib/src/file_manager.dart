import 'dart:io';

import 'package:path/path.dart';

typedef FileSystemEntityVisitor = Future<void> Function(
  FileSystemEntity entity,
  int depth,
);

typedef ShouldVisit = bool Function(FileSystemEntity source, int depth);
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
    ShouldVisit? shouldVisitEntity,
    int depth,
  ) async {
    if (!directory.existsSync()) {
      return;
    }
    await for (final entity in directory.list()) {
      final shouldVisit = shouldVisitEntity?.call(entity, depth) ?? true;
      if (shouldVisit) {
        await visitor.call(entity, depth);
      }
      if (entity is Directory && shouldVisit) {
        await _performVisit(
          entity.absolute,
          visitor,
          shouldVisitEntity,
          depth + 1,
        );
      }
    }
  }

  Future<void> visit(
    Directory directory,
    FileSystemEntityVisitor visitor, {
    ShouldVisit? shouldVisit,
  }) async {
    return _performVisit(directory, visitor, shouldVisit, 0);
  }

  Future<void> copy(
    Directory source,
    Directory destination, {
    ShouldVisit? shouldCopy,
    PostCopy? postCopy,
  }) async {
    if (!source.existsSync()) {
      return;
    }
    if (!destination.existsSync()) {
      await destination.create();
    }
    await visit(
      source,
      (entity, depth) async {
        final relativePath = relative(entity.path, from: source.path);
        if (entity is Directory) {
          final newDirectory =
              Directory(join(destination.absolute.path, relativePath));
          await newDirectory.create();
          await postCopy?.call(newDirectory, depth);
        } else if (entity is File) {
          final copied =
              await entity.copy(join(destination.path, relativePath));
          await postCopy?.call(copied, depth);
        }
      },
      shouldVisit: shouldCopy,
    );
  }
}
