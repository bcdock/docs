---
title: Prepare a client demo
description: Get a Business Central sandbox ready for a client demo from the portal - when to create it, how long it takes, what to share with the prospect, and what to do afterwards.
---

# Prepare a client demo

You have a client demo coming up and you want a clean Business Central sandbox on the right version and localisation, at its own web address. Everything here happens in the portal at [app.bcdock.io](https://app.bcdock.io). You don't need Azure, Docker or a terminal.

## The day before: create the environment

Create it the day before, not an hour before. A new environment takes about 15 minutes, and that leaves you time to set it up the way the demo needs.

1. On **My Environments**, click **Create Environment**.
2. Pick the **region** closest to where you will present from, the **country** your client works in (the BC localisation), and the **BC version**.
    - A version tagged **on request** is not ready to create yet. Request it and we email you when it is. For a demo this week, pick a version without the tag.
3. Give it a name you will recognise, for example `acme-demo`. Then click **Create**.

You can close the page while it builds. When the environment shows **Running**, open it and click **Open Business Central**. Sign in with the username shown on the environment's page, and press **Reveal** there for the password.

!!! tip "On the free trial"
    The trial includes one environment and 7 hours of running time. A demo day fits comfortably: build the environment, rehearse, and hibernate it in between.

## Set it up for the story you will tell

Set up anything specific to your client inside Business Central, the same way you would in any sandbox: the customers, items and flows your story uses, and your extensions.

Then do a full rehearsal on the environment itself. What you see in the rehearsal is what your client will see.

## Between the rehearsal and the demo: hibernate

When you finish rehearsing, open the environment's page and click **Hibernate**, then confirm. Hibernating:

- keeps everything you set up: data, extensions, users and settings;
- keeps the same web address;
- stops the running clock. A hibernated environment does not use active hours.

If you forget, we email you after an environment has had **no activity for 2 hours** while it is running. The email has links to hibernate or delete it. It does not hibernate anything by itself; that is your call.

## On the day: resume early

Click **Resume** on the environment's page at least 30 minutes before the demo, then confirm.

- A resume usually takes about **5 minutes**.
- If no server with room is running in your region, one has to start first, and the resume takes about **10 to 15 minutes**.

When it shows **Running** again, open Business Central once to check that everything is where you left it.

## What to share with your client, and what not to

- **To present it yourself**, share your screen. Nothing needs to leave your hands.
- **To let your client click around after the demo**, give them the environment's web address and a **Business Central user of their own**, created in Business Central under **Users**. See Microsoft's guide to [managing users in on-premises deployments](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-how-users-permissions#manage-users-and-licenses-in-on-premises-deployments). Give that user the permissions the client needs and no more.
- **Do not share the environment's own sign-in** (the username and password on its page). It is the key to the whole environment. Each reveal is recorded.
- **Do not load real client data.** BCDock environments are sandboxes: use data you made up or anonymised. See [limitations](../reference/limitations.md).

## After the demo

- **Same client, another meeting soon?** Hibernate the environment and resume it before the next meeting. It comes back exactly as you left it, at the same address.
- **Done with it?** On the environment's page click **Delete** and confirm. That removes the environment for good. Its stored backup is deleted 7 days later, and we cannot restore a deleted environment.

## Related

- [Portal quickstart](../quickstart/portal.md) - your first environment, step by step
- [Run a training session](training-session.md) - several environments for a class
- [Hibernation](../architecture/hibernation.md) - what is kept, and how long a resume takes
- [Pricing](https://bcdock.io/pricing) - running and hibernated rates per plan
