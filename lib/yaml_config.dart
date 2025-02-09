import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'errors.dart';
import 'git_helper.dart';

class YamlConfig {
  String? gitUrl;
  String? ref;

  YamlConfig({
    this.gitUrl,
    this.ref,
    required this.gitHelper,
  });

  static const String yamlFileName = 'remotehooks.yaml';
  final GitHelper gitHelper;

  static const String gitUrlKey = 'git-url';
  static const String refKey = 'ref';

  Future<File?> _getYamlFile(
      {required Directory directory, required String fileName}) async {
    final filePath = join(directory.path, fileName);
    final file = File(filePath);
    return await file.exists() ? file : null;
  }

  Future<void> load({required Directory directory}) async {
    final yamlFile =
        await _getYamlFile(directory: directory, fileName: yamlFileName);
    if (yamlFile == null) return;

    final yamlContent = await yamlFile.readAsString();
    final parsedYaml = loadYaml(yamlContent);

    if (parsedYaml is! YamlMap) throw YamlFileWrongFormatException();

    gitUrl = parsedYaml.value[gitUrlKey] as String?;
    ref = parsedYaml.value[refKey] as String?;
  }
}
