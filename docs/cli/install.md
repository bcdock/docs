---
title: Install the bcdock CLI
description: Install the BCDock CLI on macOS, Linux, or Windows. Single static binary, no runtime dependencies.
---

# Install

The `bcdock` CLI is a single static binary with no runtime dependencies. Pick whichever path matches your environment.

!!! note "Distribution channels in flight"

    The Homebrew tap and winget package are still pending. The commands below document the canonical paths so they keep working unchanged once distribution lands.

## macOS / Linux — install script

```bash
curl -fsSL https://cli.bcdock.io/install.sh | sh
```

Detects your OS and architecture, downloads the matching binary from GitHub Releases, and installs it to `/usr/local/bin/bcdock`.

## macOS — Homebrew

```bash
brew install bcdock/tap/bcdock
```

## Windows — winget

```bash
winget install bcdock.cli
```

## CI environments — npm wrapper

For CI runners that already have Node installed:

```bash
npm install -g @bcdock/cli
```

## Manual binary

Until release artefacts are published publicly, build from source (next section). When releases ship, the archive layout will be:

| OS | Arch | Binary name |
|---|---|---|
| macOS | arm64 (Apple Silicon) | `bcdock-darwin-arm64` |
| macOS | amd64 (Intel) | `bcdock-darwin-amd64` |
| Linux | amd64 | `bcdock-linux-amd64` |
| Linux | arm64 | `bcdock-linux-arm64` |
| Windows | amd64 | `bcdock-windows-amd64.exe` |

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

Expected output:

```
bcdock 1.x.y (commit abcdef0)
```

If you see `command not found`, your install location isn't on `PATH`. The install script targets `/usr/local/bin`; Homebrew uses its own prefix.

## Next steps

- [Authenticate](auth.md) — log in or set a `BCDOCK_TOKEN` for CI/agent use
- [Concepts](concepts.md) — pool vs environment, hibernation, billing
- [CLI quickstart](../quickstart/cli.md) — five commands to a running BC environment
