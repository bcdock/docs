---
title: Hibernation
description: How BCDock environments hibernate to blob storage and resume on demand. The dual-rate billing model. Cross-version resume.
---

# Hibernation

Hibernation is BCDock's lever for "I'm not using this env right now but I want it back later." It collapses an environment from a running container into a gzipped blob, frees the pool slot, drops billing to the much-lower stored rate, and lets you resume on demand - possibly on a different pool in a different region.

This page is the public summary of the dual-rate billing and cross-major-version resume designs.

## The two states

| State | What it is | Active billing? | Stored billing? |
|---|---|---|---|
| `running` | Container is up, URL responds, BC database mounted | yes | no |
| `hibernated` | Container is gzipped to blob storage; pool slot freed | no | yes (metered stored rate) |

Reaching `hibernated`: run `bcdock env hibernate <name>` (or click the portal **Hibernate** button). A few minutes later, the env's running container is snapshotted and uploaded to the region's blob storage, and the pool's container is destroyed. The env-record row stays; the URL becomes inert.

Reaching `running` again: run `bcdock env resume <name>` (or the portal **Resume** button). The platform picks any compatible pool (same BC version × country × artifact-type), copies the blob if needed, and starts a fresh container restored from the snapshot.

## What gets snapshotted

The container's complete state, including:

- **BC database** - your tables, customizations, custom apps, every change since the env was created
- **Container filesystem** - published `.app` files, certificates you've added, anything in `/BC` data dirs
- **Container configuration** — environment variables, mounted volumes, the BC server config
- **Container metadata** — admin password, Web Service Access Key, BC version, locale

What's *not* in the snapshot:

- **Pool-level state** - reverse-proxy routes and other pool infrastructure. These are reconstructed when the env is allocated to a pool.
- **DNS records** — recreated on resume.
- **Per-env Key Vault entries** — the admin password lives in the regional Key Vault, not in the snapshot blob.

## Where the blob lives

Per region. An env hibernated in `australiaeast` writes its blob to the `australiaeast` storage account. Cross-region resume copies the blob to the target region's storage account first, then restores from there.

Soft-delete is enabled on the storage account (7-day recovery). After env delete + 7 days, the blob is unrecoverable.

## Cross-version resume

When your environment is hibernated at one BC version but the pool you'd resume to is at a newer version, BCDock asks you to confirm the upgrade before proceeding. This happens when the original BC version is being phased out - typically because Microsoft has retired it.

```bash
bcdock env resume my-env
# error: cross-version resume requires confirmation
# error: env hibernated at 27.0; available pool is at 28.0
# error: re-run with --version 28 to confirm

bcdock env resume my-env --version 28 --wait
# proceeds with the cross-major upgrade
```

The platform never makes this call silently - version upgrades can break extensions and shift data shape, so the decision stays with you. Before confirming, check that your AL extensions are compatible with the target BC version.

Forward only - you can take an env hibernated at v27 onto a v28 pool, but not the other way around. Forward resume is the documented escape hatch when an old BC major is being drained.

## The dual-rate billing model

Active and stored states bill at independent rates. Per environment, billed per second:

- **Active rate** - metered per-second while the env is running; the rate depends on your plan tier (PAYG carries a higher per-hour rate than subscription tiers)
- **Stored rate** - metered per-second, the same across every plan tier

Why uniform across tiers: the underlying cost of holding a BC backup blob doesn't change with the plan. Tiering it would just be price discrimination. Current rate lives on the [pricing page](https://bcdock.io/pricing).

The math that matters: if you run an env active for half the month and hibernated for the other half, your bill prorates to roughly half the active rate plus half the stored rate - not "half a month of active billing" alone.

## Why hibernation is first-class

Two design principles, both visible in the rest of the system:

1. **Most environments aren't running most of the time.** A consultant testing a customisation uses the env for 4 hours, then hibernates for two weeks until the next client meeting. A CI pipeline spins one up per PR, runs tests, hibernates between pushes. The whole stack — billing, blob storage, autoscaler — is built for this shape.
2. **The cheap stored rate makes "spin up an env per PR" affordable.** Without it, leaving 5 PRs open over a weekend means paying the active rate for the whole weekend on every one. With it, parked PRs pay only the much-lower stored rate. That's the difference between "BCDock is a vendor we use sparingly" and "BCDock is the primitive in our pipeline."

## Performance

| Operation | Typical time | Notes |
|---|---|---|
| Hibernate | ~1-3 minutes | Container gzipped to blob, then container destroyed. Most time is in the gzip + upload. |
| Resume (warm pool, same region, same version) | ~7-15 minutes | Container started, blob downloaded, restore completes. Most time is in the download. |
| Resume (cross-region) | ~10-25 minutes | Adds a blob copy from source region storage to target region storage on top of the base resume. |
| Resume (cross-major version) | ~10-25 minutes | Adds the BC platform upgrade on top of the base resume. |

The autoscaler's pool warming targets the warm-pool case - most resumes finish in ~7-15 minutes against a pool that already has the right combination running.

## What's planned (not shipped)

- **Templates** (H2 2026) — hibernated env with identity detached, instantiate new envs from a saved baseline at the stored rate. Same blob mechanics; identity rewrite at clone time.
- **Cloning** (H2 2026) — copy an env's state into a new env with a fresh identity. Built on the hibernation primitive.
- **Auto-hibernate on idle** - a policy that hibernates an env after it hasn't been hit for some configurable period. Listed but contentious; if you want it, tell us via [support@bcdock.io](mailto:support@bcdock.io).

## When you'd reach for hibernation

The two-state billing model isn't theoretical - here's where it pays off in real consultancy work:

- **Between client meetings.** Hibernate Friday at 5pm; resume Tuesday morning. Same URL, same data, fraction of the cost of leaving it running over the weekend.
- **Training cohort.** 20 student envs hibernate after the class ends. Resume next session week; everyone's exercises are where they left them.
- **PR-per-branch.** Each PR gets a fresh env; hibernate between pushes; delete on close. The stored rate makes "10 open PRs" affordable when "10 running envs" wouldn't be.
- **Long-running PoC.** A pilot env can sit hibernated for months at the stored rate while the client gathers feedback, then resume on demand for the next session.
- **Version-comparison debugging.** Spin up envs at v26 and v27, capture the bug repro, hibernate both. Resume only when you need to dig deeper - no need to keep two envs running for a week-long investigation.

## Read more

- [Reference → env states](../reference/env-states.md) — the complete lifecycle state machine
- [Images and pools](images-and-pools.md) — how pool capacity interacts with hibernation
- [Anonymisation](anonymisation.md) — how hibernation backups interact with account deletion
