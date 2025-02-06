<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

[![pub package](https://img.shields.io/pub/v/remote_hooks?color=green&include_prereleases&style=plastic)](https://pub.dev/packages/remote_hooks)

## Getting Started

Add `remote_hooks` to your project's `dev_dependencies`:

```shell
dart pub add dev:remote_hooks
```

Then, interact with it inside your project using:

```shell
dart run remote_hooks -h
```

Alternatively, install it globally:

```shell
dart pub global activate remote_hooks
```

Once installed globally, you can use it anywhere:

```shell
remote_hooks -h
```

## Features

Store Git hooks in a shared repository to ensure consistency and reusability across team members
and multiple projects.

## Usage

### Hooks installation

```shell
Usage: remote_hooks install [arguments]
-h, --help    Print this usage information.
-u, --url     Url to the remote repository
-r, --ref     Repository ref to checkout
```

For example, you can use this command to install hooks from a remote repository.

```shell
remote_hooks install -u git@github.com:SilentCatD/where-you-store-hooks.git
```

Specify `ref` with `-r` to switch branches or check out a specific commit. This helps with using
different hooks for different projects.

Once installed via the command line, even without any other configuration files specified, you can
reinstall using the `install` command without needing to specify the `-u` flag.

### Hooks uninstall hooks

To uninstall, use:

```shell
remote_hooks uninstall
```

### Configuration

You can also store the url and ref information in a config file.
At the root of your repository, create a `remotehooks.yaml` file. Inside, you can specify these
two keys:

```yaml
git-url: git@github.com:SilentCatD/where-you-store-hooks.git
ref: develop
```

### Hooks repository structure (Remote repository)

Contents of the remote hooks repository will be copied to `.git/hooks`. In the remote repository,
you can add a `.hooksignore` file to exclude specific files and folders from being copied.

Patterns defined inside `.hooksignore` and `.gitignore` will be merged to create a final exclusion
list.

The file extension of files at the root level is not important, as they will be omitted when
copying.

Example of a repository structure for `pre-commit` and `pre-push` hooks written in Python:

```shell
├── .gitignore
├── .hooksignore
├── hooks_utils
│ ├── formatter_utils.py
│ └── printer_utils.py
├── pre-commit.py
└── pre-push.py
```

## Additional information

For additional command details, use `remote_hooks -h`

```shell
remote_hooks <command> -h
```



