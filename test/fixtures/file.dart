import 'dart:io';

final availableIterableDirectory = <String, int>{
  'file2.txt': 0,
  'file1.txt': 0,
  'directory1': 0,
  'directory1/file3.txt': 1,
  'directory2': 0,
  'directory2/directory3': 1,
  'directory2/directory3/file4.txt': 2,
  'directory2/directory3/file5.txt': 2,
};
final executableFile = File('test/fixtures/test_run.sh');
final nonExistedFile = File('test/fixtures/non-existed.sh');

final mapData = {
  'key1': 'value1',
  'key2': 'value2',
  'key3': {
    'key4': 0,
    'key5': 10,
  },
};
