import 'git.dart';

const yamlNonMapContent = 'Hello';
const yamlEmptyContent = '';

const yamlCorrectContent = '''
git-url: $mockGitUrl
ref: $mockRef
''';
const yamlWrongContent = '''
gt-rl: $mockGitUrl
rf: $mockRef
''';
const yamlEmptyGitUrl = '''
git-url: ''
rf: $mockRef
''';
