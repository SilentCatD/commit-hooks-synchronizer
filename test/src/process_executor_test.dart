import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:process/process.dart';
import 'package:remote_hooks/src/process_executor.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockProcessManager extends Mock implements ProcessManager {}

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
  final processException = ProcessException(
    executable,
    arguments,
  );

  setUp(() {
    logger = _MockLogger();
    processManager = _MockProcessManager();
    processExecutor =
        ProcessExecutor(logger: logger, processManager: processManager);

    when(() => logger.theme).thenReturn(logTheme);
  });

  group('test execute command', () {
    test('process manager not throw', () async {
      when(() => logger.detail(any(), style: any(named: 'style')))
          .thenReturn(null);
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
      when(() => logger.detail(any(), style: any(named: 'style')))
          .thenReturn(null);
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
}
