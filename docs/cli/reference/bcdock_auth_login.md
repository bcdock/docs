---
title: bcdock auth login
---

## bcdock auth login

Log in via email OTP (returning users; account must already exist)

### Synopsis

Authenticate using the email one-time password flow.

Use this for returning users. Login does NOT create new accounts - brand-new
emails get an explicit error pointing at 'bcdock auth signup'. New users:

  1. bcdock auth join-waitlist
  2. (wait for invite email)
  3. bcdock auth signup --invite-code CODE --email you@example.com
  4. bcdock auth login --email you@example.com

At a terminal you are prompted for your email address, then for the
6-digit code sent to that address. A long-lived API key (bdk_...) is minted
and stored in ~/.bcdock/credentials.json - no silent expiry.

Without a terminal (agents, scripts, CI) it takes two calls:

  1. bcdock auth login --email you@example.com
     sends the code to that address and exits 0, saying to re-run with --otp;
  2. bcdock auth login --email you@example.com --otp <code>
     logs in with that code. --otp never sends a new code, so the code from
     step 1 stays valid (a newly sent code would cancel it).

An agent asks its human for the code between the two calls.

For CI/CD and agent use, prefer API keys: pbpaste | bcdock auth set-token

Exit codes:
  0   ok
  1   general error (wrong email, wrong code, email not registered)
  3   auth failure
  4   rate-limited

```
bcdock auth login [flags]
```

### Examples

```
  bcdock auth login --email you@example.com              # at a terminal: sends, then prompts
  bcdock auth login --email you@example.com              # no terminal: sends the code, exits 0
  bcdock auth login --email you@example.com --otp 123456 # then log in with that code
```

### Options

```
      --email string   Email address (skips prompt)
  -h, --help           help for login
      --otp string     Pre-known OTP code - skips the interactive Code: prompt. Requires --email. Intended for smoke tests and agent flows; humans should leave this unset.
```

### Options inherited from parent commands

```
      --api-url string     API base URL (env: BCDOCK_API_URL)
      --no-color           Disable colored output
  -o, --output string      Output format: table, json, csv (default "table")
  -q, --quiet              Suppress non-essential output
      --timeout duration   Request timeout (default 30s)
      --token string       API token (env: BCDOCK_TOKEN)
```

### SEE ALSO

* [bcdock auth](bcdock_auth.md)	 - Authenticate with the BCDock platform

