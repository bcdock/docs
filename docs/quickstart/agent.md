---
title: Agent quickstart — let Claude or Copilot drive bcdock
description: Set BCDOCK_TOKEN, point your agent at the bcdock CLI, ship an AL extension end-to-end. The agent floor of BCDock.
---

# Agent quickstart

Goal: have an AI agent (Claude Code, Copilot, or any framework that can run a CLI) provision a BC environment, publish an AL extension into it, and read the URL back. The CLI commands take seconds to type; provisioning the env itself takes ~7-15 minutes. Same product as the portal - different floor.

## Why agents work with BCDock

The CLI is the API. Every verb supports `--output json`, every async operation has `--wait`, every error has a documented [exit code](../cli/exit-codes.md). Agents read `--help` natively and parse JSON. There is no "agent SDK" to integrate; you give the agent shell access to `bcdock` and it works.

This is deliberate: the CLI is the primary API tool, there are no portal-only capabilities, and anything a human can do through the dashboard an agent can do through `bcdock`.

## 1. Mint a scoped API key

In the portal go to **Profile → API keys → Create**. Pick scopes:

- `env:read` + `env:write` — enough for the standard create / publish / hibernate / delete loop, plus reading per-env usage via `bcdock env usage`.

Copy the resulting `bdk_…` token once — you can't view it again. Store it in your secret manager (`gh secret set`, `op create item`, `pass insert`, `aws secretsmanager`, etc.). Never paste it into agent chat history.

## 2. Hand the token to your agent

```bash
export BCDOCK_TOKEN="bdk_…"
```

`BCDOCK_TOKEN` overrides any stored credentials and never writes to disk — exactly the right shape for ephemeral agent sandboxes.

If the agent has its own secret-injection mechanism (Claude Code project settings, Copilot Workspace secrets, GitHub Actions `secrets`), use that and skip the manual export.

## 3. Tell the agent what it can do

Drop a `CLAUDE.md` (or `.cursorrules`, or `.github/copilot-instructions.md`) into the project the agent works on. The goal of this file is **not** to enumerate commands — the CLI evolves and a stale list rots faster than it helps. Instead, point the agent at discovery and the conventions every verb shares:

```markdown
## BCDock — Business Central environments

This project uses BCDock for sandbox BC environments. The CLI is the API.

**Discover the surface yourself, don't guess from prior memory.**
- `bcdock --help` — top-level groups
- `bcdock <group> --help` — verbs within a group (e.g. `bcdock env --help`)
- `bcdock <group> <verb> --help` — flags + examples for a single verb

The reference site at <https://docs.bcdock.io/cli/> has every page auto-generated from the binary; treat it as authoritative if `--help` is unavailable.

**Conventions that apply to every verb:**
- `--output json` (or `-o json`) — machine-readable output for any verb you parse
- `--wait` (+ optional `--wait-timeout`) — block until terminal state instead of polling
- Exit codes — `0` ok, `3` auth, `5` not-found, `10` provisioning failed, `124` `--wait` timeout. Documented at <https://docs.bcdock.io/cli/exit-codes/>; full list with `bcdock --help`.

**Authentication:** read the `BCDOCK_TOKEN` environment variable (already set from a project secret). Don't run `bcdock auth login` — it's interactive. Don't write tokens to disk.

**Typical workflow for this project:** provision an env → pull AL symbols → compile → publish into BC → verify → hibernate when done. Discover the verbs for that flow with `bcdock env --help` and `bcdock al --help`. Hibernation is the right "I'm done" action; deletion (per `bcdock env delete --help`) is destructive and should require an explicit human ask.
```

Why discovery-first beats a hardcoded list: the CLI gains verbs and flags between releases. A `CLAUDE.md` that names specific flags will lie to the agent the first time those flags change. `--help` is always current.

## 4. End-to-end loop

A complete agent session — create env, build and publish extension, verify, tear down:

```bash
# 1. Provision (--wait blocks until running or failed; ~7-15 min on a warm pool)
bcdock env create --name agent-test --version 27 --country au --wait -o json

# 2. Pull AL symbols matching the env's BC version into .alpackages/
bcdock env download-symbols agent-test --out-dir .alpackages

# 3. Compile against the env's bundled alc (cached per platform version)
bcdock al compile --env agent-test --out build/MyExtension.app

# 4. Publish — POST to BC's /dev/apps. Synchronous; returns when install completes.
bcdock env publish agent-test build/MyExtension.app

# 5. Read back the URL the agent should hand to the human
URL=$(bcdock env get agent-test -o json | jq -r .webClientUrl)
echo "BC ready at: $URL"

# 6. Hibernate when the agent is done (free the pool slot, drop to stored rate)
bcdock env hibernate agent-test --wait
```

A reasoning agent driving this loop should:

- **Parse exit codes** — exit 3 means re-authenticate, exit 5 means the env name didn't resolve, exit 10 means provisioning failed (read logs), exit 124 means a `--wait` timed out (don't loop forever — back off and tell the human).
- **Use `--output json`** for any step the next step depends on. The CLI's table format is for humans.
- **Prefer `bcdock env wait <n> --status running --status failed --timeout 30m`** over polling `env get` in a loop.

## 5. Run long operations in the background

Image builds (~45 min) and pool creation (~20 min) take long enough that an interactive agent session shouldn't block on them. Tell the agent:

> Run this in the background and notify me when it's done.

Claude Code's Bash tool accepts `run_in_background: true`. The agent gets a notification when the command exits and the conversation stays usable.

## What's next

- [Agent scenarios](../cli/agent-scenarios.md) — end-to-end tool-call transcripts you can copy-and-adapt
- [AL extension loop guide](../guides/al-extension-loop.md) — the four-phase flow in depth, with verification patterns
- [GitHub Actions guide](../guides/github-actions.md) — same loop in CI, one ephemeral env per PR
- [Claude Code guide](../guides/claude-code.md) — concrete agent prompts and patterns
- [CLI reference](../cli/reference/bcdock.md) — every verb, every flag, auto-generated from the binary
- [Authentication](../cli/auth.md) — API key vs JWT, scopes, the three credential paths

## Troubleshooting

**`error: not authenticated`** (exit 3) — `BCDOCK_TOKEN` is unset, expired, or revoked. Refresh from the portal.

**`error: scope insufficient`** (exit 1) — the API key doesn't carry the scope the verb needs. Check the [authentication scopes table](../cli/auth.md#scopes) and re-mint with the right grants.

**Agent can't find `bcdock`** — install on the agent's host with the [install script](../cli/install.md) or `npm install -g @bcdock/cli` for Node-based agent runners.

**Provisioning fails with "image not ready"** - first-time use of a version × country combo triggers a ~78 min image build that the platform runs in the background. Your options are: (a) accept the cold-start delay, or (b) ask BCDock support to pre-warm a pool for that combination ahead of time.
