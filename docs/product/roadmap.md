# Roadmap

The roadmap is ordered by dependency and product risk. Dates are intentionally
omitted until the core tracking behavior has been validated.

## Phase 0: Foundation

- Maintain the project documentation structure.
- Remove live random sample seeding; retain deterministic fixtures for previews
  and tests.
- Resolve Swift concurrency isolation warnings.
- Add explicit loading and error presentation.
- Introduce deterministic clock and calendar dependencies where required.

Exit criterion: the existing prototype builds without warnings and never
presents demonstration data as real user activity.

## Phase 1: Activity tracking

- Implement frontmost-application observation.
- Define and persist the user-approved application list.
- Implement the activity-session state machine.
- Handle switching, pause/resume, sleep/wake, lock/unlock, and termination.
- Add first-run privacy onboarding.
- Cover state transitions and recovery with automated tests.

Exit criterion: a user can run ModelWatch for a day and obtain accurate,
inspectable sessions without granting unnecessary permissions.

## Phase 2: Trustworthy analytics

- Correctly intersect sessions with day, week, and month boundaries.
- Include active sessions without double counting.
- Prevent stale asynchronous dashboard results.
- Add empty, loading, and recoverable failure states.
- Test calendar, daylight-saving, and malformed-session edge cases.

Exit criterion: displayed totals can be reproduced from stored session data.

## Phase 3: Subscription management

- Add create, edit, deactivate, and delete workflows.
- Validate cost, currency, service name, and renewal date.
- Define the MVP currency strategy.
- Add renewal presentation and optional local reminders.

Exit criterion: users can maintain their real subscriptions entirely in the app.

## Phase 4: Product completion

- Implement launch at login and remaining preferences.
- Add data inspection, export, and deletion controls.
- Complete accessibility and appearance verification.
- Add app icon, version metadata, signing, notarization, and release workflow.
- Measure launch time, idle energy use, and memory consumption.

Exit criterion: ModelWatch is suitable for a signed beta distribution.

## Later opportunities

- Provider billing API integrations
- Token and model usage analytics
- Budget alerts and spending forecasts
- Optional encrypted synchronization
- Team dashboards

These opportunities require separate privacy, security, and product decisions
and must not complicate the local-first MVP prematurely.

