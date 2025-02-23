import 'dart:async';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:remote_hooks/src/process_executor.dart';
import 'package:test/test.dart';

import '../fixtures/processor.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProcessManager extends Mock implements ProcessManager {}

class _MockProcess extends Mock implements Process {}

void main() {
  late Logger logger;
  late ProcessManager processManager;
  late ProcessExecutor processExecutor;
  const command = ['git', 'status'];
  final executable = command.first;
  final arguments = command.skip(1).toList();
  final fullCommand = command.join(' ');
  final workingDirectory = Directory.current.path;
  final processResult = ProcessResult(999, 0, 'stdout', 'stderr');
  const logTheme = LogTheme();
  final executableFile = File('test/fixtures/test_run.sh');
  final nonExistedFile = File('test/fixtures/non-existed.sh');
  final processException = ProcessException(
    executable,
    arguments,
  );
  final mockProcess = _MockProcess();
  late StreamController<List<int>> stdOut;
  late StreamController<List<int>> stdErr;
  // Hello world

  setUp(() {
    logger = _MockLogger();
    processManager = _MockProcessManager();
    processExecutor =
        ProcessExecutor(logger: logger, processManager: processManager);

    stdOut = StreamController<List<int>>.broadcast();
    stdErr = StreamController<List<int>>.broadcast();

    when(() => logger.theme).thenReturn(logTheme);

    when(() => mockProcess.stdout).thenAnswer((_) => stdOut.stream);
    when(() => mockProcess.stderr).thenAnswer((_) => stdErr.stream);
  });

  tearDown(() async {
    await stdErr.close();
    await stdErr.close();
  });

  group('test execute command', () {
    test('process manager not throw', () async {
      when(() => processManager.run(any(),
              workingDirectory: any(named: 'workingDirectory')))
          .thenAnswer((_) async => processResult);

      final result = await processExecutor.executeCommand(
        command,
        workingDirectory: workingDirectory,
      );

      expect(result, processResult);
      verify(() => logger.detail(fullCommand)).called(1);
      verifyNoMoreInteractions(logger);
      verify(
        () => processManager.run(command, workingDirectory: workingDirectory),
      ).called(1);
      verifyNoMoreInteractions(processManager);
    });
    test('process manager throw', () async {
      when(
        () => processManager.run(any(),
            workingDirectory: any(named: 'workingDirectory')),
      ).thenThrow(processException);

      Future<ProcessResult> execute() async {
        return processExecutor.executeCommand(
          command,
          workingDirectory: workingDirectory,
        );
      }

      expect(
          execute(),
          throwsA(
            const TypeMatcher<ProcessException>()
                .having((err) => err.executable, 'executable', executable)
                .having((err) => err.arguments, 'arguments', arguments),
          ));
      verify(() => logger.theme).called(1);
      verify(() => logger.detail(fullCommand)).called(1);
      verify(() => logger.detail('$processException', style: logTheme.err))
          .called(1);
      verify(
        () => processManager.run(command, workingDirectory: workingDirectory),
      ).called(1);
      verifyNoMoreInteractions(processManager);
      verifyNoMoreInteractions(logger);
    });
  });

  group('test execute file', () {
    test('process manager not throw', () async {
      when(
        () => processManager.start(
          any(),
          workingDirectory: any(named: 'workingDirectory'),
          runInShell: any(named: 'runInShell'),
        ),
      ).thenAnswer((_) async => mockProcess);
      when(() => mockProcess.exitCode).thenAnswer((_) async {
        stdErr.add(helloWorldInBytes);
        stdOut.add(helloWorldInBytes);
        return 1;
      });

      final result = await processExecutor.executeFile(
        executableFile,
        workingDirectory: workingDirectory,
      );

      expect(result, 1);
      verify(() => logger.detail(executableFile.path)).called(1);
      verify(() => logger.detail(helloWorldInStr)).called(1);
      verify(() => logger.theme).called(1);
      verify(() => logger.detail(helloWorldInStr, style: logTheme.err))
          .called(1);
      verifyNoMoreInteractions(logger);
      verify(
        () => processManager.start(
          [executableFile.path],
          workingDirectory: workingDirectory,
          runInShell: true,
        ),
      ).called(1);
      verifyNoMoreInteractions(processManager);
    });
    test('process manager throw', () async {
      when(
        () => processManager.start(
          any(),
          workingDirectory: any(named: 'workingDirectory'),
          runInShell: any(named: 'runInShell'),
        ),
      ).thenThrow(processException);

      Future<void> execute() async {
        await processExecutor.executeFile(
          executableFile,
          workingDirectory: workingDirectory,
        );
      }

      expect(
        execute(),
        throwsA(
          const TypeMatcher<ProcessException>()
              .having((err) => err.executable, 'executable', executable)
              .having((err) => err.arguments, 'arguments', arguments),
        ),
      );
      verify(() => logger.detail(executableFile.path)).called(1);
      verify(() => logger.theme).called(1);
      verify(() => logger.detail('$processException', style: logTheme.err))
          .called(1);
      verifyNoMoreInteractions(logger);
      verify(
        () => processManager.start(
          [executableFile.path],
          workingDirectory: workingDirectory,
          runInShell: true,
        ),
      ).called(1);
      verifyNoMoreInteractions(processManager);
    });
  });
  group('test execute file', () {
    test('execute existed file', () async {
      when(
        () => processManager.start(
          any(),
          workingDirectory: any(named: 'workingDirectory'),
          runInShell: any(named: 'runInShell'),
        ),
      ).thenAnswer((_) async => mockProcess);
      when(() => mockProcess.exitCode).thenAnswer((_) async {
        return 1;
      });

      final result = await processExecutor.executeFileIfExist(executableFile);
      expect(result, 1);
      verify(
        () => processManager.start(
          any(),
          workingDirectory: any(named: 'workingDirectory'),
          runInShell: any(named: 'runInShell'),
        ),
      ).called(1);
      verifyNoMoreInteractions(processManager);
    });
    test('execute non existed file', () async {
      final result = await processExecutor.executeFileIfExist(nonExistedFile);
      expect(result, 0);
      verifyZeroInteractions(processManager);
      verifyZeroInteractions(logger);
    });
  });
}
