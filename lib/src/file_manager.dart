import 'dart:io';

class FileManager {
  File? loadFile({required String path}) {
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<String?> loadFileAsString({required String path}) async {
    final file = loadFile(path: path);
    if (file == null) {
      return null;
    }
    final contents = await file.readAsString();
    return contents;
  }
}
