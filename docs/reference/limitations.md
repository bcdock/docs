---
title: Limitations - what BCDock can and cannot do
description: Detailed feature-by-feature comparison with Microsoft BC SaaS. Licensing, provisioning, free-trial caps, compliance scope.
---

# Limitations

BCDock runs real Business Central containers - the same images Microsoft publishes - but there are important restrictions you should understand before using the platform.

This page is the consolidated reference: the actual constraints, what they mean in practice, and what's coming. The buyer-facing summary on the marketing site links here.

## Sandbox and testing use only

BCDock environments use Microsoft's **developer/sandbox licences**. These are legally restricted to non-production purposes. You **must not** use BCDock for live business operations, financial transactions, or any workload that requires a production Microsoft Dynamics 365 Business Central licence.

See: [Microsoft Business Central Container EULA](https://go.microsoft.com/fwlink/?linkid=861843).

| ✓ Allowed | ✗ Not allowed |
|---|---|
| AL extension development & testing | Production workloads or live operations |
| Staff training and onboarding | Processing live customer or financial data |
| Demos and proof-of-concept evaluations | Replacing a Microsoft BC SaaS subscription |
| Integration and regression testing | Revenue-generating business operations |
| Migration testing before production cutover | |
| Version compatibility checks | |

If your use case isn't on the allowed list, talk to us first - there are edge cases we're happy to discuss (internal-only training, public-facing demos with synthetic data, etc.) but they need explicit confirmation.

## Provisioning time

Environments are not instant. Time depends on whether pre-built resources already exist for your chosen BC version × country combination.

| Scenario | Typical time |
|---|---|
| Pre-built version, warm pool | ~7-15 minutes |
| Pre-built version, cold pool | longer (pool create plus env create) |
| Not pre-built - first time for this version × country combo (built on request) | ~78 minutes (one-time) |

The longer wait only happens once per version × country combination. All subsequent environments on that combo provision in the warm-pool window above.

## Free trial caps

Free trial accounts have **two independent caps**:

| Cap | Limit | What happens at the cap |
|---|---|---|
| **Active runtime** | 7 hours total across all environments | Running envs auto-suspend; resume requires a paid plan |
| **Stored time** | 100 hours (~4.2 days) total across all environments | Per-env auto-suspend after grace period |
| **Wall-clock expiry** | 14 days from signup | Trial ends, all envs suspend; upgrade to keep them |

Trial counters live on the company, not the user. Trial is one per human - if you delete your account and re-sign up with the same email, you don't get a fresh trial (the trial-history flag set at anonymisation time blocks both buckets).

Active runtime is metered per-second across all environments simultaneously. Stored time is metered per-environment-day. Hibernating cuts active billing instantly; the env continues to consume the stored bucket until you delete it.

## Differences from Microsoft BC SaaS

BCDock is a developer tool, not a SaaS ERP. Feature-by-feature:

| Feature | BCDock | BC SaaS |
|---|---|---|
| Production licence | ✗ Sandbox only | ✓ Full commercial |
| AL extension dev | ✓ Full support | ✓ Full support |
| Web services / OData | ✓ Full support | ✓ Full support |
| Multi-company | ✓ Full support | ✓ Full support |
| Power Platform | ✗ Not available | ✓ Native integration |
| Azure AD SSO | Manual configuration | ✓ Built-in |
| AppSource extensions | Manual install | ✓ One-click |
| Automatic BC updates | ✗ User-managed | ✓ Microsoft-managed |
| Uptime SLA | Best effort | ✓ 99.9% guaranteed |
| Compliance certs | Azure-level only | ✓ SOC 2, ISO 27001 |
| Microsoft support | ✗ BCDock support only | ✓ Included |

## Hibernation and resume

| Operation | Typical time | Notes |
|---|---|---|
| Hibernate | ~1-3 minutes | Container gzipped to blob storage; pool slot freed |
| Resume (same BC major version) | ~7-15 minutes | Container restored on any compatible pool |
| Resume across major BC versions | ~10-25 minutes | Adds the BC platform upgrade; CLI/portal will prompt for confirmation |

Cross-major-version *backwards* resume is not supported (e.g. you can't take a v28-hibernated env and resume it onto a v27 pool). Forwards is the documented escape hatch.

## Regional availability

Currently provisioning in:

- `australiaeast` / `australiasoutheast`
- `westus2`
- `westeurope` (limited; check with us before relying on it)

Each region has its own pool family, image cache, and Key Vault. Cross-region env moves are staff-driven today (not user-initiated yet); reach out via support@bcdock.io if you need an environment moved between regions.

## Pool sharing

Pools host 2-9 environments each. Environments on the same pool share:

- The pool VM's compute (CPU, memory) - sized so that typical concurrent usage doesn't contend
- The pool's reverse proxy
- The pool's network egress

They do **not** share:

- BC databases (each env has its own)
- File system (each env is a separate Docker container)
- Credentials (each env has unique admin password)

A pool can host environments belonging to **different companies**. Tenant isolation is enforced at the API layer (every query carries a company-scoped filter) and inside the BC containers themselves - one company's container can't reach another's. Full posture detail in [security/posture](../security/posture.md).

## Compliance scope

- **Azure-level compliance** (SOC 2, ISO 27001) inherits from Azure. We run on Azure.
- **BCDock-level compliance** is currently best-effort. We don't claim SOC 2 or ISO 27001 *for the BCDock platform itself* - that's a Phase D milestone that needs ≥1 paying enterprise to justify the audit cost.
- **Data residency**: pick a region; your data stays in that region's pool, blob storage, and Key Vault. We don't replicate cross-region without explicit configuration.
- **Sandbox containers are not in scope** for HIPAA, PCI, or similar regulated-data regimes. Use synthetic or anonymised data.

Detailed posture: [security/posture](../security/posture.md).

## What's not on the roadmap

- **Power Platform integration** - would require BC SaaS, not sandbox containers. Not happening.
- **Production hosting** - explicitly licence-prohibited. Not happening.
- **Automatic BC version updates inside an environment** - design choice. Each env is pinned to its BC version; resume across versions is the upgrade path. This keeps the version lifecycle predictable for testing.
- **AppSource auto-install** - Microsoft's marketplace doesn't expose programmatic install for sandbox containers. Manual install via `bcdock env publish` is the path.

## Questions

Anything unclear, or a use case you're not sure fits? Email [hello@bcdock.io](mailto:hello@bcdock.io).
