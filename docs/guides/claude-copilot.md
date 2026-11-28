---
title: Use BCDock from Claude or Copilot Studio
description: Connect Claude to BCDock by signing in with your BCDock account, or a Copilot Studio agent with an API key, then list versions, look up an environment's URL, and create, hibernate, resume or delete sandboxes from the chat.
---

# Use BCDock from Claude or Copilot Studio

Goal: ask your AI assistant for a Business Central sandbox, or for the URL of one you already have, without leaving the chat. BCDock serves a remote MCP (Model Context Protocol) server. Claude connects to it by signing in with your BCDock account; Copilot Studio connects with a BCDock API key.

## What the assistant can do

- **`list_versions`** (free, it only reads): the BC versions and countries you can create a sandbox on right away in one Azure region.
- **`list_environments`** (free, it only reads): your environments, each with its name, status, BC version, country, region, web client URL, and a link to its page in the BCDock portal, where you find its sign-in details. Deleted ones are left out.
- **`get_environment`** (free, it only reads): one environment's status, its URLs (web client, OData, dev endpoint), and a link to its page in the BCDock portal, where you find its sign-in details. By name or id.
- **`get_billing`** (free, it only reads): your plan and its rates, your trial hours while you are on the trial, and your active and stored hours with their estimated charges over the last 30 days. Invoices and payment details stay in the portal; the result links to its billing page.
- **`request_version`** (free): asks BCDock to build a BC version, country and type that `list_versions` does not offer yet. BCDock is told by email, and you get an email once you can create an environment on it. Needs permission to create environments.
- **`create_environment`** (starts a cost): creates a sandbox, usually running in about 15 minutes. Once it is running it bills at your plan's active rate.
- **`hibernate_environment`** (cuts the cost): hibernates a sandbox. Its data is kept, its URL stops answering, and it bills at the much lower stored rate.
- **`resume_environment`** (starts the cost again): resumes a hibernated sandbox with its data and URL as they were, usually running in about 4 minutes, or 10 to 15 when a new server has to start. Once it is running it bills at your plan's active rate.
- **`delete_environment`** (stops the cost): deletes a sandbox permanently, which stops its billing. It cannot be undone, and the tool tells the assistant to ask you to confirm first.

Rates are on the [pricing page](https://bcdock.io/pricing). If a resume needs a newer BC platform version, the assistant cannot confirm that for you: resume it from the portal or with `bcdock env resume`.

## Connect Claude: sign in with BCDock

In Claude, go to **Customize → Connectors**, select **Add**, then **Add custom connector**.

1. **Name**: `BCDock`.
2. **MCP server URL**: `https://api.bcdock.io/api/v1/mcp`. Select **Continue**.
3. Under **Authentication**, choose **Sign in now**. Claude tags it **Detected**, but the dialog can open with **No sign-in** selected, and a connector added that way does not connect. **OAuth client** then appears (under **Advanced** in some layouts): keep **Use Claude's published identity**, also tagged **Detected**. You do not need an API key.
4. Select **Add**, then **Connect**.
5. A BCDock page opens. Sign in with your email code if you are not signed in already, pick the company if you belong to more than one, check what Claude asks to do, and select **Allow**.

Claude is now connected as you, in that company. Turn the connector on in a chat.

What you allow:

- **See your environments, the BC versions you can create, and your plan and usage.**
- **Create, hibernate, resume and delete environments.** Creating or resuming one starts billing, and Claude is told to ask you before it deletes anything.

On a Team or Enterprise plan, an Owner adds the connector under **Organization settings → Connectors**, then each member selects **Connect** and signs in with their own BCDock account.

### Claude Code

Add the server, then sign in from Claude Code:

```
claude mcp add --transport http bcdock https://api.bcdock.io/api/v1/mcp
```

In Claude Code, run `/mcp`, select **bcdock**, and choose to authenticate. Your browser opens the same BCDock page. Because Claude Code signs in through your own computer, the page warns you: continue only if you started the sign-in yourself.

## Connect with an API key

Copilot Studio connects with an API key, and so can a Claude connector that sends **Request headers**.

### 1. Create an API key

In the portal, go to [Profile → API keys](https://app.bcdock.io/profile/api-keys) and select **New key**.

- For look-ups only, tick **Read environments**. With this key the assistant cannot change or create anything.
- To let the assistant create, hibernate, resume or delete, also tick **Create & delete environments**.

Copy the key (it starts with `bdk_`). The portal shows it once.

### 2. The connection settings

**Server URL**

```
https://api.bcdock.io/api/v1/mcp
```

**Header name**: `authorization`

**Header value**: `Bearer bdk_...` (the word `Bearer`, a space, then your key)

The header value must include `Bearer ` in front of the key. Other shapes are refused:

- `authorization: Bearer bdk_...` works.
- `authorization: bdk_...` (no `Bearer `) is refused with 401.
- `authentication: Bearer bdk_...` (wrong header name) is refused with 401.
- `x-api-key: bdk_...` is refused with 401.

### Claude with a key

Request headers is a beta that Anthropic has opened to some organizations, and suits a key your organization shares. In the **Add custom connector** dialog, choose **No sign-in** for Authentication and add `authorization` with the value `Bearer bdk_...` under **Request headers**. Signing in, above, works on every plan and connects each person as themselves.

### Copilot Studio (and Microsoft 365 Copilot)

Microsoft 365 Copilot reaches MCP servers through an agent you build in Copilot Studio, so the steps are in Copilot Studio.

1. Open your agent's **Tools** page, select **Add a tool**, then **New tool**, then **Model Context Protocol**.
2. Fill in **Server name** (`BCDock`), a **Server description** (for example "Creates and manages Business Central sandboxes"), and **Server URL** `https://api.bcdock.io/api/v1/mcp`.
3. For authentication, choose **API key**, type **Header**, and header name `authorization`.
4. Select **Create**, then **Create a new connection**. When it asks for the key, enter `Bearer bdk_...`.
5. Select **Add to agent**.

Microsoft's own steps are in [Connect your agent to an existing MCP server](https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent).

## Try it

Ask the assistant:

- "Which BC versions can I create in australiaeast?"
- "What is the URL of my BCDock environment `acme-test`?"
- If you allowed creating: "Create a BC sandbox called `demo-friday` on the latest AU version." Then ask for its URL after about 15 minutes.

## Troubleshooting

**Claude asks you to sign in again.** Your connection was revoked or has not been used for 30 days. Select **Connect** and sign in.

**A key connection cannot connect.** The key is not arriving in the shape above. Check the header name is `authorization` and the value starts with `Bearer `. In Claude, check that Authentication is **No sign-in**. You cannot edit a Claude connector's headers after you add it: remove it and add it again.

**"API key requires 'env:write' scope".** The connection is read-only. For a key, create one with **Create & delete environments** ticked and update the connector.

**"environment ... not found".** The name must match an environment in the company you connected (or the key belongs to).

## Revoke access

To cut the assistant off, go to [Profile → API keys](https://app.bcdock.io/profile/api-keys) in the portal and revoke its row. A Claude sign-in shows there as one row, for example **Claude (claude.ai, connected 2026-11-28)**. It stops working immediately, and Claude asks you to sign in again next time.
