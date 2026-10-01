---
title: Glossary
description: Terms used across the BCDock platform - environment, pool, company, hibernation, template, and the rest.
---

# Glossary

Terms used across the BCDock platform. The two most important - **environment** and **pool** - are CRITICAL because they're often confused with each other or with VM-shaped things from other platforms.

## Environment

A **Docker container running Business Central**. Has a name, a BC version, a country localisation, an `https://...bcdock.io/BC/` URL, and a billing meter. You create, hibernate, resume, and delete environments. They are the unit of work.

You manage environments through the portal, the CLI (`bcdock env *`), or the API. You do **not** manage the underlying VMs - that's the platform's concern.

## Pool

An **Azure VM hosting 2-9 environments**. We operate pools; you don't. Pools are never stopped - they always have a public FQDN, Traefik fronting them, and capacity for new environments. The autoscaler creates pools when capacity is tight and tears them down when they're idle.

Each pool is locked to one combination of: BC version × country × artifact-type. An env can move between pools of the same combination (e.g. cross-region resume); it cannot run on a pool of a different combination.

Pool state inspection is staff-only via internal tooling, not exposed in the public `bcdock` CLI.

## Company

A **billing entity**. One company per customer. All your environments belong to a company; that company gets the bill.

If you're a member of multiple companies (consultant, support engineer, agency staff), `bcdock companies switch <id|name>` changes which one new commands run against.

## Active

An environment is **active** when its container is running and addressable at its URL. Active time is metered per-second against your subscription's active-rate cap or PAYG hourly rate.

## Stored / Hibernated

An environment is **stored** (the billing term) or **hibernated** (the operational term - same state) when its container has been gzipped to blob storage. The pool slot is freed. Billing drops to the much-lower stored rate. State (data, extensions, configuration) survives - resume any time and it's back exactly as you left it.

## Hibernation

The act of moving an env from `running` to `hibernated`. ~1-3 minutes for a typical env. Triggered by `bcdock env hibernate`, the portal Hibernate button, or auto-hibernate when a trial active bucket is exhausted.

## Resume

The act of moving an env from `hibernated` back to `running`. ~7-15 minutes on a warm pool of the same combination. Cross-major-version resume requires `--version <ver>` confirmation.

## Pre-warmed environment

An environment that was created ahead of time on a pool slot, sitting in a `pending-assignment` state. When you request a new env matching the same combination, we assign the pre-warmed one to you - bypassing the typical create wait. Silent optimisation; there's no "pre-warmed" status surfaced in the public API.

## Draining

A pool state. `Draining` pools serve their existing environments but won't accept new env allocations. Used when the pool's BC version is being phased out - existing customers stay running until they migrate or hibernate; new customers go to the active version's pool.

## Template (planned, H2 2026)

A **hibernated environment with identity detached**. Lets you instantiate new envs from a saved baseline (training, demos, client setups) at the stored rate. Same blob mechanics as hibernation; identity rewrite happens at clone time.

## Cloning (planned, H2 2026)

Copy an environment's state into a new environment with a fresh identity. Built on the hibernation primitive - clone = hibernate + blob copy + restore-with-new-identity.

## API key

A long-lived (`bdk_…`) credential the CLI uses for authentication. Scope-bounded, mintable in the portal, no refresh-token machinery. The right shape for agents, CI, and daily CLI use. See [API keys](api-keys.md).

## JWT

A short-lived (15 min access + 7 day refresh) credential issued by the OTP exchange or the portal session. Useful for interactive portal sessions; not the right shape for agents.

## Scope

A grant attached to an API key. Standard set: `env:read`, `env:write`. See [API keys](api-keys.md).

## BCDOCK_TOKEN

Environment variable the CLI reads first when looking for credentials. Wins over stored credentials. The right shape for ephemeral processes (CI, agents) - never writes to disk.

## Cached VM image

A prepared VM image stored per region so we can deploy a new pool VM without re-downloading and re-installing BC artifacts every time. One image per BC version × country combination. See [architecture / images and pools](../architecture/images-and-pools.md).

## Pool family

The set of pools sharing one combination of BC version × country × artifact-type. The autoscaler manages pool counts within a family; envs can move between pools within a family freely.

## SAS URL

Azure Storage Shared Access Signature. Time-limited signed URL granting access to a single blob. We use SAS URLs for hibernation backup snapshots (operator-only; envelope-signed for the platform's use) and for data export downloads (24h TTL, customer-facing).

## Provisioning logs

A platform-managed log stream keyed by env ID. Captures every stage of create / hibernate / resume / delete operations with structured fields. Excluded from the customer data export - it's operational telemetry, not personal data.

## Soft delete

Both blob storage (Azure-level, 7d recovery) and our DB (`deleted_at` column) implement soft delete. After the recovery window expires, hard-purge runs and the row/blob is unrecoverable. See [account-deletion](../guides/account-deletion.md) for the deletion-flow specifics.

## Anonymise-in-place

Our approach to GDPR Art. 17 / APP 11 erasure. Instead of cascade-deleting an anonymised user's rows (which would destroy FK integrity, audit trails, and financial records), we overwrite the User row's PII fields in place and leave referenced rows intact - they now point at an anonymous row. See [account-deletion](../guides/account-deletion.md).

## Related

- [Concepts](../cli/concepts.md) - the same terms in a longer-form mental model
- [Architecture overview](../architecture/overview.md) - how the pieces fit together
