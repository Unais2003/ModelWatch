# Architecture Overview

## Current status

ModelWatch is a Swift Package Manager executable for macOS 14 and later. It
uses SwiftUI for presentation, SwiftData for persistence, and Apple Charts for
visualization. There are no third-party runtime dependencies.

The current implementation provides the application shell, dashboard,
persistence models, and read-only analytics. Activity monitoring and
notifications are represented by no-op services and are not implemented yet.

## Layers

```text
SwiftUI scenes and views
        |
        v
Observable view models
        |
        v
Service protocols and business rules
        |
        v
Store protocols
        |
        v
SwiftData
```

### Application composition

`ModelWatchApp` owns the application scenes. `AppContainer` creates the model
container, stores, and service implementations and injects them into view
models. This is the composition root; concrete dependencies should remain out
of feature views.

### Views

Views render state and send user intent to view models. They should not query
SwiftData, observe workspace notifications, calculate billing totals, or own
other business rules.

### View models

View models coordinate feature operations and expose presentation state. They
should explicitly represent loading, loaded, empty, and failed states where
those distinctions matter to the user.

### Services

Services own business behavior such as tracking lifecycle and usage
aggregation. Protocols provide narrow substitution points for tests and future
implementations.

### Stores

Stores isolate SwiftData fetch and save operations. SwiftData model instances
must remain within a consistent actor boundary. The MVP may use main-actor
isolation for simplicity; any later move to a dedicated `ModelActor` should be
an explicit architecture decision.

## Dependency direction

- Views depend on view models and presentation models.
- View models depend on service protocols.
- Services depend on store protocols and small system abstractions.
- Concrete stores depend on SwiftData.
- `AppContainer` is the only place that selects live implementations.

Lower layers must not import feature views or depend on application scenes.

## Proposed feature boundaries

The existing folder structure is sufficient for the MVP. Add focused files
within the current `Models`, `Services`, `Stores`, `ViewModels`, and `Views`
groups rather than introducing packages or frameworks prematurely.

Expected additions include:

- A workspace-observation abstraction around macOS activation events
- A tracking coordinator implementing the session state machine
- A configured-application model or value type
- Subscription mutation operations and validation
- Explicit dashboard presentation state
- A clock abstraction for deterministic time-based tests

## Concurrency

SwiftData context access must occur on its owning actor. Protocol isolation
must agree with concrete implementations so model objects do not cross actor
boundaries accidentally. Long-running or CPU-heavy work should not execute on
the main actor, but the MVP's small fetches and UI state updates can remain
main-actor isolated until profiling demonstrates otherwise.

Overlapping dashboard loads must be cancelled or guarded by a request identity
so an earlier request cannot overwrite a newer range selection.

## Error handling

- Persistence initialization should provide a recoverable user-facing path
  rather than terminating with `fatalError`.
- Save and seed failures must not be ignored.
- UI state must distinguish a successful empty result from a failed request.
- Logs may contain operational context but not detailed user activity.

## Testing strategy

Business rules should be testable without launching the application. Use fake
stores, a controllable clock, and deterministic calendars for service and view
model tests. Use an in-memory SwiftData container for store integration tests.
See [Testing](../engineering/testing.md) for the expected test coverage.

## Related documents

- [Data model](data-model.md)
- [Activity-tracking design](activity-tracking.md)
- [Architecture decision records](decisions/README.md)
- [Product requirements](../product/requirements.md)

