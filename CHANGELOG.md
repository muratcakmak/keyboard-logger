# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-04-07

### Fixed
- CI and Release workflows now use `APP_NAME=KeyboardLoggerApp`, matching the SwiftPM executable target. The previous value caused `package_app.sh` to fail looking up the built binary, which broke the v0.1.0 release.
- Switched the GitHub Actions runner to `macos-15` with `latest-stable` Xcode so GRDB 7.10's Swift 6.1 toolchain requirement is satisfied.

## [0.1.0] - 2026-04-07

### Added
- Menu bar app with live keyboard shortcut and keystroke dashboard (Shortcuts / Keys / Apps / Trends tabs)
- Global keyboard event tap with per-app attribution
- Local SQLite storage via GRDB with daily aggregation
- `keyboard-logger` CLI with `stats`, `apps`, `export`, and `seed` subcommands
- SwiftPM-based build with `Scripts/package_app.sh` producing a signed `.app` bundle
- CI and tag-triggered release workflows on GitHub Actions

[Unreleased]: https://github.com/muratcakmak/keyboard-logger/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/muratcakmak/keyboard-logger/releases/tag/v0.1.1
[0.1.0]: https://github.com/muratcakmak/keyboard-logger/releases/tag/v0.1.0
