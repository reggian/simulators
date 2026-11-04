# simulators

A Swift CLI that makes Xcode simulator runtimes easy to list, install, uninstall and prune. It's
a friendly layer over Apple's own tools (`xcrun simctl runtime …`, `xcodebuild -downloadPlatform`),
not a replacement for them.

Project brief: projects/simulators.md in the Agents repo (scope, decisions, native command
reference, known pitfalls). Read it before substantial work.

## Stack

- Swift 6 language mode, Swift Package Manager, macOS 15+.
- Dependencies: swift-argument-parser and Foundation only. Ask before adding any other dependency.
- Tests: Swift Testing.

## Commands

```sh
swift build
swift test
swift run simulators --help
```

## Layout

- `Sources/simulators/`: the executable. Command parsing and terminal presentation only.
- Domain logic, such as runtime models, parsing `simctl` and `xcodebuild` output, the prune rule and
  selection parsing, goes into a separate library target (`SimulatorsKit`). Add it with the first
  feature that needs it. One type or responsibility per file.

## Rules

- **Interactive when no argument is given.** A command that acts on runtimes and is run without one
  shows a numbered list and accepts several numbers (`1 3`, `2-4`, `all`).
- **Never prompt without a terminal.** If stdin isn't a TTY, fail with a message telling the user
  to pass a runtime or `--yes`.
- **Never delete without confirmation.** Show what will be removed and the total size first.
- **Shell out through one injectable runner**, so tests never call the real `simctl`, `xcrun` or
  `xcodebuild`. Test against captured JSON and plist fixtures.
- **Protect the developer's machine.** While developing, never run `xcrun simctl runtime delete`,
  `simulators uninstall` or `simulators prune` against the real system without `--dry-run`, unless
  Andreas explicitly asks. Each runtime is several GB to download again.
- Identify a runtime by platform, version, build, architecture and runtime identifier, never by
  version alone. Device-specific runtimes (for example `…iOS-27-2-iPhone19-4`) aren't duplicates.

## Git

Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`). Small commits that
each build. Branch for anything beyond a single small commit. Never push without asking.
