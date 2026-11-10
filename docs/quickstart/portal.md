---
title: Portal quickstart - your first BC environment in five clicks
description: Sign up, create an environment, get a URL. No CLI required. The portal entry path to BCDock for consultants, trainers, and sales engineers.
---

# Portal quickstart

Goal: a Business Central sandbox for tomorrow's client demo, or for checking how standard BC behaves on a particular version. You do it all in the browser, usually in about 15 minutes, with no CLI and no Azure subscription of your own.

## 1. Get access

BCDock is currently in early access. Two steps:

1. **Join the waitlist** at [bcdock.io/waitlist](https://bcdock.io/waitlist) - email, name, and the BC config you'd like to start with. We review within 48 hours.
2. **Activate with your invite code** at [bcdock.io/signup](https://bcdock.io/signup) once the email arrives. You can set your time zone under **Profile → Preferences** and your company's default region under **Profile → Company Settings** at any time.

After activation, sign in at [app.bcdock.io](https://app.bcdock.io) with the one-time code we email you. You start with no environments.

## 2. New environment

Open **Environments** and click **Create Environment**.

The form asks for three things:

- **Region** - where the environment runs. It starts on your company's default region; pick another per environment if you need one closer to your client.
- **Country** - the BC localisation.
- **BC version** - most recent versions are pre-built in your region and carry no tag - a new environment on one takes about 15 minutes. Versions that aren't pre-built are tagged **on request**: request one, we build its image and email you when you can create environments on it, and from then on it is just as fast. Requests are open from BC 27 onward. For an older version, email support@bcdock.io.

For your first environment, the region, country and version you gave when you joined the waitlist are filled in for you, where they are still offered.

Optional:

- **Name** - a label you will recognise, for example `acme-demo`. It becomes part of the environment's address.
- **Advanced** - the image type and tenancy. Leave them as they are unless you have a specific reason to change them.

Click **Create**. The environment shows **Preparing** straight away.

## 3. Wait for it to be ready

The environment moves through **Preparing**, **Creating**, **Setting up environment** and **Starting** to **Running**. A new environment reaches **Running** in about 15 minutes, sooner when a server with room is already running.

You can close the page; it carries on. When your first environment is ready, we email you a link to it.

## 4. Open your environment

When it shows **Running**, open the environment's page. Under **Connect**:

- **Open Business Central** opens the BC web client in a new tab.
- **Username** is shown on the page. Press **Reveal** for the password. Nothing secret is on screen until you ask for it, and each reveal is recorded.
- **For developers** holds the web client URL, the dev endpoint, and the SOAP and OData addresses, for AL publishing and API integrations (see the [Agent quickstart](agent.md)).

## 5. Hibernate when done

When you're not actively using the environment, click **Hibernate** on its page and confirm. It is saved to storage, its address stops responding, and billing drops to the much-lower stored rate. Your data, extensions, users, and configuration all survive - resume any time and they're back exactly as you left them.

Current pricing lives on the [pricing page](https://bcdock.io/pricing); the shape is the same on every tier - per-second active rate while the env is running, much-cheaper per-second stored rate while it's hibernated.

To resume: click **Resume** on the environment's page and confirm. A resume usually takes about 4 minutes. If no server with room is running in your region, one has to start first, and the resume takes about 10 to 15 minutes. It restores the environment's database at the same URL. If its BC version has been retired, the UI asks you to confirm the newer platform version first, and that resume takes longer.

To delete entirely: **Delete** removes the environment for good, and its stored backup is deleted 7 days later. We don't restore deleted environments.

## What's next

- [Prepare a client demo](../guides/client-demo.md) - create the day before, hibernate, resume before the meeting, what to share.
- [Run a training session](../guides/training-session.md) - environments per plan, hibernating between sessions, resuming before class.
- [CLI quickstart](cli.md) - the same five steps from a terminal. Useful once you find yourself doing this often.
- [Agent quickstart](agent.md) - point Claude / Copilot / your favourite agent framework at `bcdock`. The agent reaches BCDock through the CLI on your behalf.
- [Concepts](../cli/concepts.md) - pool vs environment, hibernation economics, why the model is shaped this way.
- [Limitations](../reference/limitations.md) - what BCDock is and isn't. Read before using on real client work.

## Troubleshooting

**Not Running after 30 minutes** - that is longer than a normal create, even when a new server has to start. The environment's page shows the stage it is in. If it hasn't moved, email support@bcdock.io with the environment's name.

**Web client sign-in fails** - check you are using the username shown on the environment's page, not `Administrator`. If the environment was recreated its password changed: press **Reveal** for the current one.

**"Sandbox use only" warning** - yes, BCDock environments are not for production data. Use synthetic or anonymised data. See [limitations](../reference/limitations.md).
