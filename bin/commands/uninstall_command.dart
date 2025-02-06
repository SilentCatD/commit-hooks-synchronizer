import 'package:args/command_runner.dart';
import 'package:chs/chs.dart' as chs;
import 'package:chs/logger.dart';
import 'package:chs/utils.dart';

class UninstallCommand extends Command {
  @override
  String get description => "Uninstall hooks from repository";

  @override
  String get name => "uninstall";

  @override
  Future<void> run() async {
    final verbose = globalResults?.flag('verbose') ?? false;
    initLogger(verbose);
    await exitOnFail(chs.uninstall());
  }
}
