# Testing

## Goals

Tests should protect behavior that would cause users to distrust their usage or
cost data. Prefer deterministic unit and integration tests over broad UI tests.

## Test layers

### Business logic tests

Use fake stores and a controllable clock to cover:

- Activity-tracking state transitions
- Session closure and recovery
- Range intersection and aggregation
- Active-session duration
- Subscription validation and totals
- Mixed-currency behavior

### View-model tests

Cover:

- Loading, loaded, empty, and failure states
- Retry behavior
- Range changes and stale-request prevention
- Tracking pause/resume presentation
- Subscription mutations and validation feedback

### Persistence integration tests

Use an in-memory SwiftData container to verify:

- Save and fetch behavior
- Date-range predicates
- Active-subscription filtering
- Unfinished-session lookup
- Schema migrations when introduced

### UI verification

Keep UI tests focused on a few critical workflows:

- First-run onboarding
- Pause/resume monitoring
- Add and edit a subscription
- Delete activity history

Use stable accessibility identifiers only where semantic labels are not enough.

## Time-based test matrix

Analytics tests must include:

- A session entirely inside the range
- A session starting before the range
- A session ending after the range
- A session spanning the complete range
- A session on an exact boundary
- An unfinished active session
- A zero-length or negative malformed session
- Week and month transitions
- Daylight-saving transitions in a deterministic time zone

## Commands

Run all tests from the repository root:

```bash
swift test
```

Warnings should be reviewed as potential future errors. New behavior is not
complete merely because the existing no-op tests pass.

