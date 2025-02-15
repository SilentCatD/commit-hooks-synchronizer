import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:remote_hooks/src/file_manager.dart';
import 'package:remote_hooks/src/remote_hooks_config.dart';
import 'package:test/test.dart';

import '../fixtures/git.dart';
import '../fixtures/yaml.dart';

class _MockFileManager extends Mock implements FileManager {}

void main() async {
  Future<RemoteHooksConfig?> loadFromDirectory(
    FileManager fileManager,
    Directory yamlDir,
  ) async {
    return RemoteHooksConfig.loadFromDirectory(
      fileManager: fileManager,
      directory: yamlDir,
    );
  }

  final yamlDir = Directory.current;
  late FileManager fileManager;

  setUp(() {
    fileManager = _MockFileManager();
  });

  test('no yaml file found', () async {
    when(() => fileManager.loadFileAsString(path: any(named: 'path')))
        .thenAnswer((_) async => null);
    final config = await loadFromDirectory(fileManager, yamlDir);

    expect(config, null);
    expect(config, isA<RemoteHooksConfig?>());

    verify(
      () => fileManager.loadFileAsString(
        path: join(yamlDir.path, RemoteHooksConfig.fileName),
      ),
    ).called(1);
    verifyNoMoreInteractions(fileManager);
  });

  group('yaml file found', () {
    test('empty yaml file', () async {
      when(() => fileManager.loadFileAsString(path: any(named: 'path')))
          .thenAnswer((_) async => yamlEmptyContent);

      expect(
        loadFromDirectory(fileManager, yamlDir),
        throwsA(
          isFormatException.having(
            (error) => error.message,
            'error message',
            RemoteHooksConfig.incorrectFormatMessage,
          ),
        ),
      );

      verify(
        () => fileManager.loadFileAsString(
          path: join(yamlDir.path, RemoteHooksConfig.fileName),
        ),
      ).called(1);
      verifyNoMoreInteractions(fileManager);
    });
  });

  test('non map yaml file', () async {
    when(() => fileManager.loadFileAsString(path: any(named: 'path')))
        .thenAnswer((_) async => yamlEmptyContent);

    expect(
      loadFromDirectory(fileManager, yamlDir),
      throwsA(
        isFormatException.having(
          (error) => error.message,
          'error message',
          RemoteHooksConfig.incorrectFormatMessage,
        ),
      ),
    );

    verify(
      () => fileManager.loadFileAsString(
        path: join(yamlDir.path, RemoteHooksConfig.fileName),
      ),
    ).called(1);
    verifyNoMoreInteractions(fileManager);
  });

  test('correct format', () async {
    when(() => fileManager.loadFileAsString(path: any(named: 'path')))
        .thenAnswer((_) async => yamlCorrectContent);

    final config = await loadFromDirectory(fileManager, yamlDir);
    expect(config, isA<RemoteHooksConfig>());
    expect(config, RemoteHooksConfig(gitUrl: mockGitUrl, ref: mockRef));

    verify(
      () => fileManager.loadFileAsString(
        path: join(yamlDir.path, RemoteHooksConfig.fileName),
      ),
    ).called(1);
    verifyNoMoreInteractions(fileManager);
  });

  test('wrong format', () async {
    when(() => fileManager.loadFileAsString(path: any(named: 'path')))
        .thenAnswer((_) async => yamlWrongContent);

    expect(
      loadFromDirectory(fileManager, yamlDir),
      throwsA(isFormatException),
    );

    verify(
      () => fileManager.loadFileAsString(
        path: join(yamlDir.path, RemoteHooksConfig.fileName),
      ),
    ).called(1);
    verifyNoMoreInteractions(fileManager);
  });
  test('empty git url', () async {
    when(() => fileManager.loadFileAsString(path: any(named: 'path')))
        .thenAnswer((_) async => yamlEmptyGitUrl);

    expect(
      loadFromDirectory(fileManager, yamlDir),
      throwsA(isFormatException),
    );

    verify(
      () => fileManager.loadFileAsString(
        path: join(yamlDir.path, RemoteHooksConfig.fileName),
      ),
    ).called(1);
    verifyNoMoreInteractions(fileManager);
  });
}
