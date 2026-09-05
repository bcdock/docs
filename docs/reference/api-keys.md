---
title: API key scopes
description: BCDock API key scopes - what each grants, when to use which, how to mint and revoke.
---

# API keys

The `bcdock` CLI authenticates with **API keys** (`bdk_…`) almost everywhere. Long-lived (until revoked), scope-bounded, no refresh-token gymnastics. Mint them in the portal at **Profile → API keys**.

For the JWT vs API-key mental model, see [authentication](../cli/auth.md).

## Scopes

Pick the smallest set that lets the consumer do what it needs.

| Scope | Allows | Don't grant if… |
|---|---|---|
| `env:read` | List environments, inspect details, read logs, read per-env usage | Always include - required for almost every other action to surface useful errors |
| `env:write` | Create / delete / hibernate / resume environments; publish AL extensions | The consumer is read-only (status dashboards, billing reports) |

API keys minted via `bcdock auth login` (the OTP exchange path) automatically receive both scopes.

## How to mint

From the portal:

1. **Profile → API keys → Create**
2. Name the key (e.g. `ci-pipeline`, `claude-agent`, `release-bot`)
3. Pick scopes
4. Click **Create**
5. Copy the `bdk_…` token - **you can't view it again**

The portal stores only the prefix and a hash; the bytes you copy are the only way to use the key.

**A key can only grant what it already holds.** Minting from the portal is unrestricted - your
session can already do these things directly, so the key just carries your own authority. But if
you mint a key *using another key*, the new one can carry at most the scopes the old one carries:
an `env:read` key cannot create an `env:write` key. Rotate through the portal rather than by
chaining one key off another.

## How to use

Three paths, in order of preference:

| Path | When | Persistence |
|---|---|---|
| `BCDOCK_TOKEN` env var | CI, agents, ephemeral runners | none - dies with the process |
| `bcdock auth login` | Daily dev on a personal laptop | `~/.config/bcdock/credentials.json` (mode 0600) |
| `bcdock auth set-token <bdk_…>` | When you have a key already and want to persist it | same as `auth login` |

**Rule of thumb**: never persist secrets to disk in CI - use `BCDOCK_TOKEN`.

## Verify what a key has

```bash
bcdock auth whoami
```

Prints the token's identity (email, role, company). Doesn't print the scopes directly today; if you need that, list keys in the portal - the row shows the scopes you picked at creation.

## Revoke

In the portal: **Profile → API keys → Revoke** on the row. Takes effect immediately for new requests; in-flight requests complete.

A CLI verb for programmatic revocation is on the roadmap. Until it ships, the portal is the path - which is also the right shape for most rotations (a human decides "this key shouldn't work anymore" and clicks once).

## Rotation

We don't auto-rotate keys. When a contributor leaves or a runner is decommissioned:

1. Mint a fresh key with the same scopes
2. Update the consumer's secret store
3. Revoke the old key

Both keys work in parallel during the swap, so there's no service interruption.

## Common pitfalls

- **Pasting `bdk_…` into chat history** (Slack, agent conversation log, Discord). Treat it like a password.
- **Granting more scopes than needed.** The smallest grant that works is the right approach - if a consumer only reads, don't grant `env:write`.
- **Reusing one key across multiple unrelated repos / pipelines.** Hard to attribute audit-log entries; rotation has higher blast radius. One key per consumer is the right shape.
- **Storing keys in `~/.config/bcdock/credentials.json` on shared servers.** Every user with read access on that file can act as that key. Use `BCDOCK_TOKEN` per-process for shared infrastructure.

## Related

- [Authentication](../cli/auth.md) - API key vs JWT, the three credential paths
- [Exit codes](../cli/exit-codes.md) - `exit 3` is auth, `exit 1` with "scope insufficient" is the wrong scopes
- [Agent quickstart](../quickstart/agent.md) - `BCDOCK_TOKEN` is the right shape for agent loops
