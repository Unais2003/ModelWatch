# ADR-0001: Observe frontmost applications with NSWorkspace

## Status

Accepted

## Context

ModelWatch needs to measure time spent in user-approved AI applications without
reading application content or requiring invasive macOS permissions. Polling
would also waste energy and could miss short transitions.

## Decision

Use `NSWorkspace` application activation and lifecycle notifications to drive a
main-actor session state machine. Store only the approved application's bundle
identifier, display name, session start, and session end.

Monitoring is disabled by default. Users select application bundles explicitly
and must retain at least one approved application before monitoring can start.
Accessibility and Screen Recording permissions are not requested.

Approved application identities and monitoring state are stored in local user
defaults. Completed activity sessions are stored in SwiftData. Unfinished
sessions left by an unexpected termination are discarded at next startup.

## Consequences

- Monitoring is event-driven and lightweight.
- The MVP cannot identify browser tabs, websites, prompts, or window content.
- Application bundle identifiers provide stable identity, while display names
  remain presentation data.
- Lock/unlock behavior must be verified across supported macOS releases.
- Unexpected termination may lose the final partial session rather than
  overcounting unverified usage.

## Alternatives considered

- Accessibility APIs were rejected because the MVP does not need UI-element or
  window-title access.
- Screen capture was rejected because it collects substantially more data than
  required.
- Periodic polling was rejected in favor of workspace notifications because it
  is less precise and consumes unnecessary resources.
