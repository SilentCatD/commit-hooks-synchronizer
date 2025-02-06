class YamlFileWrongFormatException implements Exception {
  const YamlFileWrongFormatException();

  @override
  String toString() => "YAML file has an incorrect format.";
}

class GitUrlNotSpecifiedException implements Exception {
  const GitUrlNotSpecifiedException();

  @override
  String toString() => "Git URL must be specified.";
}

class ProcessExecutionException implements Exception {
  final String message;

  const ProcessExecutionException(this.message);

  @override
  String toString() => message.isNotEmpty ? message : 'Process execution error.';
}

class FileNotFoundException implements Exception {
  final String path;

  const FileNotFoundException(this.path);

  @override
  String toString() => "File not found: $path";
}
