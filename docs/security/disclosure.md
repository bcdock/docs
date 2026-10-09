---
title: Coordinated disclosure
description: How to report a security issue in BCDock. Contact, scope, and what we commit to.
---

# Coordinated disclosure

If you've found a security issue in BCDock, thank you - please tell us before telling anyone else.

## Contact

Email: **security@bcdock.io**

Please include:

- A clear description of the issue
- Steps to reproduce (commands, requests, account context if applicable)
- The impact you observed or suspect
- Any patches, mitigations, or hardening you'd recommend

If the issue is sensitive enough that you'd rather not put it in plain email, ask us first and we'll arrange an encrypted channel.

## What we commit to

- **Acknowledge within two business days.** A real human reads everything that lands in `security@`.
- **Investigate and fix within a reasonable window** - proportional to severity. Critical issues (auth bypass, cross-tenant data access, secret exposure) are dropped-everything-else. Lower-severity issues are timelined and we'll keep you informed.
- **Credit you publicly** if you'd like, at the time of fix or disclosure. If you'd rather stay anonymous, that's also fine.
- **No legal threats for good-faith research.** If your testing follows the scope below, we will not pursue legal action and will treat you as a friend of the platform.

## Scope

### In scope

- The BCDock Platform API at `api.bcdock.io`
- The customer portal at `app.bcdock.io`
- The marketing site at `bcdock.io`
- The docs site at `docs.bcdock.io`
- The `bcdock` CLI binary
- Per-environment BC URLs (subdomains under `bcdock.io`) if the issue affects the platform's isolation guarantees rather than BC itself
- Pool and infrastructure provisioning if the issue exposes other customers' data or infrastructure

### Out of scope

- **Bugs in Microsoft Dynamics 365 Business Central itself.** We host BC; we don't develop it. Report BC bugs to Microsoft. We're happy to help triage if you're not sure where the issue lives.
- **Bugs in third-party dependencies** that don't affect BCDock specifically (e.g. a CVE on a version we don't run).
- **Attacks on your own BC environment** - once you're logged into BC and acting as Administrator, what happens inside that container is your business. The platform's isolation guarantees apply at the boundary; the inside is BC's responsibility.
- **Denial-of-service through resource exhaustion** at scale (running 1000 concurrent env creates, etc.) - that's a billing concern, not a security one. The platform throttles via API rate limits and background-job queue depth.
- **Issues with no security impact** - UX bugs, broken links, typos, etc. - are welcome at hello@bcdock.io.

## What we ask of you

- **Don't access data that isn't yours.** If a vulnerability lets you see another customer's data, stop, document the proof, and tell us - please don't browse around.
- **Don't disrupt the service.** Test against your own account, your own environments, your own data.
- **Give us reasonable time to fix.** We commit to keeping you informed; please don't disclose publicly before we've had a chance to ship a fix or coordinate a disclosure window. We'll work with you on timing.
- **Don't social-engineer our staff or customers.** That's out of scope on both sides.

## Severity guidance

We use a simple internal rubric to triage:

| Severity | Examples | Target time-to-fix |
|---|---|---|
| **Critical** | Cross-tenant data access; auth bypass; secret leak; remote code execution on a pool VM | Hours-to-days |
| **High** | Privilege escalation (e.g. `env:read` token getting `env:write` results); persistent XSS in portal | Days-to-1 week |
| **Medium** | Reflected XSS; CSRF on a non-destructive endpoint; information disclosure that doesn't include PII | 1-4 weeks |
| **Low** | Verbose error messages; missing security headers; cosmetic CSP issues | Next-feature-bundle |

These are guidance, not a contract - we make case-by-case calls and tell you what we're doing.

## What we won't do

- Pay a bounty automatically. We're a small team pre-revenue. As we grow we'll set up a formal program; today, the offer is acknowledgement, public credit (if you want it), and our active gratitude.
- Respond to vulnerability "scan reports" from automated tools that lack proof of impact - too many false positives.
- Litigate good-faith research within the scope above.

## Related

- [Posture](posture.md) - what BCDock does for security at the architecture level
- [Data handling](data-handling.md) - what we store, where, for how long
- [Account deletion](account-deletion.md) / [Data export](data-export.md) - GDPR self-service mechanics
