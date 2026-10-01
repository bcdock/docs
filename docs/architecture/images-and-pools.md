---
title: Images and pools
description: BCDock's VM image cache, the pool model, and the autoscaler. Why pools host 2-9 environments. How draining works.
---

# Images and pools

Most BCDock provisioning time is spent in two places: building cached VM images and creating pool VMs. Both are amortised - one cached image serves many pools; one pool serves many environments. Knowing the model makes the timing surprises (and the cost shape) less surprising.

## VM image cache

BCDock caches prepared VM images per region so environments spin up quickly. The first time someone requests a particular BC version × country combination in a region, the platform builds the image cache (~78 minutes, one-time); subsequent environments in that combination provision from the cached image and are fast (the warm-pool case).

The cache is refreshed in the background when Microsoft publishes a new BC artifact for a cached version × country - existing pools keep serving from the previous image until the new one is rolled out, so customers don't see the rebuild.

## Pool model

A **pool** is an Azure VM hosting 2-9 BC containers. Pools are the load-bearing infrastructure unit:

- **Always running.** We never stop pools. A stopped pool means a stopped reverse proxy, which means broken URLs.
- **Hosts a single combination.** One pool = one BC version × country × artifact-type. Environments on the pool share the combination; you can't put a v27-au env on a v28-au pool.
- **Has its own DNS.** Each environment gets its own subdomain under `bcdock.io`.

### Why 2-9 containers

The lower bound (2) avoids the "whole pool to host one customer's empty env" cost shape - pools are sized so a typical concurrent workload of 2-4 active envs doesn't contend.

The upper bound (9) is empirical - beyond 9 we've seen routing and disk-IO contention show up under heavy AL compile load. Could be tuned upward with bigger pool VM sizes; we've stayed conservative pre-launch.

### Pool lifecycle states

| State | Meaning |
|---|---|
| `Creating` | Pool VM provisioning, Docker installing, agents deploying |
| `Running` | Operational; can accept new env allocations |
| `Draining` | Existing envs continue to run; no new allocations. Used when phasing out a BC version. |
| `Failed` | Provisioning failed; kept around for forensics, not destroyed automatically |
| `Deleting` / `Deleted` | Tearing down |

Allocating a new env always uses a `Running` pool - the autoscaler implicitly excludes other states.

## Autoscaler

A background service decides:

- **When to create a pool** - when env demand exceeds current pool capacity for a combination, or when you request a region/version that has no pool yet
- **When to delete a pool** - when a `Running` pool has been at 0 utilisation for a sustained window and isn't pinned
- **When to drain a pool** - when its BC version is being phased out

Pools can be pinned to exempt them from autoscaler deletion - useful for staging environments and "I want this exact pool for the next training run" scenarios. Pinning is staff-handled via internal tooling; if you need a pool pinned for a workshop or event, reach out via support@bcdock.io.

## Allocation algorithm

When you create an env:

1. **Check the image cache** - if the requested BC version × country combo isn't cached in the requested region, kick off the one-time image build (~78 min) and return a `queued` env.
2. **Check for pool** - is there a `Running` pool in the right region with capacity for one more env? If yes, allocate. If no, kick off pool create (~20 min) and queue.
3. **Allocate slot** - write the env-record row, ask the pool to start the container, return.

In the warm-pool case, only step 3 runs - provisioning completes in ~7-15 minutes. The other steps amortise across envs.

## Pre-warmed environments

For workloads where the warm-pool create wait is still too slow (training cohort, demo prep), the platform supports pre-warmed environments - created ahead of time on a pool slot, sitting in a `pending-assignment` state. When you request a matching env, we assign the pre-warmed one to you, bypassing the create wait.

This is a silent optimisation; there's no `pre-warmed` status in the public API. You see a fast `running` state and that's it.

## Why this shape matters

Three customer-visible consequences:

1. **First-time-for-a-combo is slow.** Building the image cache and creating the first pool for a brand-new BC version × country combination in a region takes around an hour and a half end-to-end. Every subsequent env in that combo provisions in ~7-15 minutes.
2. **Cross-region resume is supported.** The hibernation primitive plus the multi-pool model mean an env hibernated in `australiaeast` can resume on a `westus2` pool. Cross-region adds latency over same-region resume; see [hibernation](hibernation.md) for the per-operation timings.
3. **Our pricing is per environment, not per VM.** Several environments share each pool VM, and BCDock runs all the shared plumbing - the reverse proxy, HTTPS, DNS, monthly OS patches. Pooling lets us spread that cost across environments, so a managed environment costs less than renting and operating a dedicated Azure VM per env.

## How to plan around this

Two practical implications for consultants:

**First env on a new BC version × country combo is slow.** Plan for around 90 minutes the first time you provision e.g. v27 AU in `australiaeast`. Subsequent envs in that combo are fast (~7-15 minutes on a warm pool). For a known event (training class, demo prep, client kickoff), reach out to `support@bcdock.io` a day ahead and we'll pre-warm the combo so the first student / first attendee doesn't wait.

**Pool sharing is invisible by default.** Your envs share a VM with envs from other customers - separate Docker containers, separate databases, separate credentials, isolated at every level. For training cohorts or events where you want a dedicated pool (predictable performance under heavy concurrent load, no chance of a noisy neighbour), ask support to pin one for the duration.

## Read more

- [Hibernation](hibernation.md) - how the active/stored split interacts with pool capacity
- [URL shape](url-shape.md) - per-env URL format and how to wire it into VS Code `launch.json`
- [Reference: env states](../reference/env-states.md) - the customer-facing lifecycle states
