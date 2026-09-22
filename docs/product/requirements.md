# Product Requirements

## Problem

People increasingly use several AI applications during the same day. They lack
a simple, private way to understand time spent across those tools and the total
cost of recurring AI subscriptions.

## MVP scope

### Activity monitoring

- Monitor the frontmost macOS application using event-driven system APIs.
- Record sessions only for applications the user has enabled.
- Store the application name, bundle identifier, start time, and end time.
- Keep at most one active application session at a time.
- Close or pause sessions when the Mac sleeps, locks, the user disables
  monitoring, or ModelWatch terminates normally.
- Recover safely from an unfinished session after an unexpected termination.

### Analytics

- Present daily, weekly, and monthly usage ranges.
- Show total duration and the number of tracked applications used.
- Aggregate duration by application.
- Include the elapsed portion of the current active session.
- Count only the portion of a session that overlaps the selected date range.
- Show distinct loading, empty, and failure states.

### Subscriptions

- Add, edit, deactivate, and delete a subscription.
- Store service name, monthly cost, currency, optional renewal date, and status.
- Validate required fields and reject negative costs.
- Avoid combining unlike currencies into one misleading total.

### Dashboard and menu bar

- Provide a native dashboard with overview, subscriptions, and settings.
- Show whether monitoring is active and which tracked application is active.
- Let the user pause or resume monitoring from the menu bar.
- Provide direct access to the dashboard, settings, and quit action.

### Preferences and control

- Let the user select which applications to track.
- Support launch at login through the macOS-supported service.
- Provide a way to inspect and delete locally stored usage data.
- Preserve preferences locally.

### Privacy and onboarding

- Explain what ModelWatch observes and stores before monitoring begins.
- Request only permissions required for enabled functionality.
- Do not collect window titles, document names, typed content, screenshots, or
  browser history for the MVP.
- Require no account and perform no analytics telemetry by default.

## Non-goals for the MVP

- OpenAI, Anthropic, or other billing API integrations
- Token-level usage tracking
- Cloud synchronization
- Team or organization dashboards
- Productivity scoring
- Spending forecasts or anomaly detection
- Browser-tab or website-level monitoring

## Quality requirements

- Support macOS 14 and later.
- Preserve responsive UI while loading or aggregating data.
- Support Light Mode, Dark Mode, keyboard use, and VoiceOver labels.
- Handle persistence errors without crashing or presenting false totals.
- Use structured logs without including personal activity or sensitive data.
- Include automated tests for time boundaries, aggregation, state transitions,
  validation, and failure handling.

## Definition of done

A feature is complete when it compiles without new warnings, has appropriate
tests, handles expected failures, follows the existing architecture, works in
Light and Dark appearances, and has its documentation updated.

