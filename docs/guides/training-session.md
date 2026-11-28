---
title: Run a training session
description: Run a Business Central training session on BCDock from the portal - how many environments your plan allows, creating them ahead, hibernating between sessions, and resuming before class.
---

# Run a training session

You are running a Business Central course and want an environment for each trainee, or one shared environment for the class. You want them ready before people arrive and costing little between sessions. Everything here happens in the portal at [app.bcdock.io](https://app.bcdock.io), with no terminal.

## Check how many environments your plan allows

Each plan has a limit on how many environments your company can have at once. **Hibernated environments count toward that limit**, so a class that keeps its environments between sessions uses its places for the whole course.

| Plan | Environments at once |
|---|---|
| Free trial | 1 |
| Pay-as-you-go | 3 |
| Starter | 5 |
| Pro | 30 |
| Enterprise | Agreed with us |

The free trial includes one environment and 7 hours of running time. That is enough to try a lesson on your own, but a class needs a paid plan. Rates are on the [pricing page](https://bcdock.io/pricing). To choose a plan, open **Billing** in the portal. For more than 30 environments, email [support@bcdock.io](mailto:support@bcdock.io).

!!! tip "One environment per trainee, or one for the class?"
    One per trainee lets everyone post and break things without getting in each other's way. One shared environment, with a Business Central user for each trainee, uses one place and works when the exercises do not collide.

## A few days before: create the environments

1. On **My Environments**, click **Create Environment**.
2. Pick the **region** closest to the class, the **country** your trainees work in, and the **BC version** the course is written for. Give each environment a name you can match to a trainee, for example `course-anna`.
3. Click **Create**, and repeat for each environment you need.

Each new environment takes about **15 minutes**. You can start the next one without waiting for the one before.

## Set them up, then hibernate

Open each environment with **Open Business Central** and sign in with the username shown on the environment's page. Press **Reveal** there for the password. Then set it up for the course:

- the exercise data the course uses;
- a **Business Central user for each trainee**, created in Business Central under **Users**. See Microsoft's guide to [managing users in on-premises deployments](https://learn.microsoft.com/en-us/dynamics365/business-central/ui-how-users-permissions#manage-users-and-licenses-in-on-premises-deployments). Give trainees their own user, not the environment's own sign-in.

When an environment is ready, open its page and click **Hibernate**, then confirm. It keeps everything you set up and its web address, and it stops using active hours until you resume it.

## Before each session: resume

Resume the class's environments **at least 30 minutes before the session starts**: click **Resume** on each environment's page and confirm.

- A resume usually takes about **5 minutes**.
- If no server with room is running in your region, one has to start first, and the resume takes about **10 to 15 minutes**.

Check that each one shows **Running** and opens before the trainees arrive. Then send each trainee their environment's web address and their Business Central user.

## After each session: hibernate

Hibernate every environment when the session ends. Trainees' work is kept exactly as they left it, at the same address, for the next session.

If one is left running, we email you after it has had **no activity for 2 hours**, with links to hibernate or delete it. It does not hibernate anything by itself, so make hibernating part of closing the session.

## When the course is over

Delete the environments you no longer need: on each environment's page click **Delete** and confirm. That frees their places for the next course. A deleted environment's stored backup is removed 7 days later, and we cannot restore a deleted environment.

!!! note "Sandbox only"
    Use course data or made-up data, never a real client's. See [limitations](../reference/limitations.md).

## Related

- [Portal quickstart](../quickstart/portal.md) - your first environment, step by step
- [Prepare a client demo](client-demo.md) - one environment for one meeting
- [Hibernation](../architecture/hibernation.md) - what is kept, and how long a resume takes
- [Pricing](https://bcdock.io/pricing) - running and hibernated rates per plan
