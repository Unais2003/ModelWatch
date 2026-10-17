# Roadmap

The roadmap is ordered by dependency and product risk. Dates are intentionally
omitted until the core tracking behavior has been validated.

## Phase 0: Foundation

- [x] Maintain the project documentation structure.
- [x] Remove live random sample seeding; retain deterministic fixtures for previews
  and tests.
- [x] Resolve Swift concurrency isolation warnings.
- [x] Add explicit loading, empty, and error presentation.
- [x] Prevent stale dashboard requests from replacing the selected range.
- [x] Add initial analytics and dashboard state tests.
- [x] Introduce a deterministic clock dependency for activity tracking.
- [x] Introduce deterministic calendar behavior for analytics range boundaries.

Exit criterion: the existing prototype builds without warnings and never
presents demonstration data as real user activity.

## Phase 1: Activity tracking

- [x] Implement frontmost-application observation.
- [x] Define and persist the user-approved application list.
- [x] Implement the activity-session state machine.
- [x] Handle switching, pause/resume, sleep/wake, session changes, and termination.
- [x] Add explicit application selection and monitoring controls.
- [x] Add first-run privacy onboarding.
- [ ] Verify lock/unlock behavior across supported macOS versions.
- [x] Cover state transitions and recovery with automated tests.

Exit criterion: a user can run ModelWatch for a day and obtain accurate,
inspectable sessions without granting unnecessary permissions.

## Phase 2: Trustworthy analytics

- [x] Correctly intersect sessions with day, week, and month boundaries.
- [x] Include active sessions without double counting.
- [x] Prevent stale asynchronous dashboard results.
- [x] Add empty, loading, and recoverable failure states.
- [x] Refresh analytics after tracking changes and during active sessions.
- [x] Test calendar, daylight-saving, persistence-overlap, and malformed-session edge cases.

Exit criterion: displayed totals can be reproduced from stored session data.

## Phase 3: Subscription management

- [x] Add create, edit, deactivate, reactivate, and confirmed-delete workflows.
- [x] Validate cost, ISO currency, service name, and optional renewal date.
- [x] Display separate totals per currency without implicit conversion.
- [x] Present renewal dates in the subscription list.
- [ ] Add opt-in local renewal reminders after the notification UX is specified.

Exit criterion: users can maintain their real subscriptions entirely in the app.

## Phase 4: Product completion

- [x] Implement launch at login and remaining preferences.
- [x] Add data inspection, versioned JSON export, and confirmed deletion controls.
- [x] Add semantic accessibility labels and adaptive layouts.
- [x] Add an isolated release-candidate preflight and live accessibility audit.
- [ ] Complete the manual VoiceOver, keyboard, and appearance verification matrix.
- [x] Add app icon, version metadata, and reproducible local app packaging.
- [x] Add Developer ID signing, notarization, and the release workflow.
- [ ] Produce and validate a notarized beta with Apple team credentials.
- [x] Establish launch, idle CPU, memory, and relative-power baselines.
- [ ] Verify energy impact with Instruments Power Profiler on a signed candidate.

Exit criterion: ModelWatch is suitable for a signed beta distribution.

## Later opportunities

- Provider billing API integrations
- Token and model usage analytics
- Budget alerts and spending forecasts
- Optional encrypted synchronization
- Team dashboards

These opportunities require separate privacy, security, and product decisions
and must not complicate the local-first MVP prematurely.
