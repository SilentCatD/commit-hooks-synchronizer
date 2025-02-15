import 'dart:io';

import 'package:remote_hooks/src/file_manager.dart';
import 'package:test/test.dart';

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
      final fileContent =
          await fileManager.loadFileAsString(path: existedFilePath);
      expect(fileContent, isNot(null));
      expect(fileContent, fileContent);
    });
    test('file not exist', () async {
      final fileContent =
          await fileManager.loadFileAsString(path: nonExistedFilePath);
      expect(fileContent, null);
      expect(fileContent, isA<String?>());
    });
  });
}
