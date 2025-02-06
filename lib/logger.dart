import 'package:cli_util/cli_logging.dart';

late Logger logger;

void initLogger(bool verbose) {
  logger = verbose
      ? Logger.verbose(ansi: Ansi(true))
      : Logger.standard(ansi: Ansi(true));
}
