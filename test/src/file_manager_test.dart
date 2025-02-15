import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:remote_hooks/src/file_manager.dart';
import 'package:test/test.dart';

import '../fixtures/file.dart';

void main() {
  const existedFilePath = 'test/fixtures/test-file.txt';
  const nonExistedFilePath = 'test/fixtures/test-file-that-do-not-exist.txt';
  const fileContent = 'Hello World';

  late FileManager fileManager;

  setUp(() {
    fileManager = FileManager();
  });

  group('loadFile', () {
    test('file exist', () {
      final file = fileManager.loadFile(path: existedFilePath);
      expect(file, isNot(null));
      expect(file, isA<File>());
    });
    test('file not exist', () {
      final file = fileManager.loadFile(path: nonExistedFilePath);
      expect(file, null);
      expect(file, isA<File?>());
    });
  });

  group('loadFileAsString', () {
    test('file exist', () async {
      final loadedFileContent =
          await fileManager.loadFileAsString(path: existedFilePath);
      expect(loadedFileContent, isNot(null));
      expect(loadedFileContent, fileContent);
    });
    test('file not exist', () async {
      final fileContent =
          await fileManager.loadFileAsString(path: nonExistedFilePath);
      expect(fileContent, null);
      expect(fileContent, isA<String?>());
    });
  });

  test('create temporary directory', () async {
    final rootDirectory = Directory('test/fixtures');
    final tempDirectory =
        await fileManager.createTemporaryDirectory(rootDirectory);
    final path = tempDirectory.path;

    expect(tempDirectory.existsSync(), true);
    expect(path.startsWith(rootDirectory.path), true);
    expect(basename(path).startsWith(FileManager.tempDirPrefix), true);

    addTearDown(tempDirectory.deleteSync);
  });

  group('directory children visitor', () {
    test('visit children', () async {
      final directory = Directory('test/fixtures/iterable_directory');
      final visited = <String, int>{};
      await fileManager.visit(directory, (entity, depth) async {
        visited[relative(entity.path, from: directory.path)] = depth;
      });

      expect(visited.length, availableIterableDirectory.length);
      for (final entry in visited.entries) {
        expect(availableIterableDirectory.containsKey(entry.key), true);
        expect(availableIterableDirectory[entry.key], entry.value);
      }
    });

    test('skip visit children', () async {
      final directory = Directory('test/fixtures/iterable_directory');
      final visited = <String, int>{};
      await fileManager.visit(directory, (entity, depth) async {
        final relativePath = relative(entity.path, from: directory.path);
        visited[relativePath] = depth;
      }, shouldVisit: (entity, depth) {
        final relativePath = relative(entity.path, from: directory.path);
        if (relativePath == 'directory2') {
          return false;
        }
        return true;
      });
      // skip visit:
      // - directory2
      // - directory2/directory3
      // - directory2/directory3/file4.txt
      // - directory2/directory3/file5.txt
      expect(visited.length, availableIterableDirectory.length - 4);
      for (final entry in visited.entries) {
        expect(entry.key.startsWith('directory2'), false);
      }
    });

    test('skip visit because deleted', () async {
      final directory = Directory('test/fixtures/iterable_directory');

      final testDirectory = await fileManager
          .createTemporaryDirectory(Directory('test/fixtures'));

      await copyPath(directory.path, testDirectory.path);

      final visited = <String, int>{};
      await fileManager.visit(testDirectory, (entity, depth) async {
        final relativePath = relative(entity.path, from: testDirectory.path);
        visited[relativePath] = depth;
        if (relativePath == 'directory2') {
          await entity.delete(recursive: true);
        }
      });
      // skip visit:
      // - directory2/directory3
      // - directory2/directory3/file4.txt
      // - directory2/directory3/file5.txt
      expect(visited.length, availableIterableDirectory.length - 3);
      for (final entry in visited.entries) {
        expect(entry.key.startsWith('directory2/directory3'), false);
      }
      addTearDown(() => testDirectory.delete(recursive: true));
    });
  });

  group('files copy', () {
    test('copy all', () async {
      final directory = Directory('test/fixtures/iterable_directory');
      final testDirectory = Directory('test/iterable_directory_copied');
      final visited = <String, int>{};
      await fileManager.copy(
        directory,
        testDirectory,
        postCopy: (entity, depth) async {
          final relativePath = relative(entity.path, from: testDirectory.path);
          visited[relativePath] = depth;
        },
      );

      expect(visited.length, availableIterableDirectory.length);
      for (final entry in visited.entries) {
        expect(availableIterableDirectory.containsKey(entry.key), true);
        expect(availableIterableDirectory[entry.key], entry.value);
      }
      addTearDown(() => testDirectory.delete(recursive: true));
    });
  });

  test('not copy directory 2', () async {
    final directory = Directory('test/fixtures/iterable_directory');
    final testDirectory =
        await fileManager.createTemporaryDirectory(Directory('test/fixtures'));
    final visited = <String, int>{};
    await fileManager.copy(
      directory,
      testDirectory,
      postCopy: (entity, depth) async {
        final relativePath = relative(entity.path, from: testDirectory.path);
        visited[relativePath] = depth;
      },
      shouldCopy: (entity, depth) {
        final relativePath = relative(entity.path, from: directory.path);
        if (relativePath == 'directory2') {
          return false;
        }
        return true;
      },
    );

    // skip visit:
    // - directory2
    // - directory2/directory3
    // - directory2/directory3/file4.txt
    // - directory2/directory3/file5.txt
    expect(visited.length, availableIterableDirectory.length - 4);
    for (final entry in visited.entries) {
      expect(entry.key.startsWith('directory2'), false);
    }
    addTearDown(() => testDirectory.delete(recursive: true));
  });
}
