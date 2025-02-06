import 'package:args/command_runner.dart';
import 'commands/install_command.dart';
import 'commands/uninstall_command.dart';

void main(List<String> arguments) {
  CommandRunner(
      "chs",
      "chs - Commit Hooks Synchronizer - a CLI to share & "
          "sync git git hooks.")
    ..addCommand(InstallCommand())
    ..addCommand(UninstallCommand())
    ..argParser.addFlag('verbose',
        abbr: 'v', help: "Show additional command output.", negatable: false)
    ..run(arguments);
}
