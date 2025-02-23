import 'dart:io';

import 'package:path/path.dart';
import 'package:remote_hooks/src/file_manager.dart';
import 'package:remote_hooks/src/hooks_ignore/ignore.dart';

class HooksIgnore {
  HooksIgnore({required this.patterns}) {
    _ignore = Ignore(patterns);
  }

  final List<String> patterns;
  late final Ignore _ignore;

  static const String kGitIgnore = '.gitignore';
  static const String kHooksIgnore = '.hooksignore';
  static const String kDotGit = '.git';

  static Future<HooksIgnore> loadFromDirectory(
      Directory directory, FileManager fileManager) async {
    Future<List<String>> parsePatterns({bool includeGitIgnore = true}) async {
      final hooksIgnore = File(join(directory.path, kHooksIgnore));
      final gitIgnore = File(join(directory.path, kGitIgnore));
      final patterns =
          await fileManager.loadFileAsLines(path: hooksIgnore.path) ?? [];

      if (includeGitIgnore) {
        patterns.addAll(
          await fileManager.loadFileAsLines(path: gitIgnore.path) ?? [],
        );
      }
      return patterns;
    }

    final patterns = await parsePatterns();
    return HooksIgnore(patterns: patterns);
  }

  bool shouldIgnore(String path, {required bool isDirectory}) {
    final resolvedPath = isDirectory ? join(path, '.') : path;
    return _ignore.ignores(resolvedPath);
  }
}
