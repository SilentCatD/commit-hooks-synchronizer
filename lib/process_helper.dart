import 'dart:async';
import 'dart:io';
import 'package:remote_hooks/logger.dart';
import 'errors.dart';

class ProcessHelper {
  Future<String> executeCommand(String command, List<String> args,
      {String? workingDirectory,
      String? errorMessage,
      String? processMessage}) async {
    final process =
        logger.progress(processMessage ?? "$command ${args.join(" ")}");
    final result =
        await Process.run(command, args, workingDirectory: workingDirectory);
    process.finish();
    if (result.exitCode != 0) {
      throw ProcessExecutionException(
          errorMessage ?? "Error executing $command: ${result.stderr}".trim());
    }
    return result.stdout.toString().trim();
  }

  Future<String?> executeFileIfExist(File file) async {
    if (!await file.exists()) {
      return null;
    }
    return await executeCommand(file.path, []);
  }
}
