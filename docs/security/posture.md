---
title: Security posture
description: Architecture-level security controls in BCDock - per-region Key Vaults, tenant isolation, HTTPS for environment URLs, immutable provisioning logs, httpOnly cookies. What's shipped today, what's not, and the boundary between the two.
---

# Security posture

This page is the answer to "what does BCDock do for security?" - designed for partner-questionnaire and enterprise-procurement audiences. It describes **what's shipped today**, not what's planned. Honest scope: BCDock is a sandbox platform; the controls described here are the ones we've built into the architecture, not certified by an external auditor.

For the formal compliance scope (what BC SaaS gives you that we don't), see [reference/limitations § Compliance scope](../reference/limitations.md#compliance-scope).

## Shipped controls

### Tenant isolation

Every database query in the Platform API carries a company-scoped filter set from the authenticated company context. The filter applies automatically at the data-access layer to every query - there is no per-query opt-out path within normal API code paths. Cross-company data access from a customer-scoped credential is therefore not possible.

Staff-level cross-tenant operations exist for support purposes but are not reachable from customer-facing API keys or the public CLI.

### Azure Key Vaults

Secrets live in Azure Key Vault, partitioned by scope:

- **Platform KV** (`bcdock-platform-kv-{env}`) - application-level credentials (JWT signing key, Stripe API keys, email token, Postgres password, etc.). Fetched at startup via the platform VM's system-assigned managed identity. api-tier containers carry zero long-lived Azure credentials.
- **Core KV** - secrets shared across all environments (wildcard TLS certificate). All pools fetch from here.
- **Regional KV** (one per region BCDock provisions in) - region-scoped secrets: per-environment BC admin passwords, pool SSH keys, etc.

Soft-delete is enabled on all KVs (90-day recovery window). RBAC is auto-assigned at provisioning time - each pool has just enough access to fetch the secrets it needs.

### Container-side admin passwords

Each BC environment has a unique `Administrator` account password, generated at provisioning time, stored in the regional Key Vault. The password is never logged, never written to file, and is fetched on demand by the platform when starting the container.

The admin password and the separate Web Service Access Key for OData/SOAP are **revealed on request, not returned on every read**. Press **Reveal** on the environment's page in the portal, or run `bcdock env credentials <name>`. A plain environment read - the portal page, `bcdock env get`, any script polling either - carries the username and no secret.

Every reveal writes an audit-trail entry, so you can see when an environment's credentials were last handed out and to whom. You can rotate the password through the BC interface; the platform doesn't auto-rotate.

### Authentication

**Portal (browser sessions)** - httpOnly cookies. Two cookies per signed-in user:

- `bcdock_token` - 15-minute access token
- `bcdock_refresh_token` - 7-day refresh token

Both are httpOnly + SameSite=Lax; the Secure flag is set in production so cookies only travel over HTTPS. JavaScript on the page cannot read them - they're attached to API calls server-side, not by client code.

Refresh tokens are single-use and rotated on every refresh: each use issues a new token and retires the one presented. If a retired token is ever presented again - the signature of a stolen or replayed session - BCDock treats it as a compromise and revokes the whole chain of tokens descended from it, forcing re-authentication rather than letting a copied token keep working alongside the real one.

**CLI / API / agents** - long-lived API keys (`bdk_…`) with explicit scopes. See [API keys](../reference/api-keys.md).

OTP exchange (the email-based login flow) is rate-limited at the API layer. Codes are short-lived single-use; the code itself is hashed in storage.

### Network surface

Every BCDock environment is reached over HTTPS at `https://<env-name>-<shortId>.bcdock.io/BC/`. TLS is platform-managed - customers don't provision or rotate certificates, and every new environment is on HTTPS from the moment it's created.

Pool-to-platform traffic uses authenticated, encrypted channels with credentials stored in the regional Key Vault and never logged. Customers don't interact with that surface directly.

### Immutable provisioning logs

Every stage of every provision / hibernate / resume / delete operation writes a structured log line into the platform-managed audit trail. Append-only - there is no API surface to edit or delete log lines. Used for support investigations and post-mortems.

Critically, the provisioning telemetry is **excluded** from the customer data export - it's operational telemetry tied to environment IDs, not personal data. See [data-handling](data-handling.md) for the scope decision.

### Storage soft-delete

Hibernation backup blobs (the snapshot of an environment's state when hibernated) live in per-region Azure Storage with soft-delete enabled (7-day recovery window). After deletion, the blob enters the soft-delete state and can be recovered for 7 days; after that it's hard-purged.

This protects against accidental deletion of an environment - operator can restore within the 7-day window. Beyond that, the data is not recoverable by anyone.

## What's *not* claimed

We are deliberate about the boundary between "in the architecture" (what this page describes) and "audited by a third party" (what enterprise procurement teams want). We don't claim:

- **SOC 2 / ISO 27001 for the BCDock platform.** Azure (the underlying cloud) carries these certifications; BCDock at the platform level is best-effort. Pursuing certification is a Phase D milestone tied to ≥1 enterprise contract that justifies the audit cost.
- **HIPAA / PCI scope for sandbox containers.** They're not in scope for regulated-data regimes. Use synthetic or anonymised data.
- **Penetration testing reports.** No formal pen-test on BCDock itself yet. Internal review and standard hardening (Key Vault, RBAC, company-scoped query isolation, parameterised queries) is what's shipped.

If you need any of these, talk to us - we can timeline them against your engagement.

## How to report a security issue

See [security/disclosure](disclosure.md) for the coordinated disclosure policy, contact email, and scope.

## Related

- [Data handling](data-handling.md) - what we collect, where it lives, retention
- [Data export](data-export.md) - GDPR Art. 15 / APP 12 mechanics
- [Account deletion](account-deletion.md) - GDPR Art. 17 / APP 11 mechanics
- [Architecture overview](../architecture/overview.md) - how the controls above fit into the broader system
- [Disclosure](disclosure.md) - coordinated disclosure policy
