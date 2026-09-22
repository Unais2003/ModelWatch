# Subscriptions

## Purpose

Subscription tracking gives users one local view of recurring AI-service costs
and upcoming renewal dates.

## Current implementation

SwiftData persistence and a read-only subscription list exist. Four sample
subscriptions are inserted on first launch. There is no create, edit,
deactivate, or delete interface yet.

## MVP workflows

### Add

The user enters a service name, monthly cost, currency, optional renewal date,
and active status. Validation occurs before saving.

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

The MVP should either require one user-selected reporting currency or display a
separate total per currency. It must not sum unlike currencies and label the
result with a single currency symbol. Automatic conversion requires a rate
provider, rate timestamp, failure behavior, and separate privacy review.

## Optional reminders

Renewal notifications may follow subscription CRUD. Notification authorization
must be requested in context when the user enables reminders, not at first
launch without explanation.

