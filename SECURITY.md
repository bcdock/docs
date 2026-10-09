# Security policy

## Reporting a vulnerability or sensitive content in these docs

Email **security@bcdock.io** if you find any of the following on `docs.bcdock.io` or in this repository:

- Credentials, tokens, or API keys accidentally published in a page or commit.
- Internal Azure resource names, customer data, or other internal references that should not be public.
- Mistakes in the security or data-handling pages that could mislead a reader about BCDock's actual posture.

Please do **not** open a public GitHub issue for any of these. Discovering them here is a real find; we'd rather hear from you privately.

Include in your email:

- A link to the page or commit.
- A description of what should not be there and why.
- (If applicable) what an attacker or compliance auditor could do with the information.

We acknowledge reports within **5 business days** during the beta phase. Sensitive content gets removed from `main` and force-pushed within hours of confirmation.

## Security issues in BCDock itself (not the docs)

If your report is about the BCDock product (the `bcdock` CLI, the platform, the portal), see the policy in the CLI repo at [`bcdock/cli/SECURITY.md`](https://github.com/bcdock/cli/blob/main/SECURITY.md). Same email address; we want to keep product-security and docs-content reports together in the same triage queue.

## Out of scope

- Typos, broken links, factual errors that don't have a security implication -> please use [GitHub issues](https://github.com/bcdock/docs/issues) as per [CONTRIBUTING.md](CONTRIBUTING.md).
- Bug reports about `mkdocs.yml` or the build pipeline that don't expose anything sensitive -> also issues.
