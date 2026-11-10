# BCDock Docs

Source for **[docs.bcdock.io](https://docs.bcdock.io)** - the documentation for [BCDock](https://www.bcdock.io), the managed platform for Microsoft Dynamics 365 Business Central environments on Azure.

Built with Mkdocs Material, served via GitHub Pages.

---

## Read the docs

The published site is at **[docs.bcdock.io](https://docs.bcdock.io)**:

- **Quickstart** - install the `bcdock` CLI, create your first environment, build an AL extension.
- **CLI** - reference for every `bcdock` verb.
- **Guides** - AL extension dev loop, GitHub Actions, Claude Code integration, data export, account deletion.
- **Reference** - BC version coverage, current limitations.
- **Security** - posture, data handling, disclosure process.
- **Architecture** - how BCDock works internally (environments, pools, hibernation, images).

GitHub also renders these pages directly under [`docs/`](docs/) in this repo if you'd rather read them at the source.

## Build the site locally

```bash
make setup    # one-time bootstrap (creates .venv via uv)
make serve    # live-reload at http://localhost:8000
make build    # mkdocs build --strict (the same gate CI uses)
```

`--strict` turns broken links and missing nav entries into errors.

Prerequisite: [`uv`](https://github.com/astral-sh/uv). If `uv` isn't on PATH:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version:
- Typos, broken links, factual errors, missing examples -> **[open an issue](https://github.com/bcdock/docs/issues/new)**.
- Anything bigger -> open an issue describing the change.
- Security issues -> [SECURITY.md](SECURITY.md), not a public issue.

PRs submitted here are auto-closed; they would be overwritten on the next sync. The auto-close is structural, not personal.

## Licence

MIT. See [LICENSE](LICENSE).

## Related repositories

- **`bcdock` CLI source**: [`bcdock/cli`](https://github.com/bcdock/cli)
- **BCDock product**: [bcdock.io](https://www.bcdock.io)
