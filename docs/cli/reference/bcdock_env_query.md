---
title: bcdock env query
---

## bcdock env query

Run a read-only OData query against a BC environment

### Synopsis

Read business data out of a BC environment over its OData v4 endpoint.

This is the read path for scripts and agents. It replaces the pattern of pulling the
admin password out of 'bcdock env get' and calling OData with curl, which put a live
credential into the caller's transcript.

Credentials: the CLI fetches the environment's web-service access key once per
invocation from the audited reveal endpoint (the same one 'bcdock env credentials'
uses) and sends it as HTTP Basic auth. It is never printed, never accepted as a flag,
and never reaches your shell history or the process list. BC's OData and SOAP surfaces
reject the admin password, so the access key is the credential in play here.

Read-only by construction: the verb issues GET and nothing else. There is no method
flag, so a write attempt is refused as an unknown flag before any call. A path that is
an absolute URL, escapes the OData root, or names $batch is refused for the same reason.

The path is relative to the environment's OData root and is taken literally (do not
pre-percent-encode it). OData v4 serves the entity sets your environment publishes as
web services, so WHICH NOUNS EXIST VARIES BY ENVIRONMENT. 'Company' is a BC system
entity set and is present on every environment. Everything else depends on what has
been published, so ask the environment rather than guessing:

  Company                                  the company list - start here if you do
                                           not know the company name. Note the
                                           capital and the singular
  $metadata                                every entity set this environment serves.
                                           This is the answer to "what can I query?"
  Company('CRONUS AU')/Chart_of_Accounts   a company-scoped set, or pass --company
  Company('CRONUS AU')                     a single entity by key

Measured on a BC 28.4 sandbox: 82 published entity sets, among them
Chart_of_Accounts, workflowCustomers, G_LEntries and SalesOrder. Names are
case-sensitive, and a name BC does not serve answers 404 rather than an empty list.

Output:
  -o table  (default) scalar columns; any dropped nested column is named on stderr
  -o json   the 'value' array, pretty-printed
  -o csv    the same scalar columns as the table
A response that is not a collection (a single entity, $count) is printed as JSON in
every format, because there are no rows to lay out.

Exit codes:
  0   ok
  1   general error (refused path, no OData URL, BC error response)
  3   auth failure (missing or invalid bcdock token)
  5   environment not found

```
bcdock env query <env> <odata-path> [flags]
```

### Examples

```
  bcdock env query my-env Company -o json
  bcdock env query my-env '$metadata'
  bcdock env query my-env --company "CRONUS AU" Chart_of_Accounts --select "No,Name" --top 3
  bcdock env query my-env --company "CRONUS AU" workflowCustomers --filter "startswith(Name,'Adatum')" -o json
```

### Options

```
      --company string     BC company to scope the query to (wraps the path in Company('...'))
      --filter string      OData $filter expression
  -h, --help               help for query
      --insecure           Skip TLS verification for the OData endpoint (use for self-signed local certs only)
      --select string      OData $select list (comma-separated field names)
      --tenant string      BC tenant to query (default "default")
      --timeout duration   Max time to wait for the OData response (default 1m0s)
      --top int            OData $top row limit (0 = server default)
```

### Options inherited from parent commands

```
      --api-url string   API base URL (env: BCDOCK_API_URL)
      --no-color         Disable colored output
  -o, --output string    Output format: table, json, csv (default "table")
  -q, --quiet            Suppress non-essential output
      --token string     API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock env](bcdock_env.md)	 - Manage Business Central environments

