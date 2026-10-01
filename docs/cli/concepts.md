---
title: CLI concepts - pools, environments, companies, hibernation
description: The mental model behind BCDock. Pools are Azure VMs; environments are Docker containers running BC. Hibernation drops billing without losing state.
---

# Concepts

Five things to know before running `bcdock` verbs in anger.

## Environment

**An environment is a Docker container running Business Central.** It has a name, a BC version, a country localisation, an `https://...bcdock.io/BC/` URL, and a billing meter. You create them, you delete them, you hibernate them, you resume them. They are the unit of work.

When you run `bcdock env create` you get back an environment record with a stable `id` (UUID), `name` (DNS-safe label), `webClientUrl`, and credentials for the BC `Administrator` user.

## Pool

**A pool is an Azure VM that hosts 2-9 environments.** Pools are infrastructure; we operate them, not you. We never stop pools - they always have a public FQDN, Traefik fronting them, and capacity for new environments.

You don't create or delete pools through the standard `bcdock env *` verbs. The autoscaler creates pools when capacity is tight and tears them down when they're idle. Each pool is locked to one BC version × country × artifact-type combination - same combination = same pool family.

Pool inspection lives in staff-only internal tooling, not the public `bcdock` CLI.

## Company

**A company is a billing entity.** One company per customer. All your environments belong to a company; that company gets the bill.

If you're a member of multiple companies (consultant, support engineer, agency staff), `bcdock companies list` shows them and `bcdock companies switch <id|name>` changes which one new commands run against. Switching mints a short-lived JWT (15 min) - re-run `auth login` or `auth set-token` to restore a long-lived key.

## Active vs stored states

Each environment lives in one of two metered states:

| State | What it means | Approx. cost |
|---|---|---|
| **Active** | Container is running on a pool, addressable at its URL, can serve requests | Per-second active rate (varies by pool VM size) |
| **Stored** (hibernated) | Container has been gzipped to blob storage; pool slot is freed | Metered stored rate, much lower than active |

Hibernation is the lever for "I'm not using this right now but I want it back later." `bcdock env hibernate <name> --wait` drops you into stored. `bcdock env resume <name> --wait` brings it back. State (data, installed extensions, configuration) survives hibernation.

Cross-major-version resume - e.g. a v27 env resumed onto a v28 pool - works but requires `--version` confirmation. See `bcdock env resume --help`.

## Lifecycle states

Environments transition through a small set of states:

```
queued → creating → running → (hibernating → hibernated → resuming → running)*
                  ↘ failed
                  ↘ deleting → deleted
```

`bcdock env wait <name> --status running --timeout 30m` is the right pattern in scripts and agent loops; it polls until any of the requested statuses is reached and exits with `124` on timeout, `5` on not-found.

## Why this model

Two design principles, both visible at the CLI surface:

1. **You manage environments, not infrastructure.** No "start VM," no "scale pool" verbs you have to think about. Pools are an implementation detail of the platform; you talk to them indirectly through environment operations.
2. **Hibernation is first-class, not an afterthought.** The whole stack - billing, blob storage, cross-pool resume - is built around the assumption that most environments are *not* running most of the time. The much-cheaper stored rate is what makes "spin up an env per PR" affordable.

For the architectural picture - how environments, pools, and the platform fit together - see [architecture/overview](../architecture/overview.md).

Looking for end-to-end tool-call transcripts? See [agent scenarios](agent-scenarios.md).
