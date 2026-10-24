---
title: Account deletion - how it works, what we keep, how to come back
description: Self-service GDPR Art. 17 / APP 11 account deletion. 30-day grace window with one-click cancellation, anonymise-in-place at +30d, restore-on-sign-in within the grace window.
schema_type: HowTo
---

# Account deletion

Goal: cleanly leave BCDock. We hibernate your environments immediately, give you a 30-day grace window in case you change your mind, and at +30 days we anonymise your account in place - preserving FK integrity and audit trails while making the row no longer about you.

This implements GDPR Article 17 (right to erasure) and Australian Privacy Principle 11. The decision to *anonymise in place* rather than cascade-delete preserves audit trail integrity, financial-record linkage, and provisioning telemetry that's already keyed by environment - none of which is personal data, all of which would be destroyed by a hard purge. The price is a single salted email hash retained for trial-abuse suppression on re-registration; we discuss the tradeoff explicitly in the privacy policy.

## Timeline

```
T+0          Deletion request submitted
             → All your environments hibernate immediately (active billing stops)
             → Account + company marked as pending deletion
             → 30-day grace window begins
             → Confirmation email sent

T+0..T+30d   You can sign back in (auto-cancels deletion) or cancel explicitly
             from the portal / CLI / support

T+30d        Scheduled anonymisation runs
             → Personal data on your account overwritten in place (email, name, etc. → placeholders)
             → If sole-owner Company: company name overwritten to a generic placeholder
             → Hibernation backup blobs deleted
             → Session and OTP state deleted
             → A salted email hash retained for abuse-prevention (re-registration check)
             → A trial-history flag retained if you were ever on a trial
             → Status: `deleted`
```

## What "anonymise in place" means

After +30d, your account record still exists in our database - but the bytes that were *you* are gone:

- Personal contact and identity data (email, display name, OAuth subject, last login timestamp, time zone) is overwritten to null.
- A salted hash of the original email is retained - used to suppress trial-abuse on re-registration.
- A trial-history flag is retained - blocks a second free trial.
- The internal account identifier, creation timestamp, and auth-provider type are retained so audit and usage records still resolve through them.

For sole-owner companies: the company is anonymised the same way (name and slug overwritten to generic placeholders). Co-member companies are untouched - your membership is removed and ownership transfers to the next-oldest member if you owned it.

What's *actually* deleted (not just anonymised):

- **Hibernation backup blobs** (your BC database snapshots)
- **Session and OTP state** (ephemeral)

What's untouched (not personal data):

- Provisioning logs (env-keyed, no user identifier)
- Pool / VM / image records (platform infrastructure)

The legal basis for retaining the salted hash is GDPR Article 17(3)(e) and APP 11.2(c) - defending against trial-abuse via repeated signups is a legitimate-interest grounds for limited retention. The salt that hashes the email lives in Key Vault, never in the database, and never rotates (rotating would lose the suppression check).

## Request deletion from the portal

1. Sign in at [app.bcdock.io/profile](https://app.bcdock.io/profile).
2. Find the **Delete account** card.
3. Type your account email exactly to confirm.
4. Click **Delete**.
5. The card flips to a **Cancel deletion** state showing the scheduled anonymise date.
6. You get a confirmation email.

## Request deletion from the CLI

```bash
bcdock me delete --confirm you@example.com
```

The `--confirm` flag must equal your account email - protects against accidental deletion in agent-driven flows. Returns a JSON summary with the scheduled anonymise timestamp and counts of companies / environments affected.

```bash
bcdock me delete --confirm you@example.com -o json
{
  "userId": "...",
  "scheduledAnonymiseAt": "2026-06-04T10:30:00Z",
  "companiesScheduledForDeletion": 1,
  "companiesWithOwnershipTransferred": 0,
  "membershipsRemoved": 0,
  "environmentsScheduledForHibernation": 3
}
```

## Cancel a pending deletion

Three paths, all equivalent:

| Path | How |
|---|---|
| **Portal** | Sign in → Profile → click **Cancel deletion** |
| **CLI** | `bcdock me cancel-deletion` |
| **Auto on sign-in** | Just sign back in. Any successful `bcdock auth login` (interactive - prompts for an OTP code we email you) or portal OTP exchange within the grace window auto-cancels the pending deletion - equivalent to running `me cancel-deletion`. |

```bash
bcdock me cancel-deletion -o json
{ "cancelled": true }
```

`cancelled: true` if there was a pending request; `cancelled: false` if there wasn't. Safe to call unconditionally.

## Coming back after +30d (anonymisation has fired)

If you signed up again with the same email after we anonymised your account, the sign-in step detects the email-hash match and **restores** your account in place (plaintext email re-attached, hash cleared, status active, display name reset). Then:

- You create a fresh company (the anonymised company stays anonymised - it's not yours anymore).
- If you previously had a trial, the new company **does not** get a free trial - you go straight to a paid plan. One trial per human.
- If you never had a trial, the new company gets a fresh trial.

Subsequent re-deletions, re-registrations, etc. all work the same way. There's no permanent block.

### Edge case - email recycling

If a previously-anonymised email becomes the property of a new human (Gmail recycles abandoned addresses, custom domain ownership changes), that human will be treated as the original owner on first signup - the email-hash matches and we restore the anonymised User row to them. This is the same model as password-reset-via-email everywhere: **whoever controls the inbox controls the account.** Worth being explicit about because it's the only path where one human can land in another human's BCDock account.

### Edge case - email already taken

If the original email is currently held by a different active user (rare but possible if the original owner anonymised, then someone else signed up with the same email before the original came back), restoration is skipped and the returning user falls through to a normal signup. The restored-account path requires the email to be currently unclaimed.

## Staff-initiated cancellation

If you need help restoring a deletion (e.g. you requested deletion in error and don't have credentials to sign back in), email support@bcdock.io. BCDock staff can cancel the pending deletion via internal tooling; the action is captured in the audit trail attributed to the operator.

The 30-day anonymise job fires at `scheduledAnonymiseAt` regardless of whether anyone has reviewed. There is no "delay anonymisation" path - the schedule is the legal commitment.

## What this isn't

- **Not "delete one environment, keep the rest."** That's `bcdock env delete <name>` - a per-env operation, no grace window.
- **Not "delete my company but keep my user."** Sole-owner company deletion is tied to user deletion. Co-member ownership transfer happens automatically.
- **Not "delete the company; I'll keep my login and join another company."** Co-member case: leave the company first (admin or owner removes you from the member list), then optionally delete your user separately.

## Related

- [Data export](data-export.md) - get a copy of your data before deletion
- [`bcdock me show`](../cli/reference/bcdock_me_show.md) - see your current status and deletion schedule
- [`bcdock me delete`](../cli/reference/bcdock_me_delete.md) - full flag reference
- [Privacy policy](https://bcdock.io/legal/privacy-policy) - the full retention and processing notice
