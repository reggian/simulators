# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-04

First release.

### Added

- `simulators list`: installed runtimes with build, architecture, size, last use and the installed
  Xcodes that use them. Betas and release candidates are labelled from Apple's runtime index.
- `simulators list --available [--all]`: runtimes Apple offers for download, marking the installed
  ones.
- `simulators install`: downloads runtimes through `xcodebuild -downloadPlatform`, by platform and
  version (`iOS 27.2`), label (`iOS 27.3 beta`), platform alone (newest release) or build. arm64 by
  default, `--arch universal` for Intel too.
- `simulators uninstall`: by name, label, build or UUID. Warns before removing a runtime an Xcode
  uses, and retries when `simctl` keeps a runtime's files.
- `simulators prune`: offers superseded builds and runtimes not used for 180 days
  (`--unused-for`, `--superseded-only`), keeping runtimes an installed Xcode uses.
- Without a runtime argument, `install` and `uninstall` show a numbered list to pick from
  (`1 3`, `2-4`, `all`); `prune` always does, with all picked by default.
- Every change asks for confirmation with the total size first. `--yes` skips it, and without a
  terminal the commands never prompt.
- `--dry-run` rehearses the whole flow in a terminal and only reports without one.
- Colored output on a terminal; `NO_COLOR` turns it off.

[1.0.0]: https://github.com/reggian/simulators/releases/tag/v1.0.0
