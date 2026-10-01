---
title: Portal quickstart — your first BC environment in five clicks
description: Sign up, create an environment, get a URL. No CLI required. The portal entry path to BCDock for consultants, trainers, and sales engineers.
---

# Portal quickstart

Goal: from "I just signed up" to "I have a Business Central URL I can use." No CLI, no Azure, no Terraform.

## 1. Get access

BCDock is currently in early access. Two steps:

1. **Join the waitlist** at [bcdock.io/waitlist](https://bcdock.io/waitlist) - email, name, and the BC config you'd like to start with. We review within 48 hours.
2. **Activate with your invite code** at [bcdock.io/signup](https://bcdock.io/signup) once the email arrives. The signup wizard captures your time zone and default Azure region - both can change later under **Profile → Settings**.

After activation, sign in with the one-time code we email you and you land on the dashboard with no environments yet.

## 2. New environment

Click **New environment** at the top of the dashboard.

The form has three required choices:

- **Name** — DNS-safe, 3–40 chars (e.g. `acme-test`, `pr-42`, `training-cohort-q2`). Becomes part of the URL.
- **BC version** - pick from the cascading dropdown. Most recent versions are pre-built in your region and carry no tag - they provision in ~7-15 minutes on a warm pool. Versions that aren't pre-built are tagged **on request**: the first env on that version and country combination takes longer while the image is built (you're emailed when it's ready), then everything after is on the fast lane.
- **Country** — the BC localisation. Defaults to your company's home country.

Optional:

- **Region** — defaults to your company default; override per env if you need a US/EU/AU split.
- **Multi-tenant** — leave on unless you have a specific reason to use single-tenant.

Click **Create**. The environment lands in the `creating` state immediately.

## 3. Wait for provisioning

The environment card shows live progress: VM provision → Docker setup → BC artifact download → container start. Most envs reach `running` in ~7-15 minutes on a warm pool; the very first env on a new version × country combo takes substantially longer (one-time image build per combination).

You can leave the page — refreshing comes back to the same state. We don't email you when it's done; the dashboard just goes green.

## 4. Open your environment

When the card flips to `running`:

- **Web Client URL** — the BC interface. Sign in as `Administrator`; press **Reveal** on the environment's page for the password. Nothing secret is on screen until you ask for it, and each reveal is recorded in your audit trail.
- **OData endpoint** — for API integrations.
- **Dev endpoint** — for AL extension publishing (CLI users — see [Agent quickstart](agent.md)).

## 5. Hibernate when done

When you're not actively using the env, click **Hibernate**. The container is gzipped to blob storage; the URL stops responding; billing drops to the much-lower stored rate. Your data, extensions, users, and configuration all survive - resume any time and they're back exactly as you left them.

Current pricing lives on the [pricing page](https://bcdock.io/pricing); the shape is the same on every tier - per-second active rate while the env is running, much-cheaper per-second stored rate while it's hibernated.

To resume: click **Resume** on the env card. ~7-15 minutes back to `running` (longer if the platform decides you need a cross-version upgrade - the UI will prompt for confirmation).

To delete entirely: **Delete** removes the env and the stored backup after a 7-day operator-recovery grace window.

## What's next

- [CLI quickstart](cli.md) — the same five steps from a terminal. Useful once you find yourself doing this often.
- [Agent quickstart](agent.md) — point Claude / Copilot / your favourite agent framework at `bcdock`. The agent reaches BCDock through the CLI on your behalf.
- [Concepts](../cli/concepts.md) — pool vs environment, hibernation economics, why the model is shaped this way.
- [Limitations](../reference/limitations.md) — what BCDock is and isn't. Read before using on real client work.

## Troubleshooting

**Stuck in `creating` past 30 minutes** — likely a first-time image build for an unseen version × country combo. Check the env card's logs view; it'll show the current stage. If it's been past 90 minutes, reach out at hello@bcdock.io.

**Web Client login fails** — the password may have rotated if the env was recreated. Press **Reveal** on the environment's page, or run `bcdock env credentials <name>`, for the current one.

**"Sandbox use only" warning** — yes, BCDock environments are not for production data. Use synthetic or anonymised data. See [limitations](../reference/limitations.md).
