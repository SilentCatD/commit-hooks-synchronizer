import 'dart:convert';
import 'dart:io';

import 'package:io/io.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:remote_hooks/src/file_manager.dart';
import 'package:remote_hooks/src/process_executor.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../fixtures/file.dart';

class _MockProcessExecutor extends Mock implements ProcessExecutor {}

void main() {
  const existedFilePath = 'test/fixtures/test-file.txt';
  const existedFilePath2 = 'test/fixtures/test-file2.txt';
  const nonExistedFilePath = 'test/fixtures/test-file-that-do-not-exist.txt';
  const fileContent = 'Hello World';
  final tempDir = Directory('test/fixtures/temp_directory');
  const uuid = Uuid();

  late FileManager fileManager;
  late ProcessExecutor processExecutor;

  setUp(() {
    processExecutor = _MockProcessExecutor();
    fileManager = FileManager(processExecutor: processExecutor);
  });

  test('create without process executor', () {
    FileManager();
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

  group('writeFileAsString', () {
    test('file exist', () async {
      final file = await fileManager.writeFileAsString(
          contents: fileContent, path: existedFilePath2,);
      expect(file.path, existedFilePath2);
      expect(file.readAsStringSync(), fileContent);
    });
    test('file not exist', () async {
      final generatedFile =
          File('test/fixtures/temp_directory/${uuid.v4()}.txt');
      final existed = generatedFile.existsSync();
      final file = await fileManager.writeFileAsString(
          contents: fileContent, path: generatedFile.path,);
      final generated = generatedFile.existsSync();
      expect(file.readAsStringSync(), fileContent);
      expect(existed, false);
      expect(generated, true);
      addTearDown(file.delete);
    });
  });

  test('writeFileAsMap', () async {
    final generatedFile = File('test/fixtures/temp_directory/${uuid.v4()}.txt');
    final file = await fileManager.writeFileAsMap(
        contents: mapData, path: generatedFile.path,);
    expect(file.readAsStringSync(), jsonEncode(mapData));
    addTearDown(file.delete);
  });

  test('readFileAsMap', () async {
    final jsonFile = File('test/fixtures/map-data-file.json');
    final fileMapData = await fileManager.loadFileAsMap(path: jsonFile.path);
    expect(jsonEncode(fileMapData), jsonEncode(mapData));
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
      await fileManager.visit(
        directory,
        (entity, depth) async {
          final relativePath = relative(entity.path, from: directory.path);
          visited[relativePath] = depth;
        },
        shouldVisit: (entity, depth) {
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
// not pre-created to test destination creation
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

  test('delete entity', () async {
    final generatedTempDir = await tempDir.createTemp();
    final generated = generatedTempDir.existsSync();
    await fileManager.delete(generatedTempDir);
    final deleted = !generatedTempDir.existsSync();
    expect(generated, true);
    expect(deleted, true);
  });

  group('Grant execution permission', () {
    test('file existed', () async {
      when(() => processExecutor.executeCommand(any())).thenAnswer(
        (_) async => ProcessResult(999, 0, null, null),
      );

      await fileManager.grantExecutionPermission(executableFile);

      if (!Platform.isWindows) {
        verify(
          () => processExecutor
              .executeCommand(['chmod', '+x', executableFile.path]),
        ).called(1);
      }
      verifyNoMoreInteractions(processExecutor);
    });

    test('file not existed', () async {
      await fileManager.grantExecutionPermission(nonExistedFile);

      if (!Platform.isWindows) {
        verifyZeroInteractions(processExecutor);
      }
      verifyNoMoreInteractions(processExecutor);
    });
  });
}
