---
title: Data handling
description: What BCDock collects, where it lives, how long we keep it, and the deliberate scope decisions that shape the answer.
---

# Data handling

This page is the system-level view of "what does BCDock store about me, and where?" The two GDPR / APP self-service mechanics - [data export](data-export.md) and [account deletion](account-deletion.md) - describe the customer-facing surface; this page is the engineering view that grounds them.

## What we store

Three categories.

### Identity and account

- **User account** - internal identifier, email, display name, status, time zone, creation timestamp, OAuth subject if applicable
- **Company** - internal identifier, name, slug, country, region, owner reference, status, creation timestamp
- **Membership** - links users to companies with role
- **Session tokens** - for portal session continuity (httpOnly cookie pair); 7-day TTL

### Operational state

- **Environment records** - internal identifier, name, BC version, country, region, status, lifecycle timestamps. One record per environment ever created (deleted envs are marked deleted, not removed).
- **Environment state changes** - append-only log of every transition (`creating → running → hibernated → resuming → running → deleted` etc.) with timestamps. Source of truth for billing.
- **Environment usage records** - daily aggregations of state-change data: per-env per-day running seconds + hibernated seconds. Past days immutable; current day recalculated on demand.
- **Subscription and billing** - plan, effective dates, consumed seconds, invoices, payment-method references (Stripe customer ID, never card data).
- **API keys** - hashed key bytes, name, scopes, created/last-used/revoked timestamps.

### Operational telemetry

- **Provisioning logs** - stage-by-stage log lines for every provision / hibernate / resume / delete operation. Keyed by environment, not by user or company. Append-only.
- **Audit trail** - every meaningful API action (env create, plan change, key revocation, staff operation). Linked to the user who took the action.
- **Email log** - record of transactional emails sent (template name, sent timestamp, status). For deliverability investigation.
- **Hibernation backup blobs** - per-environment, gzipped container snapshot. Lives in regional Azure Storage with 7-day soft-delete.

### Sandbox content (yours, not ours)

The data **inside** a BC environment - companies, items, customers, AL extensions you've published - is yours. We host the container; we don't read into it. The container's database is backed up only as part of the hibernation snapshot; we don't extract structured rows from it.

## Where it lives

| Class | Storage | Region scope |
|---|---|---|
| Identity, account, billing | Managed relational database (Azure-hosted) | BCDock's primary region |
| Environment records, usage, audit | Same database instance | BCDock's primary region |
| Provisioning logs | Same database instance | BCDock's primary region |
| Hibernation backup blobs | Azure Storage (per-region) | The region the env was provisioned in |
| Per-env BC admin passwords | Azure Key Vault (per-region) | The env's region |
| Shared TLS certificate (for HTTPS on env URLs) | Azure Key Vault (core) | Global |

The platform database lives in BCDock's primary region. Cross-region replication is not enabled by default; data residency claims for platform metadata are best-effort for that reason. Customer-environment data (hibernation blobs, per-env Key Vault secrets) stays in the region the environment was provisioned in.

## How long we keep it

| What | Retention |
|---|---|
| User account / Company | While account active. After deletion: **30-day grace** then anonymise-in-place forever. |
| Hibernation backup blobs | While environment exists. After env delete: **7-day soft-delete** then unrecoverable. After account anonymisation: deleted at +30d. |
| Session tokens | 7 days from issue. Wiped at account anonymisation (+30d). |
| Email codes (OTP) | Short TTL (~10 min); single use; hashed at rest. |
| Provisioning logs | Indefinitely - operational telemetry, env-keyed, not personal data. |
| Audit trail | Indefinitely - linked to the acting user; anonymised when the user is anonymised. |
| Subscription / billing history | Indefinitely - financial record requirement. |
| Salted email hash after anonymisation | Indefinitely - used to suppress trial-abuse on re-registration. Salt in Key Vault, never rotates. |

The **legal basis** for retaining the salted hash post-anonymisation is GDPR Article 17(3)(e) and APP 11.2(c) - defending against trial-abuse via repeated signups is a legitimate-interest grounds for limited retention.

## What's deliberately excluded

Two things that look like they should be in scope but aren't.

### Provisioning logs excluded from data export

The logs are env-keyed, not user-keyed. They're operational telemetry - what stage failed, how long the artifact download took, when the container reached `running`. None of those fields contain personal data; including them in the data export would dilute the signal-to-noise (most of the volume) without giving you any information about *yourself*.

### Provisioning logs not deleted on account anonymisation

Same reason. The log lines reference an environment; the environment's owner gets anonymised at +30d, and the operational log still resolves to "an anonymised user" - useful for debugging cross-pool issues without exposing who once owned the env.

### Salted email hash retained after anonymisation

A SHA-256 hash of the lowercased email combined with a server-side salt, retained on the account after anonymisation. We use it to detect re-registration with the same email (auto-restore the account, optionally suppress a second free trial). Without it, "one free trial per human" is unenforceable.

The salt lives in Key Vault, never appears in the database, never appears in code or logs, and never rotates (rotating would invalidate every existing hash and lose the suppression check). If the salt leaks, an attacker with the database can rainbow-table common emails - same threat model as password hashes.

## Customer levers

Two self-service paths:

| Action | How |
|---|---|
| Get a copy of everything | [Data export](data-export.md) - portal or `bcdock me export --wait --out export.zip` |
| Cleanly leave | [Account deletion](account-deletion.md) - portal or `bcdock me delete --confirm <email>` |

Both actions are documented in detail under their respective pages.

## Related

- [Data export](data-export.md) - what's in the ZIP, how the SAS URL works
- [Account deletion](account-deletion.md) - 30-day grace, anonymise-in-place, restore-on-sign-in
- [Posture](posture.md) - the controls that protect the data described here
