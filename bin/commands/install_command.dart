import 'package:args/command_runner.dart';
import 'package:remote_hooks/logger.dart';
import 'package:remote_hooks/remote_hooks.dart';
import 'package:remote_hooks/utils.dart';

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
    final verbose = globalResults?.flag('verbose') ?? false;
    initLogger(verbose);
    final url = argResults!.option('url');
    final ref = argResults!.option('ref');
    await exitOnFail(install(gitUrl: url, gitRef: ref));
  }
}
