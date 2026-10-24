---
title: Data export - download everything BCDock holds about your account
description: Self-service GDPR Art. 15 / APP 12 data export. Request from portal or CLI; receive a ZIP of CSVs covering your environments, usage, audit log, and billing history.
schema_type: HowTo
---

# Data export

Goal: in two clicks (portal) or one CLI verb, request a complete export of your BCDock data. We hand you a ZIP of CSVs covering everything tied to your user and company. You own the data; this is the receipt.

This implements GDPR Article 15 (right of access) and Australian Privacy Principle 12. The export shape and SAS lifetime below are the canonical specification.

## What's in the ZIP

| File | Contents |
|---|---|
| `user.csv` | Your User row - id, email, display name, role, time zone, status |
| `company.csv` | Companies you're a member of - id, name, country, region, billing references |
| `environments.csv` | Every environment you've created - id, name, version, country, region, status, lifecycle timestamps |
| `environment_state_changes.csv` | State transitions per env (`running` ↔ `hibernated` ↔ `suspended` ↔ `deleted`) with timestamps |
| `environment_usage_records.csv` | Daily aggregated runtime per env (running seconds + hibernated seconds) |
| `subscription_history.csv` | Subscription tier changes with effective dates |
| `audit_log.csv` | Audit-relevant actions you took (env create/delete, plan changes, key revocations) |
| `api_keys.csv` | API keys you've minted - name, scopes, created/last-used/revoked timestamps. **Never** the key bytes themselves. |
| `email_log.csv` | Transactional emails we've sent you (template name, sent timestamp, status) |

**Not included**: provisioning telemetry is operational data tied to env IDs, not personal data - explicitly excluded.

## Request from the portal

1. Sign in at [app.bcdock.io/profile](https://app.bcdock.io/profile).
2. Find the **Data export** card.
3. Click **Request export**.
4. The card shows status while the export builds (typically 30-90 seconds for a typical company; longer if you have hundreds of environments).
5. When ready, the card shows a download link valid for **24 hours**. We also email the link to your account email.
6. Click **Download** - a signed Azure SAS URL streams the ZIP.

Re-clicking **Request export** while one is in flight returns the same in-progress request - no duplicate work.

## Request from the CLI

```bash
# Fire and forget - returns the request id, sends email when ready
bcdock me export

# Block until ready, then download to a local file
bcdock me export --wait --out account-export.zip
```

`bcdock me export` calls `POST /api/v1/me/export` and prints the request status (idempotent - the same request id comes back if one is already running).

`--wait` polls until the export flips to `ready` (default timeout 5 min, exit 124 on timeout).

`--out FILE` downloads the ZIP to the given path once `--wait` succeeds. Without `--out`, the CLI prints the SAS URL - pipe to `curl -o` if you'd rather drive the download yourself.

## Verify what's in the ZIP

```bash
unzip -l account-export.zip
# Lists all CSVs with their sizes

unzip -p account-export.zip environments.csv | head
# Spot-check a single file
```

CSVs are UTF-8 with a header row and ISO 8601 UTC timestamps.

## Privacy and retention

- **The download link expires after 24 hours.** Re-request if you need it again - there's no rate limit on requests, only on the SAS lifetime.
- **The blob is deleted from our storage when the SAS expires.** We don't keep an archive of past exports.
- **Cross-company isolation is enforced server-side.** If you're a member of company A you can only export company A's data, even if you used to be in company B (your account record leaves; the company's data stays with company B's owner).
- **Sole owners** see all their company's data. **Co-members** see their personal user data plus the company-shared data they have access to under normal app permissions.

## What this isn't

- **Not a backup tool.** The ZIP is a snapshot of metadata, not a way to migrate environments. To export a BC database, use the env's BC interface (Database Export) or the standard BC `.bak` flow. Hibernation backups are owned by the platform; talk to us if you need raw access to one.
- **Not the place to download AL extensions you've published.** Those are committed source in your own repo; we don't store them server-side after the install.

## Related

- [Account deletion](account-deletion.md) - if you want to leave entirely
- [`bcdock me show`](../cli/reference/bcdock_me_show.md) - current status + deletion schedule
- [Privacy policy](https://bcdock.io/legal/privacy-policy) - the full retention and processing notice
