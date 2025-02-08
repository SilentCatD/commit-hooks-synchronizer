const String yamlFileName = 'remotehooks.yaml';
const String kRemoteHooksConfig = '.remotehooks';
const String kDotGit = '.git';
const String kGitIgnore = '.gitignore';
const String kHooksIgnore = '.hooksignore';
const String kHooksInstallScripts = 'install';
const String kHooksUninstallScripts = 'install';

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
}
