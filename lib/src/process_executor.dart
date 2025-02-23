import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:process/process.dart';

class ProcessExecutor {
  ProcessExecutor({ProcessManager? processManager, Logger? logger})
      : _processManager = processManager ?? const LocalProcessManager(),
        _logger = logger ?? Logger();
  final ProcessManager _processManager;
  final Logger _logger;

  Future<ProcessResult> executeCommand(
    List<String> command, {
    String? workingDirectory,
  }) async {
    try {
      _logger.detail(command.join(' '));
      return _processManager.run(command, workingDirectory: workingDirectory);
    } catch (error) {
      _logger.detail('$error', style: _logger.theme.err);
      rethrow;
    }
  }

  Future<int> executeFileIfExist(File file) async {
    if (!file.existsSync()) {
      return 0;
    }
    return executeFile(file);
  }

  Future<int> executeFile(File file, {String? workingDirectory}) async {
    try {
      _logger.detail(file.path);
      final process = await _processManager.start(
        [file.path],
        runInShell: true,
        workingDirectory: workingDirectory,
      );
      unawaited(process.stdout.transform(utf8.decoder).forEach(_logger.detail));
      unawaited(process.stderr.transform(utf8.decoder).forEach((stdErrData) {
        _logger.detail(stdErrData, style: _logger.theme.err);
      }));
      return process.exitCode;
    } catch (error) {
      _logger.detail('$error', style: _logger.theme.err);
      rethrow;
    }
  }
}
