---
title: Use BCDock from Claude or Copilot Studio
description: Connect Claude or a Copilot Studio agent to BCDock over MCP with an API key, then list versions, look up an environment's URL, and create, hibernate, resume or delete sandboxes from the chat.
---

# Use BCDock from Claude or Copilot Studio

Goal: ask your AI assistant for a Business Central sandbox, or for the URL of one you already have, without leaving the chat. BCDock serves a remote MCP (Model Context Protocol) server that Claude and Copilot Studio connect to with a BCDock API key.

## What the assistant can do

- **`list_versions`** (free, it only reads): the BC versions and countries you can create a sandbox on right away in one Azure region.
- **`list_environments`** (free, it only reads): your environments, each with its name, status, BC version, country, region, web client URL, and a link to its page in the BCDock portal, where you find its sign-in details. Deleted ones are left out.
- **`get_environment`** (free, it only reads): one environment's status, its URLs (web client, OData, dev endpoint), and a link to its page in the BCDock portal, where you find its sign-in details. By name or id.
- **`get_billing`** (free, it only reads): your plan and its rates, your trial hours while you are on the trial, and your active and stored hours with their estimated charges over the last 30 days. Invoices and payment details stay in the portal; the result links to its billing page.
- **`request_version`** (free): asks BCDock to build a BC version, country and type that `list_versions` does not offer yet. BCDock is told by email, and you get an email once you can create an environment on it. Needs a key with env:write.
- **`create_environment`** (starts a cost): creates a sandbox, usually running in about 15 minutes. Once it is running it bills at your plan's active rate.
- **`hibernate_environment`** (cuts the cost): hibernates a sandbox. Its data is kept, its URL stops answering, and it bills at the much lower stored rate.
- **`resume_environment`** (starts the cost again): resumes a hibernated sandbox with its data and URL as they were, usually running in about 4 minutes, or 10 to 15 when a new server has to start. Once it is running it bills at your plan's active rate.
- **`delete_environment`** (stops the cost): deletes a sandbox permanently, which stops its billing. It cannot be undone, and the tool tells the assistant to ask you to confirm first.

Rates are on the [pricing page](https://bcdock.io/pricing). If a resume needs a newer BC platform version, the assistant cannot confirm that for you: resume it from the portal or with `bcdock env resume`.

## 1. Create an API key

In the portal, go to [Profile → API keys](https://app.bcdock.io/profile/api-keys) and select **New key**.

- For look-ups only, tick **Read environments**. With this key the assistant cannot change or create anything.
- To let the assistant create, hibernate, resume or delete, also tick **Create & delete environments**.

Copy the key (it starts with `bdk_`). The portal shows it once.

## 2. The connection settings

Both apps need the same three values.

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

## 3a. Claude

In Claude, go to **Customize → Connectors** and select **Add custom connector**.

1. **Name**: `BCDock`.
2. **MCP server URL**: `https://api.bcdock.io/api/v1/mcp`.
3. **Authentication**: choose **No sign-in**.
4. **Request headers**: add `authorization` with the value `Bearer bdk_...`.
5. Select **Add**, then turn the connector on in a chat.

**Request headers** is a beta that Anthropic has opened to some accounts. If your dialog has no Request headers section, your Claude cannot send an API key yet, and BCDock does not offer a Claude sign-in (OAuth) yet. In that case, use the [portal](../quickstart/portal.md) or the [Agent quickstart](../quickstart/agent.md) for now.

On a Team or Enterprise plan, an Owner adds the connector under **Organization settings → Connectors**.

## 3b. Copilot Studio (and Microsoft 365 Copilot)

Microsoft 365 Copilot reaches MCP servers through an agent you build in Copilot Studio, so the steps are in Copilot Studio.

1. Open your agent's **Tools** page, select **Add a tool**, then **New tool**, then **Model Context Protocol**.
2. Fill in **Server name** (`BCDock`), a **Server description** (for example "Creates and manages Business Central sandboxes"), and **Server URL** `https://api.bcdock.io/api/v1/mcp`.
3. For authentication, choose **API key**, type **Header**, and header name `authorization`.
4. Select **Create**, then **Create a new connection**. When it asks for the key, enter `Bearer bdk_...`.
5. Select **Add to agent**.

Microsoft's own steps are in [Connect your agent to an existing MCP server](https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent).

## 4. Try it

Ask the assistant:

- "Which BC versions can I create in australiaeast?"
- "What is the URL of my BCDock environment `acme-test`?"
- With a key that can create: "Create a BC sandbox called `demo-friday` on the latest AU version." Then ask for its URL after about 15 minutes.

## Troubleshooting

**The connector cannot connect, or Claude keeps asking you to sign in.** The key is not arriving in the shape above. Check the header name is `authorization` and the value starts with `Bearer `. In Claude, check that Authentication is **No sign-in**. You cannot edit a Claude connector's headers after you add it: remove it and add it again.

**"API key requires 'env:write' scope".** The key is read-only. Create a key with **Create & delete environments** ticked, and update the connector.

**"environment ... not found".** The name must match an environment in the company the key belongs to.

## Revoke access

To cut the assistant off, revoke the key in the portal at [Profile → API keys](https://app.bcdock.io/profile/api-keys). It stops working immediately.
