# Subscriptions

## Purpose

Subscription tracking gives users one local view of recurring AI-service costs
and upcoming renewal dates.

## Current implementation

The subscriptions dashboard provides native create, edit, deactivate,
reactivate, and confirmed-delete workflows backed by SwiftData. Active and
inactive records remain visible, while only active records contribute to
monthly totals. Persistence and validation failures are presented without
silently removing visible data.

The editor captures a service name, monthly cost, ISO currency, optional
renewal date, and active state. It uses a temporary form value, so cancelling an
edit cannot mutate the stored record.

## MVP workflows

### Add

The user enters a service name, monthly cost, currency, optional renewal date,
and active status. Validation occurs before saving. The empty state and page
toolbar both expose the add workflow.

### Edit

Every stored field can be changed. Cancelling an edit must leave the persisted
record unchanged.

### Deactivate

An inactive subscription remains available for later reactivation but does not
contribute to active totals.

### Delete

Deletion is explicit and confirmed when accidental loss would be surprising.
Failures are reported without removing the item from visible state.

## Validation

- Trim and require the service name.
- Require a finite, non-negative monthly cost.
- Store a supported ISO 4217 currency code.
- Treat renewal date as optional.
- Use locale-aware currency formatting.

## Currency strategy

ModelWatch displays a separate active monthly total for each stored currency.
The overview shows the formatted total when exactly one currency is active and
shows the number of currencies otherwise. Unlike currencies are never summed.

Automatic conversion is deliberately excluded because it would require an
exchange-rate provider, a rate timestamp, failure behavior, and a separate
privacy review.

## Optional reminders

The General Settings tab provides an off-by-default renewal-reminder toggle.
ModelWatch requests notification authorization only when the user enables that
toggle. Declining or later revoking permission turns the preference off without
affecting subscription management, activity tracking, or analytics.

For each active subscription with a future next-renewal date, ModelWatch
schedules one local notification for 9:00 AM three calendar days before the
renewal. Enabling reminders inside that three-day window schedules a near-term
notification instead, so the known renewal is not silently missed. Inactive
subscriptions, missing dates, and past dates are excluded. Creating, editing,
activating, deactivating, deleting, or bulk-deleting subscriptions refreshes the
pending requests.

Notifications deliberately use generic text. Service names, prices, and
currencies do not appear in notification content. The stored date represents
the next renewal, so reminders do not repeat automatically; users update that
date when the provider supplies a new one.
