import 'package:args/command_runner.dart';
import 'commands/install_command.dart';
import 'commands/uninstall_command.dart';

void main(List<String> arguments) {
  CommandRunner("remote_hooks",
      "remote_hooks - a CLI to share & install git hooks from remote repository.")
    ..addCommand(InstallCommand())
    ..addCommand(UninstallCommand())
    ..argParser.addFlag('verbose',
        abbr: 'v', help: "Show additional command output.", negatable: false)
    ..run(arguments);
}
