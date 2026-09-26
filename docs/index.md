---
title: BCDock docs — Business Central sandbox CLI, API, and integration reference
description: Reference and guides for the BCDock CLI, API, and integration patterns. Spin up a Business Central environment in minutes from the portal, the terminal, or an AI agent.
---

# BCDock Docs

BCDock is a managed Business Central sandbox platform. Two equally first-class ways in:

- **Portal** — point-and-click for consultants, trainers, and sales engineers. Sign up, pick a BC version + region, click create.
- **CLI** — `bcdock` for developers, CI pipelines, and AI agents. The same Platform API the portal uses.

This site is the **developer / agent / ops reference**. For pricing and signup go to [bcdock.io](https://bcdock.io); for the running app go to [app.bcdock.io](https://app.bcdock.io).

## Where to start

<div class="grid cards" markdown>

-   :material-monitor-dashboard: __Use the portal__

    ---

    Sign in, pick a BC version, click create. No CLI required.

    [→ Portal quickstart](quickstart/portal.md){ .md-button }

-   :material-console: __Use the CLI__

    ---

    `curl ... | sh`, then `bcdock auth login`, then `bcdock env create --wait`.

    [→ CLI quickstart](quickstart/cli.md){ .md-button .md-button--primary }

-   :material-robot: __Integrate an agent__

    ---

    Set `BCDOCK_TOKEN`, point Claude / Copilot at the CLI, ship a working AL extension end-to-end.

    [→ Agent quickstart](quickstart/agent.md){ .md-button }

</div>

## Common scenarios

Pick the closest match to what you're trying to do:

<div class="grid cards" markdown>

-   :material-presentation: __Spin up a demo for a client__

    ---

    Click create in the portal, get an HTTPS URL in ~7-15 minutes, hand the link to the prospect.

    [→ Portal quickstart](quickstart/portal.md)

-   :material-code-tags: __Develop and ship an AL extension__

    ---

    Four CLI verbs: pull symbols, compile, publish, generate `launch.json`. Works from any terminal, no VS Code required.

    [→ AL extension loop](guides/al-extension-loop.md)

-   :material-school: __Run a training cohort__

    ---

    Provision N student envs ahead of class; hibernate between sessions so the cost only counts hours actually used.

    [→ Hibernation](architecture/hibernation.md) · [→ CLI quickstart](quickstart/cli.md)

-   :material-source-branch: __PR-per-branch environments in CI__

    ---

    GitHub Actions creates a fresh env per pull request, runs tests against it, hibernates between pushes, deletes on close.

    [→ GitHub Actions guide](guides/github-actions.md)

-   :material-robot: __Drive BCDock from Claude / Copilot__

    ---

    Set `BCDOCK_TOKEN`, point your agent at the `bcdock` CLI. Provision, compile, publish, verify, hibernate - all from natural-language prompts.

    [→ Agent quickstart](quickstart/agent.md) · [→ Claude Code patterns](guides/claude-code.md)

-   :material-compare-horizontal: __Test across BC versions__

    ---

    Spin up envs at multiple versions in parallel, compile and publish to each, diff the results. Cheap to leave hibernated between rounds.

    [→ BC versions](reference/bc-versions.md) · [→ Claude Code parallel pattern](guides/claude-code.md)

</div>

## CLI reference

- [**CLI install**](cli/install.md) — install paths for macOS, Linux, Windows
- [**CLI authentication**](cli/auth.md) — API keys vs JWT, when to use each
- [**CLI concepts**](cli/concepts.md) — pool vs environment, hibernation, billing model
- [**CLI exit codes**](cli/exit-codes.md) — what each code means, what your script should do
- [**Command reference**](cli/reference/bcdock.md) — every verb, auto-generated from the binary

## What BCDock is — and isn't

BCDock manages **environments** (BC Docker containers) running on **pools** (Azure VMs we operate). One pool hosts 2–9 environments. We never stop pools; we hibernate environments to blob storage when you don't need them, and resume on demand.

It is **not** Business Central SaaS. It is a sandbox infrastructure for development, testing, training, demos, and CI — explicitly *not* for production data. Honest comparison: [reference/limitations](reference/limitations.md).

## Audience

If you're a:

- **BC consultant, trainer, or sales engineer** — start with the [Portal quickstart](quickstart/portal.md). For evaluation and pricing, see [bcdock.io](https://bcdock.io).
- **Developer or DevOps engineer** — start with the [CLI quickstart](quickstart/cli.md). Every portal action has a CLI verb against the same Platform API.
- **Integrating an AI agent that runs BC code** — start with the [Agent quickstart](quickstart/agent.md). Set `BCDOCK_TOKEN` from `app.bcdock.io/profile/api-keys` and point Claude or Copilot at `bcdock`.
