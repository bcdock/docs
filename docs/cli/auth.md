---
title: CLI authentication - API keys, JWTs, and BCDOCK_TOKEN
description: How bcdock authentication works. When to use an API key vs a JWT. The three credential paths and which to use for CI, daily dev, or one-off overrides.
---

# Authentication

The CLI authenticates via either an **API key** (`bdk_…`) or a **JWT** (access + refresh). API keys are the right primitive almost everywhere - long-lived, scope-bounded, no refresh-token gymnastics. JWTs are short-lived and mostly used by the portal during browser sessions.

| | **API key** (`bdk_…`) | **JWT** |
|---|---|---|
| Lifetime | months/years (until revoked) | 15-min access + 7-day refresh |
| Scopes | explicit grants per key | implicit ("everything you can do") |
| Storage | `~/.config/bcdock/credentials.json` (mode 0600) | typically not stored - `auth login` exchanges OTP for an API key directly |
| Right for | **agents, CI/CD, scripts, daily CLI use** | **interactive portal sessions** |

## Three ways to set a credential

| Need | Use | Notes |
|---|---|---|
| **Persist creds for interactive dev** (across shell sessions, across reboots) | `bcdock auth login` | Preferred - runs OTP exchange and stores the resulting API key. Requires a TTY. |
| **Persist creds when `auth login` can't run** (non-TTY dev environments, restored creds after a `~/.config` wipe) | `bcdock auth set-token <bdk_…>` | Same on-disk result as `auth login`, but no OTP step. |
| **Ephemeral creds for one process** (CI, sandboxed agent, scripted run, per-call override) | `BCDOCK_TOKEN` env var | No disk write - dies with the process. Always wins over stored credentials. |

**Rule of thumb:** never persist secrets to disk in CI - use `BCDOCK_TOKEN`. On a developer laptop where you'll run `bcdock` dozens of times a day, persisted credentials via `auth login` are the right ergonomics.

## First-time access (invitation-gated)

BCDock is currently in early access. New accounts go through a two-step gate before they can log in:

```bash
# 1. Request access (or use the bcdock.io/waitlist form)
bcdock auth join-waitlist

# 2. When the invite email arrives, activate the account
bcdock auth signup --invite-code CODE --email you@example.com
```

`auth signup` activates the account but does not log you in - the OTP login is a separate step. After signup, follow the **Interactive login** flow below.

If you try `bcdock auth login` on a brand-new email without activating first, the API returns an explicit error with a hint to run `auth signup` - it never silently auto-creates accounts.

## Interactive login (humans)

```bash
bcdock auth login --email you@example.com
# Sends OTP → prompts for code → mints an API key
# Stored in ~/.config/bcdock/credentials.json as a bdk_* key (no refresh token)
```

`auth login` calls `POST /api/v1/auth/email/send-code` then `POST /api/v1/auth/email/exchange` and stores the resulting API key. The minted key receives the standard scopes (`env:read`, `env:write`) automatically.

## Set token (no-OTP persistence)

```bash
bcdock auth set-token bdk_abc123...
```

Use when you have a key already and want to persist it without going through OTP - typically:

- Switching the active credentials between accounts on a shared dev machine.
- Restoring after a `~/.config` wipe when you still have the key on hand.

If you find yourself reaching for `set-token` in CI, stop - use `BCDOCK_TOKEN` instead. The on-disk credential leaks past the process boundary and complicates secret rotation.

## Ephemeral token (CI, sandboxed agents)

```bash
export BCDOCK_TOKEN="bdk_abc123..."
bcdock --api-url https://api.bcdock.io me show
```

`BCDOCK_TOKEN` overrides any stored credentials and never writes to disk. This is the right shape for:

- CI/CD runners (token from secrets, exported per job).
- Cloud-hosted agents (Claude, Copilot Workspace, etc.) without a shared home directory.
- One-off "use this other key for one command" overrides during testing.

## Scopes

API keys are scope-bounded. Select scopes at creation time in the portal `/profile/api-keys`, or via the OTP exchange path (which always grants the standard three).

| Scope | Allows |
|---|---|
| `env:read` | list and inspect environments, view logs |
| `env:write` | create, delete, hibernate, resume, deploy extensions |

JWTs (typically obtained when navigating the portal, or via `companies switch` which mints a short-lived JWT for the new company context) bypass scope checks - they implicitly carry whatever you can do. JWTs expire in 15 minutes; this is a feature, not a bug, for interactive use.

## Verify

```bash
bcdock auth whoami       # core identity (email, role, company)
bcdock me show           # adds status + deletionScheduledAt
```

`whoami` is the fast "am I logged in as the right person" check. `me show` is the same query with additional fields; preferred when you also want to see deletion status (during 30-day grace) or programmatic JSON output.

## Logout

```bash
bcdock auth logout
# Best-effort revokes server-side, then clears ~/.config/bcdock/credentials.json
```

`logout` clears the on-disk credentials regardless of network success. To revoke a key without clearing local state (e.g., revoking a leaked key from a different machine), use the portal `/profile/api-keys` page.
