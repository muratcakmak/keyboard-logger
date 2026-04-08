# Contributing to KeyboardLogger

Thanks for your interest in contributing! This document explains how to propose changes.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating you agree to uphold it.

## Development setup

```bash
git clone https://github.com/muratcakmak/keyboard-logger.git
cd keyboard-logger
swift build
swift test
```

To build and launch the app end-to-end:

```bash
APP_NAME=KeyboardLoggerApp BUNDLE_ID=com.keyboardlogger.app MENU_BAR_APP=1 \
  ./Scripts/compile_and_run.sh --test
```

For a stable code-signing identity during development (so macOS doesn't re-prompt for Accessibility permission on every build):

```bash
./Scripts/setup_dev_signing.sh
export APP_IDENTITY='KeyboardLogger Development'
```

## Branching & workflow

1. Fork the repo and create a feature branch off `main`:
   ```bash
   git checkout -b feat/my-feature
   ```
2. Make focused, atomic commits.
3. Ensure `swift test` passes and the app still builds (`./Scripts/compile_and_run.sh`).
4. Open a pull request against `main`.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

- `feat:` — user-facing new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — internal change, no behaviour difference
- `test:` — adding or fixing tests
- `chore:` — tooling, build, dependency bumps
- `ci:` — CI configuration

Example: `feat(cli): add --since flag to export command`

## Pull requests

- Describe the motivation and what changed.
- Include before/after screenshots for UI changes.
- Link related issues (`Closes #123`).
- Keep PRs small and reviewable when possible.

## Releases

Releases are cut by maintainers:

1. Update `version.env` and `CHANGELOG.md`.
2. Commit with `chore(release): vX.Y.Z`.
3. Tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
4. The `release.yml` workflow builds a universal `.app`, zips it, and publishes a GitHub Release automatically.

## Reporting security issues

Please **do not** file public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md).
