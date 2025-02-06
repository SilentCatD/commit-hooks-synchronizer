import 'package:args/command_runner.dart';
import 'package:remote_hooks/logger.dart';
import 'package:remote_hooks/remote_hooks.dart';
import 'package:remote_hooks/utils.dart';

class UninstallCommand extends Command {
  @override
  String get description => "Uninstall hooks from repository";

  @override
  String get name => "uninstall";

  @override
  Future<void> run() async {
    final verbose = globalResults?.flag('verbose') ?? false;
    initLogger(verbose);
    await exitOnFail(uninstall());
  }
}
