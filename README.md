# simulators

Install, list, uninstall and prune Xcode simulator runtimes, without copying UUIDs around.

Every Xcode release, and every beta, brings its own simulator runtime, and the old ones stay
behind at 4–9 GB each. Apple's tools (`xcrun simctl runtime`, `xcodebuild -downloadPlatform`) can
manage them, but you have to list runtimes, work out which is which, copy an identifier and paste it
into another command. `simulators` does that part for you.

> **Status:** early development. Only `simulators list` (installed runtimes) works so far.

## Planned commands

```text
simulators list [--available]            installed runtimes, or the ones you can download
simulators install [<platform> [version]]
simulators uninstall [<runtime>]
simulators prune [--yes]                 remove superseded runtimes no installed Xcode uses
```

Run a command without a runtime and it shows a numbered list to pick from:

```text
$ simulators uninstall

 #  Runtime         Build      Size    Last used   Used by
 1  iOS 17.2        21C62      7.4 GB  today
 2  iOS 27.0 b3     24A5289g   8.2 GB  -
 3  iOS 27.0 b4     24A5298h   8.3 GB  today       Xcode 27 beta 4

Select runtimes to uninstall (e.g. 1 3, 2-4, all): 2
```

## Requirements

- macOS 15 or later
- Xcode 16.1 or later; some runtimes need a newer Xcode

## Building

```sh
swift build
swift run simulators --help
```
