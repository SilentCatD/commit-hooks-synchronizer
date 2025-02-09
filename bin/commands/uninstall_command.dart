import 'package:args/command_runner.dart';
import 'package:remote_hooks/remote_hooks.dart';

class UninstallCommand extends Command {
  @override
  String get description => "Uninstall hooks from repository";

  @override
  String get name => "uninstall";

  @override
  Future<void> run() async {
    final remoteHooks = RemoteHooks();
    await remoteHooks.exitOnFail(remoteHooks.uninstall());
  }
}
