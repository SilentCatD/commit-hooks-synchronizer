import 'package:args/command_runner.dart';
import 'package:remote_hooks/remote_hooks.dart';

class InstallCommand extends Command {
  @override
  String get description => "Install the git hooks from repository";

  @override
  String get name => "install";

  InstallCommand() {
    argParser.addOption('url', abbr: 'u', help: 'Url to the remote repository');
    argParser.addOption('ref', abbr: 'r', help: 'Repository ref to checkout');
  }

  @override
  Future<void> run() async {
    if (argResults == null) return;
    final remoteHooks = RemoteHooks();
    final url = argResults!.option('url');
    final ref = argResults!.option('ref');
    await remoteHooks.exitOnFail(remoteHooks.install(gitUrl: url, gitRef: ref));
  }
}
