import 'dart:io';

import 'package:path/path.dart';
import 'package:remote_hooks/file_helper.dart';
import 'package:remote_hooks/hooks_ignore/ignore.dart';

class HooksIgnore {
  List<String>? _patterns;
  Ignore? _ignore;
  final FileHelper fileHelper;

  HooksIgnore({required this.fileHelper});

  static const String kGitIgnore = '.gitignore';
  static const String kHooksIgnore = '.hooksignore';
  static const String kDotGit = '.git';

  Future<void> loadFromDirectory(Directory directory) async {
    final patterns = await parsePatterns(directory);
    _patterns = patterns;
    _ignore = Ignore(patterns);
  }

  Future<List<String>> parsePatterns(Directory directory,
      {bool includeGitIgnore = true}) async {
    final List<String> patterns = [];
    final hooksIgnore = File(join(directory.path, kHooksIgnore));
    if (await hooksIgnore.exists()) {
      patterns.addAll(await hooksIgnore.readAsLines());
    }
    if (includeGitIgnore) {
      final gitIgnore = File(join(directory.path, kGitIgnore));
      if (await gitIgnore.exists()) {
        patterns.addAll(await gitIgnore.readAsLines());
      }
    }
    return patterns;
  }

  bool shouldIgnore(String path) {
    return _ignore?.ignores(path) ?? false;
  }

  Future<File> writeToFile(String path) async {
    final file = File(path);
    final contents = _patterns?.join("\n") ?? "";
    await file.writeAsString(contents);
    return file;
  }

  Future<File> writeToDirectory(Directory directory) async {
    return writeToFile(join(directory.path, kHooksIgnore));
  }

  Future<void> cleanIgnored(Directory directory) async {
    await fileHelper.visit(directory, (entity, depth) async {
      String relativePath = relative(entity.path, from: directory.path);
      if (entity is Directory) {
        relativePath = join(relativePath, '.');
      }
      if (shouldIgnore(relativePath) ||
          basename(relativePath) == kHooksIgnore) {
        await entity.delete();
      }
      return true;
    });
  }
}
