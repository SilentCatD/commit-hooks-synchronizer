import 'dart:io';

typedef FileSystemEntityVisitor = Future<bool> Function(
  FileSystemEntity entity,
  int depth,
);

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
    await for (final entity in directory.list()) {
      if (entity is Directory) {
        final shouldVisitChildren = await visitor.call(entity, depth);
        if (!shouldVisitChildren) {
          continue;
        }
        // visitor may delete entity
        if (entity.existsSync()) {
          await _performVisit(entity.absolute, visitor, depth + 1);
        }
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
}
