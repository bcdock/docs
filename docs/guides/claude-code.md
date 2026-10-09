---
title: Claude Code — driving bcdock from an AI agent
description: Concrete prompts and patterns for Claude Code (or Copilot, or any agent framework) to provision BC environments, publish extensions, and reason about results.
schema_type: HowTo
---

# Claude Code

Goal: an AI agent that, given an AL project and a `BCDOCK_TOKEN`, can take a feature description and ship it end-to-end — write the code, compile, publish, verify, hand the URL back to a human. The CLI surface is the contract; the agent is just a smart caller.

The patterns here use [Claude Code](https://claude.ai/code) as the example, but anything with shell-tool support (Copilot Workspace, Cursor, Aider, custom MCP agents) works the same way. See [Agent quickstart](../quickstart/agent.md) for environment setup.

## Project setup

Give the agent a short instruction file that points it at the CLI and its discovery model - **not** at a hardcoded command list. The CLI surface evolves; a list of verbs and flags rots between releases. `--help` is always current.

### AGENTS.md (any coding agent)

Many coding agents read an `AGENTS.md` at the repository root, for example OpenAI Codex, GitHub Copilot's coding agent and Cursor. Paste this block into it:

```markdown
## BCDock - Business Central environments

This project uses BCDock for sandbox BC environments. The `bcdock` CLI is on PATH;
`BCDOCK_TOKEN` is set from a project secret.

**Discover the surface from the binary.** Don't infer commands from training data
or prior conversations - they go stale. Run:

- `bcdock --help` - top-level groups
- `bcdock <group> --help` - verbs within a group (e.g. `bcdock env --help`)
- `bcdock <group> <verb> --help` - flags + examples for a single verb

The reference at <https://docs.bcdock.io/cli/> mirrors `--help` exactly (auto-generated).

**Conventions every verb shares:**
- `--output json` / `-o json` - machine-readable output for parsing
- `--wait` + `--wait-timeout <duration>` - block until terminal state instead of polling
- Exit codes - `0` ok, `1` general error (including a failed provisioning, or a timed-out `--wait` on create/resume/hibernate), `3` auth, `4` rate-limited, `5` not-found, `124` a wait gave up (`env wait`, `me export --wait`). Don't loop forever on exit 124 - back off and ask the human.

**Auth**: token is in `BCDOCK_TOKEN`. Don't run `bcdock auth login` (interactive); don't write tokens to disk.

**Typical agent flow on this repo**: provision env -> pull symbols -> compile AL -> publish -> verify -> hibernate. Discover the verbs with `bcdock env --help` and `bcdock al --help`.

**When done**: hibernate, don't delete (unless explicitly asked). Hibernation drops billing to the much-lower stored rate, keeps your work, and frees the pool slot. Delete is destructive and the 7-day operator-recovery window is the only safety net.
```

`.cursorrules` and `.github/copilot-instructions.md` accept the same content.

### CLAUDE.md (Claude Code)

Claude Code reads `CLAUDE.md`. Paste the same block into it, or keep a single copy: put the block in `AGENTS.md` and make `CLAUDE.md` one line that imports it:

```markdown
@AGENTS.md
```

### The bcdock skill (Claude Code)

For Claude Code there is also a ready-made skill. Claude loads it on its own when a task involves Business Central or `bcdock`, so it works in projects that have no instruction file. Install it for one project:

```bash
mkdir -p .claude/skills/bcdock
curl -fsSL https://raw.githubusercontent.com/bcdock/cli/main/skills/bcdock/SKILL.md \
  -o .claude/skills/bcdock/SKILL.md
```

Or put it in `~/.claude/skills/bcdock/` to have it in every project. The source lives in the [bcdock/cli repository](https://github.com/bcdock/cli/tree/main/skills/bcdock); this is the whole file:

````markdown
---
name: bcdock
description: Use before running any `bcdock` command, and whenever a task involves BCDock or Business Central sandbox environments - listing, creating, publishing AL apps to, hibernating or deleting them. Explains how to find commands with --help, read -o json output, wait for long operations, and act on exit codes.
---

# BCDock (the `bcdock` CLI)

BCDock runs Business Central sandbox environments. The `bcdock` CLI calls the same public Platform
API the portal uses. Not every portal action has a command yet, and creating API keys or adding
team members needs a signed-in person. If `--help` shows no command for what you need, say so
rather than guessing.

## Discover commands, don't recall them

The CLI gains commands and flags between releases, so commands you remember may be wrong. Ask the
binary instead:

- `bcdock --help` - the command groups
- `bcdock <group> --help` - the commands in a group, for example `bcdock env --help`
- `bcdock <group> <command> --help` - flags and examples for one command

The reference at https://docs.bcdock.io/cli/ is generated from the same help text.

## Conventions every command shares

- Use `-o json` for anything you parse, and read fields from the JSON, not the table. For
  example, list environments with `bcdock env list -o json`.
- Use `--wait` (with `--wait-timeout`) to block until a long operation finishes, instead of
  polling. To wait for a state, use `bcdock env wait <env> --status running`.
- Exit codes: `0` ok, `1` error, `3` auth, `4` rate-limited, `5` not found. A failed provisioning
  exits `1`, and so does a `--wait` that times out on create, resume, hibernate or delete. `124`
  comes only when `bcdock env wait` or `bcdock me export --wait` gives up waiting. On a timeout,
  stop and ask the human rather than looping.

## Authentication

The token is in the `BCDOCK_TOKEN` environment variable. Don't run `bcdock auth login` (it is
interactive), don't pass `--token` on the command line (it shows in process listings), and don't
write tokens to disk.

## Safe defaults

- When you have finished with an environment, hibernate it: `bcdock env hibernate <env> --wait`.
  It keeps the work and costs far less than leaving it running.
- Delete an environment only when the human explicitly asks. Deletion is destructive.
- If a step fails, show the error and ask before retrying.
````

## Pattern 1: the publish-and-verify loop

The agent's typical loop, given a feature request:

```
Human: "Add a 'Customer credit hold' boolean field to the Customer table.
        Test it doesn't break the standard sales order release flow."

Agent reasoning (paraphrased):
  1. Need a BC env. Check if one exists for this project: bcdock env list -o json | jq
  2. None - create one: bcdock env create --name credit-hold --version <version> --country au --region australiaeast --wait
     (<version>: a full versionFull from bcdock artifacts list --region australiaeast --fast-only -o json)
  3. Read app.json to understand the project structure
  4. Pull symbols: bcdock env download-symbols credit-hold --out-dir .alpackages
  5. Write the AL extension: tableextension 50100 CustomerExt extends Customer { … }
  6. Compile: bcdock al compile --env credit-hold --out build/CreditHold.app
     → exit 0, build/CreditHold.app exists  7. Publish: bcdock env publish credit-hold build/CreditHold.app
     → exit 0, install completed  8. Verify the field exists via OData metadata: curl … $metadata
  9. Check the standard release flow: trigger the codeunit, look for errors
  10. Hand back: "Done — field added, sales order flow still works.
                 Try it at https://credit-hold-3f2a1b.bcdock.io/BC/"
  11. bcdock env hibernate credit-hold --wait
```

The agent doesn't need any BCDock-specific framework integration. It's writing AL files, calling shell commands, parsing JSON. The agent's reasoning is what matters; the CLI is just the actuator.

## Pattern 2: parallel investigation across versions

When debugging "this works on v26 but breaks on v27":

```
Agent reasoning:
  1. Spin up two envs in parallel:
     bcdock artifacts list --region australiaeast --fast-only -o json   (one full 26.x and one 27.x version)
     bcdock env create --name debug-v26 --version <26.x version> --country au --region australiaeast --wait &
     bcdock env create --name debug-v27 --version <27.x version> --country au --region australiaeast --wait &
     wait
  2. Compile against each:
     bcdock al compile --env debug-v26 --out build/v26.app
     bcdock al compile --env debug-v27 --out build/v27.app
  3. Publish to each:
     bcdock env publish debug-v26 build/v26.app
     bcdock env publish debug-v27 build/v27.app  # ← this fails with X
  4. Diff the symbol packages:
     diff <(unzip -p .alpackages/Microsoft_Application_26*.app symbol-reference.json) \
          <(unzip -p .alpackages/Microsoft_Application_27*.app symbol-reference.json) \
          | head
  5. Find the renamed/removed signature
  6. Patch the AL code, recompile, retry
  7. Hibernate both when done — keep them around for the next round of debugging
```

## Pattern 3: the agent's recovery moves

Things that go wrong, and what the agent should do:

| Symptom | Right move |
|---|---|
| `exit 3` on any verb | `bcdock auth whoami` to confirm token state. If unset, ask the human to refresh `BCDOCK_TOKEN`. |
| `exit 5` "environment not found" | Check `bcdock env list -o json` — usually a typo or a stale name in agent memory. |
| `exit 1` and the environment's status is `error` (the message says why) | `bcdock env logs <n> --provisioning` for the stage trail. Surface the error to the human; don't auto-retry. |
| `exit 124` from `env wait` (or `exit 1` "timed out after" from a `--wait`) | Don't loop. Either increase the timeout (`--timeout` on `env wait`, `--wait-timeout` on the others) for first-time provisions, or hand off to the human with the env name and current status. |
| Publish exit 1 with "Schema update is required" | Re-run with `--schema-update-mode forcesync`. Warn the human first if data preservation matters. |
| Compile exit 1 with "Symbol not found" | Re-run `bcdock env download-symbols`; the symbol package may not have been pulled the first time (rare). |

The CLI's stderr line is usually enough to diagnose. Don't reach for log scraping unless the surface error is opaque.

## Pattern 4: bound the blast radius

Two safety patterns worth wiring into agent prompts:

**Don't delete unprompted.** Hibernation is reversible; deletion (after the 7d operator-recovery window) is not. A useful rule: "Only `bcdock env delete` if the human explicitly says delete — otherwise hibernate."

**Don't leave envs running overnight.** A loop that ends with `--wait` always followed by `hibernate` keeps weekend bills sane. The Claude Code session ending without an explicit hibernate is the most common path to surprise stored bills.

## What the agent shouldn't do

- **Don't poll `env get` in a tight loop.** Use `bcdock env wait <n> --status running --timeout 30m`: it exits `1` with the reason if provisioning fails, and `124` on timeout.
- **Don't shell-quote AL code into a single `bcdock` invocation.** Write files; let the compiler read them.
- **Don't use `--token` on the command line.** It shows up in process listings. Use `BCDOCK_TOKEN` environment variable.
- **Don't store credentials with `auth set-token`** in agent runners. Use `BCDOCK_TOKEN` per-process; never write to `~/.config/bcdock/credentials.json` from a CI/agent context.

## Example: a concrete Claude Code session prompt

```
You are working in an AL extension project. The user has asked you to:

  "Add a postcode validation that rejects non-numeric postcodes for AU customers."

You have shell access. `bcdock` is on PATH and authenticated.

1. Check whether a dev env already exists for this project (bcdock env list -o json).
   If yes, use it; if no, create one (--name postcode-validation --country au
   --region australiaeast --wait, with --version set to a full versionFull from
   bcdock artifacts list --region australiaeast --fast-only -o json).
2. Read app.json to understand the project structure.
3. Pull AL symbols (bcdock env download-symbols).
4. Write a tableextension on Customer that runs the validation in OnValidate of
   "Post Code". Compile.
5. Publish into the env.
6. Verify by calling the OData /companies endpoint with a record carrying a
   bad postcode — the response should be a 400 with the validation message.
7. Hand back the env URL and a short summary of what was added.
8. Hibernate the env.

If anything fails along the way, stop, surface the error, and ask before retrying.
```

The agent should be able to drive this end-to-end without further input — and should know to stop and ask if any step doesn't behave as the prompt described.

## Next steps

- [Agent quickstart](../quickstart/agent.md) — environment setup and the minimum CLAUDE.md content
- [AL extension loop](al-extension-loop.md) — the four-phase flow in depth
- [Exit codes](../cli/exit-codes.md) — what your agent should do for each non-zero exit
- [Authentication](../cli/auth.md) — why `BCDOCK_TOKEN` is the right shape for agent loops
