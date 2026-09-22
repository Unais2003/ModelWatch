# Data Model

## Storage policy

MVP data is stored locally using SwiftData. No account or remote database is
required. Any future synchronization layer must be optional and documented in
a separate architecture decision.

## ActivitySession

An activity session represents a continuous interval during which one approved
AI application was frontmost.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable unique identifier |
| `applicationBundleIdentifier` | String | Stable macOS application identity |
| `applicationName` | String | Display name captured for presentation |
| `startedAt` | Date | Inclusive session start |
| `endedAt` | Date? | Exclusive session end; `nil` means unfinished |

### Invariants

- `applicationBundleIdentifier` and `applicationName` are non-empty.
- A completed session has `endedAt >= startedAt`.
- At most one session may be active at a time.
- Normal analytics use a half-open interval: `[startedAt, endedAt)`.
- An unexpected termination may leave one unfinished session. Startup recovery
  must close or discard it according to a documented rule.

### Range aggregation

A session contributes only its overlap with the requested range:

```text
effective start = max(session start, range start)
effective end   = min(session end or current time, range end)
duration        = max(0, effective end - effective start)
```

This handles sessions crossing midnight or another reporting boundary.

## Subscription

A subscription represents a recurring monthly AI-service expense.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable unique identifier |
| `serviceName` | String | User-facing provider or plan name |
| `monthlyCost` | Double | Monthly amount in the stored currency |
| `currencyCode` | String | ISO 4217 currency code |
| `renewalDate` | Date? | Optional next renewal date |
| `isActive` | Bool | Whether it contributes to active views |

### Invariants

- `serviceName` is non-empty after trimming whitespace.
- `monthlyCost` is finite and not negative.
- `currencyCode` is a supported uppercase currency code.
- Mixed currencies are grouped separately unless an explicit conversion source
  and timestamp are introduced.

## Application configuration

The activity-tracking MVP also needs a representation of applications the user
has approved for tracking. The minimum information is:

- Bundle identifier
- Display name
- Enabled state

This may initially be stored as a small Codable preference if no relationships
or query requirements justify another SwiftData model. The implementation
choice should be recorded before persistence behavior ships.

## Deletion and retention

Users must be able to delete all activity history. Per-record deletion and a
configurable retention period can follow if user research demonstrates demand.
Deletion must update visible analytics immediately and report failures.

Schema-breaking changes require a migration plan and tests. Production records
must never be silently discarded to recover from a migration error.

