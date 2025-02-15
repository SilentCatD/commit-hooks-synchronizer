import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';
import 'package:remote_hooks/src/file_manager.dart';
import 'package:yaml/yaml.dart';

part 'remote_hooks_config.mapper.dart';

@MappableClass()
class RemoteHooksConfig with RemoteHooksConfigMappable {
  RemoteHooksConfig({
    required this.gitUrl,
    this.ref,
  }) {
    if (gitUrl.isEmpty) {
      throw const FormatException(girUrlEmptyMessage);
    }
  }

  @MappableField(key: 'git-url')
  String gitUrl;
  String? ref;

  static const fromJson = RemoteHooksConfigMapper.fromJson;

  static const String fileName = 'remotehooks.yaml';
  static const String incorrectFormatMessage = 'incorrect format';
  static const String girUrlEmptyMessage = "git-url can't be empty";

  static Future<RemoteHooksConfig?> loadFromDirectory({
    required FileManager fileManager,
    required Directory directory,
  }) async {
    final filePath = join(directory.path, fileName);
    final yamlContent = await fileManager.loadFileAsString(path: filePath);

    // no yaml config found
    if (yamlContent == null) {
      return null;
    }

    // parse config
    final parsedYaml = loadYaml(yamlContent);
    if (parsedYaml is! YamlMap) {
      throw const FormatException(incorrectFormatMessage, fileName);
    }
    try {
      final yamlMap = parsedYaml.value
          .map((k, v) => MapEntry<String, dynamic>(k.toString(), v));
      final yamlConfig = RemoteHooksConfig.fromJson(yamlMap);
      return yamlConfig;
    } catch (e) {
      if (e is MapperException) {
        throw FormatException(e.message, fileName);
      }
      rethrow;
    }
  }
}
