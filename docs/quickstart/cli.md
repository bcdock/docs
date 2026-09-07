---
title: CLI quickstart - your first BC environment
description: Install bcdock, log in, create a Business Central environment, hibernate it. Five commands; the env itself takes ~7-15 minutes to provision.
---

# CLI quickstart

Goal: from nothing installed to a running Business Central environment with a URL you can open in a browser. Five commands; the create step waits ~7-15 minutes for provisioning.

## 1. Install

```bash
curl -fsSL https://cli.bcdock.io/install.sh | sh
```

Other paths (Homebrew, npm, manual binary) on the [install page](../cli/install.md).

Verify:

```bash
bcdock version
```

## 2. Get access (currently invitation-only)

BCDock is in early access - new accounts are gated by invitation. The path:

```bash
# Once: request access
bcdock auth join-waitlist

# When the invite email arrives (typically within 48 hours), activate your account
bcdock auth signup --invite-code CODE --email you@example.com
```

`auth signup` activates the account. From there, normal login:

```bash
bcdock auth login --email you@example.com
```

Prompts for the OTP we email you, exchanges it for a long-lived API key stored at `~/.config/bcdock/credentials.json` (mode 0600).

Returning users skip steps 1-2 and run `bcdock auth login` directly.

If you're scripting this from CI or an agent, skip `auth login` entirely and set `BCDOCK_TOKEN` — see [authentication](../cli/auth.md).

## 3. See what BC versions are available

```bash
bcdock artifacts list --region australiaeast
```

Lists the BC version × country combinations the platform can provision in that region. Versions with `hasVmImage: true` provision in ~7-15 min on a warm pool; the rest take substantially longer for first-time image build.

## 4. Create an environment

```bash
bcdock env create --name my-first-env --version 27 --country au --wait
```

`--wait` blocks until the environment is `running` (or `failed`). Default timeout is 30 minutes; warm pools usually return in ~7-15 minutes.

Output (truncated):

```
NAME           STATUS    VERSION   COUNTRY   URL
my-first-env   running   27.0      au        https://my-first-env-a1b2c3d4.bcdock.io/BC/
```

Get full details and the web client URL:

```bash
bcdock env get my-first-env -o json | jq
```

The BC admin **password is not in that response**. Reading an environment happens
constantly - on every page load, in every poll, in every script - and a credential that
rides along on all of it ends up in far more places than you chose to put it. Ask for it
explicitly instead:

```bash
bcdock env credentials my-first-env
```

Each reveal is recorded in your audit trail, so you can see when the credentials for an
environment were last handed out.

Open the `webClientUrl` in your browser; sign in as `Administrator` with that password.

## 5. Hibernate when you're done

```bash
bcdock env hibernate my-first-env --wait
```

Saves the environment state to blob storage and frees the pool slot. Billing drops to the much-lower stored rate. Resume any time:

```bash
bcdock env resume my-first-env --wait
```

Or delete entirely:

```bash
bcdock env delete my-first-env --force --wait
```

## Next steps

- [Authentication](../cli/auth.md) — API key vs JWT, scopes, when to use each credential path
- [Concepts](../cli/concepts.md) — what a pool is, what hibernation costs, how the billing model works
- [Exit codes](../cli/exit-codes.md) — what to do when a script gets a non-zero exit
- [Command reference](../cli/reference/bcdock.md) — every verb, every flag

## Troubleshooting

**`bcdock: command not found`** — the install script puts the binary in `/usr/local/bin`. Make sure that's on your `PATH`.

**`error: not authenticated`** (exit 3) — run `bcdock auth login` again, or set `BCDOCK_TOKEN`.

**`env create` hangs past the timeout** — first-time image build for an unseen version × country combo can take ~15 min. Re-run with `--wait-timeout 30m` or check status periodically with `bcdock env get <name>`.

**Long-running command in an agent session** — pass `run_in_background` to the agent's Bash tool so the session stays free. The agent gets a notification when the command exits.
