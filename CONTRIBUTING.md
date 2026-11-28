# Contributing to BCDock documentation

## TL;DR

| You want to... | How to contribute |
|---|---|
| Report a typo, broken link, missing example, or factual error | **[Open an issue](https://github.com/bcdock/docs/issues/new)** |
| Suggest a larger structural change or a new page | **Open an issue describing the change + audience**, we'll discuss before drafting |
| Send a small text fix you've already written | **Open an issue, paste the patch in the body**, we'll apply it |
| Submit anything else (questions, suggestions, business asks) | Email **support@bcdock.io** |
| Report a security issue | See [`SECURITY.md`](SECURITY.md) - **do not** open a public issue or PR |

**Pull requests submitted to this repo will be auto-closed** by a workflow that posts the same redirect. This repository is published from an internal source on every change, so direct PRs would be overwritten on the next publish. The auto-close keeps the expectation clear.

## Why this model

Issues are the right surface for documentation feedback because:

- **Small fixes are faster to round-trip than to review**. A two-line typo PR takes a maintainer about the same effort to apply at the source as it does to review here; combining issue triage and the fix into one step is more efficient for both sides.
- **You don't need to clone, set up mkdocs, build, and test** to point out that something is wrong. Issues lower the contribution bar.
- **Larger changes deserve discussion before drafting**. Issues capture the context (which page, which audience, what's confusing today) before anyone writes a full page that may need rework.

## What lands quickly vs slowly

Fast (typically same-week):

- Typos, grammar, broken links
- Missing or wrong CLI flag references
- Factual errors in concepts pages
- Outdated screenshots or version numbers
- Missing examples in guides where you can show what you tried

Slower (typically weeks; bigger discussion):

- New top-level sections in the navigation
- Architecture or security pages (these are written close to the systems they describe; we welcome flags but rewrite carefully)
- Restructuring the information architecture
- Vendor-specific guides we haven't prioritised

## What we don't accept (yet)

- **External rewrites of architecture / security / data-handling pages**. These describe internal behaviour and are written by the team building the systems. We welcome **issues** flagging confusing or wrong content; we don't accept page-rewrites from outside.
- **Translations**. We're English-only at launch. When we add i18n we'll explicitly invite translation contributors.
- **Marketing copy or positioning changes**. Those belong on [bcdock.io](https://www.bcdock.io) (the marketing site), not the docs site.

## Acknowledgements

If your issue results in a docs change, you'll be tagged in the resulting commit message. If you'd rather not be, just say so in the issue.

---

For anything else, **support@bcdock.io** is always the right starting place.
