---
title: Data export - security view
description: How the self-service data export is built. SAS URLs, retention, cross-company isolation, what's excluded and why.
---

# Data export - security view

The customer-facing walkthrough lives at [guides/data-export](../guides/data-export.md). This page is the security-level companion: how the export is generated, signed, retained, and isolated.

## Mechanics

1. **Customer calls** `POST /api/v1/me/export` (portal button, or `bcdock me export`). Idempotent - a second call while one is in flight returns the same request id.
2. **Platform enqueues a background job** which runs the export under a per-company database context (so company isolation scopes the export to your data automatically).
3. **The job gathers data** - reads per-table records into CSVs, packed into a ZIP.
4. **The job uploads** the ZIP via the Infrastructure API to Azure Storage. The Platform never speaks Azure SDK directly; the Infrastructure API holds the storage credentials.
5. **The job mints a SAS URL** with a 24-hour TTL, scoped to the single blob, read-only.
6. **The job emails the SAS URL** to your account email via the standard transactional email channel.
7. **You download** at any time within the 24-hour window. After expiry, the SAS becomes invalid and the underlying blob is deleted.

The end-to-end flow is bounded by the background-job retry policy - a job failure surfaces in the portal as a "failed" status; you can re-request without quota cost.

## What lands in the ZIP

The list lives in [guides/data-export](../guides/data-export.md#whats-in-the-zip). All CSVs are UTF-8 with a header row and ISO 8601 UTC timestamps.

## Cross-company isolation

The export job runs under your company context, with company isolation active. If you're a member of company A, you cannot trigger an export for company B's data, even if you used to be a member of company B (your account leaves; the company's data stays with company B's owner).

Sole owners see all their company's data. Co-members see their personal user data plus the company-shared data they have access to under normal app permissions - same RBAC as the running portal.

## SAS URL details

- **Permission**: `read` only
- **Resource**: a single blob (specifically the export ZIP) - not the container
- **Lifetime**: 24 hours from generation
- **Storage account**: per-region; all of one customer's exports go to one regional account
- **TLS**: required (HTTP-only access fails)

After the SAS expires, two things happen:

1. The SAS is no longer signed by the storage account's keys → 403 from Azure.
2. The job that created the SAS schedules the underlying blob for deletion at expiry time. We don't keep an archive.

If you re-request an export within the 24h window, the same SAS comes back. If the window has expired, a fresh export job builds a new ZIP under a new blob with a new SAS.

## What's excluded - provisioning telemetry

Provisioning logs (the stage-by-stage log lines for every provision / hibernate / resume operation) are **not in the ZIP**. They're operational telemetry keyed by environment ID, not personal data. Including them would dilute the export's signal-to-noise without giving you any information about yourself.

See [data-handling § What's deliberately excluded](data-handling.md#whats-deliberately-excluded).

## What's excluded - API key bytes

The `api_keys.csv` lists every API key you've ever minted (name, scopes, created/last-used/revoked timestamps) but **never** the key bytes themselves - only a hash of those bytes lives in our database. There is no way for the platform to surface the original key bytes once you've left the portal screen where the key was first shown.

If you need a fresh key, mint a new one in the portal (revoking the old one is a separate action).

## What's stored about exports themselves

We record one row per export request: identifiers, status, the blob it produced, request and completion timestamps, the SAS expiry, and any error message. That row is included in your *next* export (so "history of exports" is itself in the export - recursive but useful for audit purposes).

## Threat model

- **Eavesdropping in transit**: TLS is required for the SAS URL. The portal generates the link over HTTPS; the email channel uses TLS for transport (Resend → recipient MTA - best-effort beyond our control after the email is delivered).
- **SAS leak**: a leaked SAS URL is a 24-hour read-only credential to the export blob. The blast radius is limited to one customer's one export. Rotation strategy: request a fresh export, which generates a new blob with a new SAS; the old SAS expires on schedule.
- **Storage account compromise**: a compromise of the storage account's keys would expose all current export blobs. Mitigations: keys live in Key Vault (not in code or env vars); access via managed identity; per-region storage isolation limits blast radius to one region.

## Related

- [Guides → Data export](../guides/data-export.md) - customer-facing walkthrough
- [Data handling](data-handling.md) - what's stored, where, for how long
- [Account deletion](account-deletion.md) - companion GDPR Art. 17 surface
