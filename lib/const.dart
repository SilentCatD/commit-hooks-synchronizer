const String yamlFileName = 'chs.yaml';
const String kChsConfig = '.chsrc';
const String kDotGit = '.git';

/// Set of supported Git hooks
const Set<String> kHooksSignature = {
  "applypatch-msg",
  "commit-msg",
  "fsmonitor-watchman",
  "post-update",
  "pre-applypatch",
  "pre-commit",
  "pre-merge-commit",
  "pre-push",
  "pre-rebase",
  "pre-receive",
  "prepare-commit-msg",
  "push-to-checkout",
  "update",
};

/// Configuration keys used in YAML files
sealed class ConfigKey {
  static const String gitUrl = 'git-url';
  static const String ref = 'ref';
  static const String hooksEntries = 'hooks-entries';
}
