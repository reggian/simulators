# simulators

Install, list, uninstall and prune Xcode simulator runtimes, without copying UUIDs around.

Every Xcode release, and every beta, brings its own simulator runtime, and the old ones stay
behind at 4–9 GB each. Apple's tools (`xcrun simctl runtime`, `xcodebuild -downloadPlatform`) can
manage them, but you have to list runtimes, work out which is which, copy an identifier and paste it
into another command. `simulators` does that part for you.

## Install

```sh
brew install reggian/tap/simulators
```

Homebrew builds it from source, which needs Xcode. You need Xcode for simulators anyway.

## Commands

```text
simulators list                           installed runtimes
simulators list --available [--all]       runtimes Apple offers for download
simulators install [<runtime> ...]        download and install: iOS 27.2, iOS 27.3 beta, iOS or 24B8117
simulators uninstall [<runtime> ...]      uninstall: iOS 27.2, "iOS 27.3 beta", 24B8117 or a UUID
simulators prune [--unused-for <days>]    uninstall superseded and long-unused runtimes
```

`list --available` shows, per platform and version, the release builds, or the newest beta when
there's no release yet; `--all` shows every build. `install` downloads through
`xcodebuild -downloadPlatform`, arm64 by default (`--arch universal` for Intel too), and only offers
runtimes that install without signing in to an Apple account. Like `uninstall`, it asks first and
shows the total size; `--yes` skips the question.

Installed runtimes don't record whether they're a beta, so `list` and `uninstall` look the build up
in Apple's index to label betas and release candidates. Offline, they show the plain version.

`prune` offers two kinds of runtimes, each with its reason:

- **Superseded:** a newer build of the same runtime is installed, such as the release after a
  beta. Builds are ranked by release stage from Apple's index, then by build number, because
  Apple's build numbers don't sort across betas, release candidates and releases.
- **Unused:** not used for 180 days (`--unused-for <days>`; `--superseded-only` turns this off).
  A runtime `simctl` has no last-used date for is never offered.

It keeps runtimes an installed Xcode uses, and says so. You pick from a numbered list (Enter takes
all), then confirm, as with `uninstall`.

Output is colored on a terminal; set `NO_COLOR` for plain text. Pipes and files always get plain
text.

`install`, `uninstall` and `prune` take `--dry-run`. In a terminal it goes through the same steps,
picking and confirming included, and changes nothing at the end. Without a terminal, or with
`--yes`, it only reports what would happen.

The Used by column names the installed Xcodes that use a runtime: per SDK, the build Xcode picks
for building, previews and running simulators of that OS version (`simctl runtime match list`,
asked once per Xcode). Older runtimes still work for testing older OS versions, so an empty column
doesn't mean a runtime is useless. `uninstall` warns before removing a runtime an Xcode uses.

Run a command without a runtime and it shows a numbered list to pick from:

```text
$ simulators uninstall
#  Runtime        Build     Arch       Size     Last used  Used by
1  iOS 17.2       21C62     universal  7.35 GB  today
2  iOS 26.5       23F77     arm64      8.49 GB  yesterday
3  iOS 27.2       24B8117   arm64      8.32 GB  -          Xcode 27.2
4  iOS 27.3 beta  24C5037i  arm64      8.5 GB   -

4 runtimes, 32.66 GB

Select runtimes to uninstall (e.g. 1 3, 2-4, all): 4
```

## Requirements

- macOS 15 or later
- Xcode 16.1 or later; some runtimes need a newer Xcode

## Known issues

Most of these come from `simctl` itself; `simulators` works around what it can.

- **`simctl` sometimes keeps a runtime's files.** `simctl runtime delete` can unregister a runtime
  but leave its files (several GB) in `/System/Library/AssetsV2`, which macOS protects, so you
  can't remove them by hand. `simulators uninstall` then runs `xcrun simctl runtime scan-and-mount`,
  waits up to two minutes for the runtime to come back, and deletes it once more, which removes the
  files. If it doesn't come back in time, the command tells you how to finish by hand.
- **Runtimes that are being registered are left out.** Right after `scan-and-mount`, `simctl` lists
  a runtime before it knows everything about it. `simulators list` leaves such a runtime out until
  `simctl` reports it in full; run it again a little later.
- **Used by is only tested with one Xcode installed.** It asks each installed Xcode separately, and
  `prune` keeps any runtime an Xcode uses. If you have several Xcodes and the column looks wrong,
  please open an issue.

## Building from source

```sh
swift build -c release
.build/release/simulators --help
```
