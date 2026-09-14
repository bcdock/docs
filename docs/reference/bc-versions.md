---
title: BC versions and regions
description: Which Business Central versions BCDock supports, in which Azure regions, with which country localisations and artifact types. The live source is the artifact catalog API.
---

# BC versions and regions

BCDock provisions environments along three independent dimensions: **BC version × country localisation × artifact type**, in any of the available Azure regions. Not every combination exists — Microsoft publishes BC artifacts for specific country/version pairs, and we mirror what's available.

The **live source of truth** is the artifact catalog. From the CLI:

```bash
bcdock artifacts list --region australiaeast
```

That returns every version × country combination available in that region, with a `hasVmImage` flag indicating which combinations have a pre-built BCDock image (fast provisioning) vs which would trigger a one-time image build (~78 min).

This page is a structural reference: what shape the matrix takes, what each dimension means, and where we provision today.

## Dimensions

### Major and minor versions

BC follows a `<major>.<minor>` numbering — major releases are roughly biannual, minor releases monthly. We support recent majors (typically the current one and the previous one, sometimes the one before that during transition windows). Within a supported major, all minor releases are available unless explicitly retired.

The `Active` set — the BC versions our autoscaler will keep pools running for — is curated. Versions outside the Active set go into `Draining` mode (existing envs continue, no new allocations) and are eventually retired entirely.

### Country localisation

BC's country localisation determines the chart-of-accounts shape, tax behaviour, regulatory features, and a few thousand fields' worth of country-specific defaults. We currently provision the localisations Microsoft publishes — typically `au`, `us`, `gb`, `de`, plus the W1 ("worldwide") base.

Every environment is locked to its country at create time. Cross-country migration of a running env is not supported (BC's data shape differs).

### Artifact type

Two values: `Sandbox` and `OnPrem`. `Sandbox` is the common case — Microsoft's developer/sandbox container licence. `OnPrem` is for customers who specifically need the on-premises feature surface for testing on-premises behaviour.

Both are licensed for non-production use only — see [reference/limitations § Sandbox and testing use only](limitations.md#sandbox-and-testing-use-only).

## Regions where we provision

| Region | Status |
|---|---|
| `australiaeast` | Primary; home region for the platform's own infrastructure |
| `australiasoutheast` | Provisioning available |
| `westus2` | Provisioning available |
| `westeurope` | Limited — verify availability before relying on it |

Each region has its own:

- **Pool family** — the VMs hosting BC containers in that region
- **Image cache** — cached VM images for fast provisioning
- **Key Vault** — per-env BC admin passwords, pool SSH keys
- **Blob storage** — hibernation backup snapshots; data export ZIPs

Cross-region operations (env hibernated in `australiaeast`, resumed in `westus2`) are supported and take longer than same-region resume. See [architecture/hibernation](../architecture/hibernation.md) for the timings.

## Querying the live matrix

### From the CLI

```bash
# Versions in a region
bcdock artifacts list --region australiaeast

# Filter by country
bcdock artifacts list --region australiaeast --country au

# Only versions that provision fast (have a VM image)
bcdock artifacts list --region australiaeast --fast-only

# Include preview / insider builds
bcdock artifacts list --region australiaeast --include-preview

# Country codes available
bcdock artifacts countries

# Regions available
bcdock config regions
```

### What the response looks like

```json
{
  "region": "australiaeast",
  "versions": [
    {
      "versionFull": "27.5.40123.50000",
      "versionMajor": 27,
      "versionMinor": 5,
      "country": "au",
      "countryName": "Australia",
      "artifactType": "Sandbox",
      "isPreview": false,
      "category": "Current",
      "hasVmImage": true
    },
    ...
  ]
}
```

The `category` field distinguishes `Current` (recommended), `LTS` (long-term support), and `Insider`/`Preview` channels.

`hasVmImage: true` means provisioning takes ~7-15 min on a warm pool (longer on a cold pool). `hasVmImage: false` means a one-time image build (~78 min) on first request.

## Choosing a version × country × region

Two practical rules:

1. **Pick a `hasVmImage: true` combo if you can.** It's not just faster on first provision — every subsequent provision in that combo amortises against the same image. Building an image for a combo only one customer ever uses is wasted infrastructure.
2. **Match country to your customer.** AL extension behaviour differs by localisation (especially around chart of accounts, tax setup, and the standard reports). If you're testing for an Australian client, use `au`; for a German client, use `de`.

Region choice is mostly about latency to whoever's hitting the BC web client. AL compile and publish are CLI-driven and tolerate higher latency; web-client interactive use does not. Pick the region closest to wherever the env will be accessed from - AU users on `australiaeast` or `australiasoutheast`; US users on `westus2`; etc.

## Lifecycle

BC versions move through three platform-level states (separate from the env lifecycle states):

- **Active** — pools are kept warm, autoscaler provisions on demand
- **Draining** — existing envs continue, no new allocations on these pools, customers are notified to migrate
- **Retired** — no pools, no provisioning. Hibernated envs at this version need a cross-major-version resume to come back.

In practice: when Microsoft drops a BC major's support, we drain it within ~3 months.

## Read more

- [Architecture → images and pools](../architecture/images-and-pools.md) — why the matrix has the shape it has
- [`bcdock artifacts list`](../cli/reference/bcdock_artifacts_list.md) — full flag reference for the live query
- [Reference → limitations](limitations.md) — what BCDock won't do regardless of version
