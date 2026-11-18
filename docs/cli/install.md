---
title: Install the bcdock CLI
description: Install the BCDock CLI on macOS, Linux, or Windows. Single static binary, no runtime dependencies.
---

# Install

The `bcdock` CLI is a single static binary with no runtime dependencies. Pick whichever path matches your environment.

!!! note "Distribution channels in flight"

    The winget package is still pending: on Windows, use the PowerShell install script. The Homebrew tap is live: `brew install bcdock/tap/bcdock`.

## macOS / Linux - install script

```bash
curl -fsSL https://cli.bcdock.io/install.sh | sh
```

Detects your OS and architecture, downloads the matching binary from GitHub Releases, and installs it to `/usr/local/bin/bcdock`.

## Windows - install script (PowerShell)

```powershell
irm https://cli.bcdock.io/install.ps1 | iex
```

Downloads the latest release from GitHub, checks its SHA-256 checksum, installs `bcdock.exe` to `%LOCALAPPDATA%\Programs\bcdock` and adds that folder to your user PATH. No admin rights needed. Works in Windows PowerShell 5.1 and PowerShell 7. Running it again upgrades to the latest release.

## macOS - Homebrew

```bash
brew install bcdock/tap/bcdock
```

## Windows - winget (pending)

Not available yet. Once the package is published, this will work:

```powershell
winget install bcdock.cli
```

## CI environments - npm wrapper

For CI runners that already have Node installed:

```bash
npm install -g @bcdock/cli
```

## Manual binary

Each release on [github.com/bcdock/cli/releases](https://github.com/bcdock/cli/releases) has one archive per platform, plus a `checksums.txt` with their SHA-256 hashes (`VERSION` is the release number without the `v`):

| OS | Arch | Archive |
|---|---|---|
| macOS | arm64 (Apple Silicon) | `bcdock_VERSION_macos_arm64.tar.gz` |
| macOS | amd64 (Intel) | `bcdock_VERSION_macos_x86_64.tar.gz` |
| Linux | amd64 | `bcdock_VERSION_linux_x86_64.tar.gz` |
| Linux | arm64 | `bcdock_VERSION_linux_arm64.tar.gz` |
| Windows | amd64 | `bcdock_VERSION_windows_x86_64.zip` (holds `bcdock.exe`) |

## Build from source

The CLI source lives at [`github.com/bcdock/cli`](https://github.com/bcdock/cli) (MIT). Requires Go 1.25+.

```bash
git clone https://github.com/bcdock/cli.git
cd cli
make build
./bin/bcdock version
```

## Verify the install

```bash
bcdock version
```

Expected output (your version and commit will differ):

```
VERSION  COMMIT   COMMIT DATE           API
0.5.10   f072397  2026-10-22T09:46:49Z  v1
```

If you see `command not found` (or, on Windows, "not recognized"), your install location isn't on `PATH`. The macOS and Linux script targets `/usr/local/bin`; Homebrew uses its own prefix. On Windows, open a new terminal after the install so it picks up the updated PATH.

## Next steps

- [Authenticate](auth.md) - log in or set a `BCDOCK_TOKEN` for CI/agent use
- [Concepts](concepts.md) - pool vs environment, hibernation, billing
- [CLI quickstart](../quickstart/cli.md) - five commands to a running BC environment
