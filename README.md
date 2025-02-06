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

For example you can this command to install hooks from remote repository

```shell
remote_hooks install -u git@github.com:SilentCatD/where-you-store-hooks.git
```

Specify `ref` to switch branch or checkout a specific commit, this help with different hooks for
different projects

### Hooks uninstall hooks

To uninstall, use:

```shell
remote_hooks uninstall
```

### Configuration

You can also store the information about `url` and `ref` in a config file.
At the root of your repository, create a `remotehooks.yaml` file, inside you can specify these 2
keys:

```yaml
git-url: git@github.com:SilentCatD/where-you-store-hooks.git
ref: develop
```

### Hooks repository structure (Remote repository)

Contents of the remote hooks repository will be copied to `.git/hooks`, in the remote repository,
you can add a `.hooksignore` to exclude files and folders from being copied.

Patterns defined inside `.hooksignore` and `.gitignore` will be merged together to create a final
exclusive list of patterns.

File extension of files at the root level is not important, as they will be omitted when copying

Example of a repository structure for `pre-commit` and `pre-push` with hooks written in python

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



