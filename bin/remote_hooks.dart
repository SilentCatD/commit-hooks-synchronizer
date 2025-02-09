import 'package:args/command_runner.dart';
import 'package:remote_hooks/logger.dart';
import 'commands/install_command.dart';
import 'commands/uninstall_command.dart';

void main(List<String> arguments) {
  final commandRunner = CommandRunner("remote_hooks",
      "remote_hooks - a CLI tool to share & install git hooks from remote repository.")
    ..addCommand(InstallCommand())
    ..addCommand(UninstallCommand())
    ..argParser.addFlag('verbose',
        abbr: 'v', help: "Show additional command output.", negatable: false);
  final parsed = commandRunner.parse(arguments);
  final verbose = parsed.flag('verbose');
  initLogger(verbose);
  commandRunner.run(arguments);
}
