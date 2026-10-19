# Activity-Tracking Design

## Goal

Record trustworthy usage intervals for applications explicitly enabled by the
user while collecting the least information necessary.

## Current implementation

ModelWatch observes `NSWorkspace` activation and lifecycle notifications with an
event-driven service. Monitoring is disabled by default and cannot be enabled
until the user selects at least one macOS application bundle. Approved
applications and the monitoring preference are stored in local user defaults;
activity sessions are stored in SwiftData.

## System boundary

The tracker needs only application activation and relevant system lifecycle
events. For the MVP it must not inspect window titles, documents, keystrokes,
screenshots, browser tabs, or application content.

## Inputs

- Frontmost application at monitoring start
- Application activation notifications
- User pause and resume actions
- Workspace sleep and wake notifications
- Session lock and unlock notifications when available
- Application termination
- Current time from an injected clock
- Set of enabled application bundle identifiers

## State

```text
paused
  └── resume ──> monitoring with no active tracked app

monitoring with no active tracked app
  ├── tracked app activates ──> tracking session
  └── pause/sleep/lock ───────> paused

tracking session
  ├── another tracked app activates ─> close old, open new
  ├── untracked app activates ────────> close old, monitoring idle
  └── pause/sleep/lock/quit ──────────> close old, paused
```

The transition that closes an existing session and opens another should be one
coordinated operation so two sessions cannot overlap.

Sleep and inactive-login-session states are tracked as independent suspension
reasons. Application activation events are ignored while any reason remains. If
sleep and lock overlap, tracking resumes only after both wake and session-active
notifications have arrived.

## Startup recovery

An unexpected crash can leave a stored session without an end date. On launch,
the service should find unfinished sessions before starting new monitoring.

The initial conservative policy should close an unfinished session at the
earliest reliable lifecycle timestamp available, or discard it when no reliable
end can be established. It must not assume the application remained active for
the entire time ModelWatch was not running.

The current conservative policy deletes unfinished sessions during startup.
This avoids counting the period after an unexpected termination as usage.

## Application identity

Bundle identifier is the stable identity. Display names may change and should
not be used to decide whether an application is tracked. Initial application
selection should come from installed/running applications or a curated list,
but user approval is authoritative.

## Event processing rules

- Ignore duplicate activation events for the current bundle identifier.
- Clamp or reject events earlier than the current session start.
- Serialize state transitions on one actor.
- Persist the closed session before exposing updated analytics.
- Make pause/resume idempotent.
- Ignore application activation while sleep or login-session suspension remains.
- Require every overlapping suspension reason to clear before resuming.
- Do not create zero-length sessions unless required for diagnostics; normally
  discard them.

## Menu-bar behavior

The menu bar should show one of:

- Monitoring paused
- Monitoring active
- Tracking `<Application Name>`
- Monitoring unavailable, with a recoverable explanation

Pause/resume must be available without opening the dashboard.

## Test cases

- Start while a tracked application is active
- Start while an untracked application is active
- Switch tracked A to tracked B
- Switch tracked application to untracked application
- Receive a duplicate activation notification
- Pause and resume repeatedly
- Sleep/wake and lock/unlock, including overlapping and duplicate notifications
- Quit with an active session
- Recover an unfinished session after termination
- Change the approved application list while tracking
- Receive out-of-order or equal timestamps

## Decisions

- Unfinished crash sessions are discarded during startup.
- Approved applications and monitoring state use local user defaults.
- Monitoring is off by default and requires at least one approved application.
- Positive-duration sessions are retained without a minimum-duration filter.

## Remaining work

- Complete the
  [manual lifecycle matrix](../engineering/activity-lifecycle-verification.md)
  on the minimum and latest supported macOS releases.
- Exercise the complete lifecycle using a signed application build.
