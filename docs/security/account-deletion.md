---
title: Account deletion - security view
description: How account deletion is built. 30-day grace, anonymise-in-place mechanics, FK preservation, restore-on-sign-in, audit trail integrity.
---

# Account deletion - security view

The customer-facing walkthrough lives at [guides/account-deletion](../guides/account-deletion.md). This page is the security-level companion: how anonymise-in-place actually works, what's preserved, what's deleted, and the auditable boundary between the two.

## The architectural decision

GDPR Article 17 (right to erasure) is satisfied by either deletion or anonymisation - recital 26 makes anonymous data outside the regulation. Australian Privacy Principle 11 (Australia) lands at the same place via different language.

We chose **anonymise in place** rather than cascade-delete. Hard-purge would destroy audit trails, financial-record FK integrity, and provisioning telemetry - none of which is personal data, all of which is operationally needed. Anonymisation preserves the structure while making the bytes that *identified you* unreadable.

## Timeline

```
T+0          Deletion request submitted
             → All envs hibernated immediately (active billing stops)
             → Account + company marked as pending deletion
             → 30-day grace begins
             → Confirmation email sent

T+0..T+30d   You can sign back in (auto-cancel) or call cancel-deletion.
             BCDock staff can also cancel on your behalf via internal tooling.

T+30d        Scheduled anonymisation runs (background job set at T+0).
             → Personal data on your account overwritten in place
             → If sole-owner Company: company name overwritten
             → Hibernation backup blobs deleted (real delete, not soft)
             → Session and OTP state deleted
             → A salted email hash is retained for trial-abuse suppression
             → A trial-history flag is retained if applicable
             → Status → `deleted`
```

## What's overwritten

Personal contact and identity data on your account (email address, display name, OAuth subject, last login timestamp, time zone) is overwritten to null.

### What's retained on your account and why

A small set of non-identifying data is kept:

- Internal account identifier and creation timestamp - retained because audit records, usage history, and environment provisioning history reference the account by ID. Severing the link would break those records.
- Auth-provider type - same as above.
- A salted hash of the original email - retained for re-registration detection (see below).
- A trial-history flag - retained for trial-abuse suppression on re-registration.
- Account status set to `deleted` so the row is excluded from customer-facing APIs by default.

For sole-owner companies, the company is anonymised the same way (name and slug overwritten to generic placeholders). The structural identifiers and creation timestamp are retained for the same record-integrity reason.

For co-member companies, your membership is removed and ownership transfers to the next-oldest member if you were the owner; the company itself is untouched.

## What's actually deleted

Not anonymised - *deleted*:

- **Hibernation backup blobs** - your BC database snapshots. Hard delete (bypasses the 7-day soft-delete that protects against accidental env deletes).
- **Refresh tokens** - ephemeral session state.
- **Email codes (OTP)** - ephemeral auth state.

## What's untouched

Not personal data:

- **Provisioning logs** - keyed by environment / pool ID, with no user identifier. Operational telemetry.
- **Pool / VM / image records** - platform infrastructure, doesn't reference users.

## The salted email hash - legitimate-interest retention

After anonymisation, your account carries a salted hash of the original email (SHA-256 of the lowercased email combined with a server-side salt, hex-encoded). The plaintext email is gone; the hash is kept. We use it for two purposes:

### Re-registration detection

When a previously-anonymised email signs up again, the sign-in step computes the hash and finds the matching anonymised account. We **restore** the account in place (plaintext email re-attached, hash cleared, status active, display name reset). You're back; your old company is not (it stayed anonymised - you create a fresh one).

### Trial-abuse suppression

If the restored account had previously consumed a trial, the new company it creates does not get a free trial. One trial per human, identified by email.

### Legal basis

GDPR Article 17(3)(e) ("processing is necessary for the establishment, exercise or defence of legal claims") and APP 11.2(c) ("the entity is required by or under an Australian law, or a court/tribunal order, to retain the personal information") cover the limited retention. Defending against repeated-signup trial-abuse is a legitimate-interest grounds.

### Salt handling

The salt lives in Azure Key Vault, never in the database, never in code or logs. It does not rotate by design - rotating would invalidate every existing hash and lose the suppression check.

If the salt leaks, an attacker with the database can rainbow-table common emails. Same threat model as password hashes; mitigated by Key Vault access controls.

## Cross-account isolation

The deletion flow runs under your authenticated context, with company isolation active. You cannot trigger deletion of another account, even if you share a company.

Staff can also cancel a pending deletion on your behalf via internal tooling; the action is captured in the audit trail attributed to the operator.

## Audit trail integrity

Audit records reference the user by internal ID. After anonymisation, the records still resolve - they point at an anonymised account whose ID is preserved and whose personal fields are null. The audit trail is continuous: "what happened" is preserved, "who specifically" is anonymised after +30d.

This is the load-bearing argument for anonymise-in-place over hard-purge. A hard purge would either break the link or cascade-delete the audit trail - both unacceptable.

## Edge cases

### Email recycling at the provider level

If a previously-anonymised email becomes the property of a new human (Gmail recycles abandoned addresses, custom domain ownership changes), that human will be treated as the original owner on first signup - the email hash matches and we restore the anonymised account to them. **Whoever controls the inbox controls the account.** Same threat model as password-reset-via-email everywhere; worth being explicit because it's the only path where one human can land in another human's BCDock account.

### Email already taken by a different active user

If the original email is currently held by a different active user (rare but possible if the original owner anonymised, then someone else signed up with the same email before the original came back), restoration is skipped and the returning user falls through to a normal signup. The restored-account path requires the email to be currently unclaimed.

## Threat model

- **Adversarial deletion** - the `--confirm <email>` requirement on `bcdock me delete` blocks accidental deletion in agent-driven flows. The portal requires typing the email exactly. There's no zero-click path.
- **Anonymisation reversal** - once anonymisation runs, the original email is unrecoverable from our side (only the salted hash remains). Restoration requires you to sign in with the original email, which only whoever controls the inbox can do.
- **Salt compromise** - would expose the hash to rainbow-table attack against common emails. Mitigations: Key Vault RBAC, no rotation (so a single point of leak), separate salt per environment in principle.

## Related

- [Guides → Account deletion](../guides/account-deletion.md) - customer-facing walkthrough
- [Data handling](data-handling.md) - what's stored, where, for how long
- [Data export](data-export.md) - companion GDPR Art. 15 surface
- [Anonymisation architecture](../architecture/anonymisation.md) - the broader rationale
