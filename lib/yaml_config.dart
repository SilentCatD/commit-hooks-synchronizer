import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'const.dart';
import 'errors.dart';
import 'utils.dart';

class YamlConfig {
  final String? gitUrl;
  final String? ref;

  const YamlConfig({
    this.gitUrl,
    this.ref,
  });

  static Future<File?> _getYamlFile({required String fileName}) async {
    final filePath = join((await getGitDirectoryRoot()), fileName);
    final file = File(filePath);
    return await file.exists() ? file : null;
  }

  static Future<YamlConfig> parse() async {
    final yamlFile = await _getYamlFile(fileName: yamlFileName);
    if (yamlFile == null) return const YamlConfig();

    final yamlContent = await yamlFile.readAsString();
    final parsedYaml = loadYaml(yamlContent);

    if (parsedYaml is! YamlMap) throw YamlFileWrongFormatException();

    return YamlConfig(
      gitUrl: parsedYaml.value[ConfigKey.gitUrl] as String?,
      ref: parsedYaml.value[ConfigKey.ref] as String?,
    );
  }
}
