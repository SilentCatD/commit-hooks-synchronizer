import 'dart:io';

import 'package:chs/const.dart';
import 'package:chs/errors.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class YamlConfig {
  final String? gitUrl;
  final String? ref;
  final Map<String, String> hooksEntries;

  const YamlConfig({
    this.gitUrl,
    this.hooksEntries = const {},
    this.ref,
  });

  static Future<File?> _getYamlFile({required String fileName}) async {
    final filePath = join(Directory.current.path, fileName);
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
      hooksEntries:
          _parseHooksEntries(parsedYaml.value[ConfigKey.hooksEntries]),
    );
  }

  static Map<String, String> _parseHooksEntries(dynamic value) {
    if (value == null) {
      return {};
    }
    if (value is! YamlMap) throw YamlFileWrongFormatException();
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
}
