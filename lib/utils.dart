import 'dart:async';
import 'dart:io';
import 'package:chs/const.dart';
import 'package:chs/errors.dart';
import 'package:chs/logger.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

void exitWithError(String message) {
  logger.stderr(message);
  exit(1);
}

Future<String> getGitDirectoryRoot() async {
  try {
    return await executeCommand('git', ['rev-parse', '--show-toplevel']);
  } catch (e) {
    throw ProcessExecutionException("Failed to determine Git root: $e");
  }
}

Future<String> executeCommand(String command, List<String> args,
    {String? workingDirectory}) async {
  final result =
      await Process.run(command, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw ProcessExecutionException(
        "Error executing $command: ${result.stderr}".trim());
  }
  return result.stdout.toString().trim();
}

Future<void> exitOnFail(FutureOr<void> func) async {
  try {
    await func;
  } catch (err) {
    exitWithError(err.toString());
  }
}

Future<Directory> getLocalHooksDir() async {
  final repositoryRoot = await getGitDirectoryRoot();
  return Directory(join(repositoryRoot, '.git/hooks'));
}

Future<Directory> getTemporaryDirectory() async {
  final tempDirPath =
      join(Directory.systemTemp.path, "TemporaryDirectory-${Uuid().v4()}");
  return Directory(tempDirPath);
}

Future<void> cloneHooksRepo(
    String gitUrl, String? ref, Directory cloneDir) async {
  final process = logger.progress("Cloning hooks repo to: ${cloneDir.path}");
  await executeCommand('git', ['clone', gitUrl, cloneDir.path]);
  process.finish();

  if (ref != null) {
    logger.stdout("Checking out ref: $ref");
    await executeCommand('git', ['checkout', ref],
        workingDirectory: cloneDir.path);
  }
}

Future<List<String>> loadIgnorePatterns(Directory clonedDir) async {
  final List<String> results = [];
  final gitIgnoreFile = File(join(clonedDir.path, kGitIgnore));
  final hooksIgnoreFile = File(join(clonedDir.path, kHooksIgnore));

  if (await gitIgnoreFile.exists()) {
    results.addAll(await gitIgnoreFile.readAsLines());
  }
  if (await hooksIgnoreFile.exists()) {
    results.addAll(await hooksIgnoreFile.readAsLines());
  }
  return results;
}
