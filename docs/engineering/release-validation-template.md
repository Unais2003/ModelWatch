# ModelWatch Beta Validation Record

This document is the evidence record for one exact release candidate. Complete
it against the notarized archive that will be distributed. Do not copy results
from an earlier build, and do not mark a check complete unless the named
candidate was exercised.

## Candidate identity

| Field | Value |
| --- | --- |
| Marketing version | `{{VERSION}}` |
| Build number | `{{BUILD}}` |
| Git commit | `{{COMMIT}}` |
| Record created | `{{DATE}}` |
| Archive SHA-256 | Pending |
| Notarization submission ID | Pending |
| Signing identity/team | Pending |
| Tester | Pending |

## Automated release gates

- [ ] `./script/verify_release_candidate.sh` passes at the release commit.
- [ ] The Developer ID release workflow completes without skipped steps.
- [ ] The stapled ticket validates with `xcrun stapler validate`.
- [ ] Gatekeeper accepts the extracted archive with `spctl --assess`.
- [ ] The archive SHA-256 matches its distributed checksum file.
- [ ] Installation and first launch succeed in a clean macOS user account.

Record commands, logs, or defect references:

> Pending

## Supported systems

Record every Mac used for verification. The lifecycle matrix requires both the
minimum supported macOS release and the latest supported release.

| macOS version | Hardware model | Architecture | Clean account | Tester |
| --- | --- | --- | --- | --- |
| Pending | Pending | Pending | Pending | Pending |

## Accessibility, keyboard, and appearance

- [ ] Complete onboarding, dashboard, subscriptions, Settings, and deletion
  confirmations using only the keyboard.
- [ ] Confirm VoiceOver reading order, names, values, and action menus.
- [ ] Verify dashboard, sheets, menu-bar menu, and Settings in Light Mode.
- [ ] Repeat the appearance check in Dark Mode.
- [ ] Verify the largest supported accessibility text size.
- [ ] Verify Increase Contrast and Reduce Transparency.
- [ ] Confirm focus returns predictably after sheets and alerts close.

Defects or evidence:

> Pending

## Activity lifecycle matrix

For each row, inspect the exported session start and end times. Repeat the
matrix on the minimum and latest supported macOS versions.

| Scenario | Minimum macOS | Latest macOS | Evidence or defect |
| --- | --- | --- | --- |
| Lock while an approved app is frontmost | Not run | Not run | Pending |
| Unlock to the same approved app | Not run | Not run | Pending |
| Unlock to an unapproved app | Not run | Not run | Pending |
| Sleep and wake without locking | Not run | Not run | Pending |
| Sleep while locked, then wake to lock screen | Not run | Not run | Pending |
| Repeated wake or unlock notifications | Not run | Not run | Pending |
| Disable monitoring while suspended | Not run | Not run | Pending |
| Quit or restart after unlock | Not run | Not run | Pending |

## System integration

- [ ] Launch at login succeeds from the signed app in `/Applications`.
- [ ] A denied launch-item approval is reported without breaking the app.
- [ ] Renewal reminders remain off until explicitly enabled.
- [ ] Enabling reminders requests notification permission in context.
- [ ] Denied or revoked notification permission turns reminders off without
  affecting tracking or subscription management.
- [ ] An eligible subscription produces generic notification content without
  provider name, price, or currency.
- [ ] Editing, deactivating, deleting, and bulk-deleting subscriptions refresh
  or remove pending reminders.

Defects or evidence:

> Pending

## Data and privacy

- [ ] No sample records appear on first launch.
- [ ] Monitoring remains off until the user approves an app and enables it.
- [ ] Exported data matches the visible sessions and subscriptions.
- [ ] Activity-history, subscription, and all-data deletion confirmations work.
- [ ] Migration from the previous distributed version preserves user data.
- [ ] The archive contains no secrets, debug logs, or development paths.

Defects or evidence:

> Pending

## Performance and energy

- [ ] The repeatable performance benchmark stays within documented guardrails.
- [ ] Instruments Power Profiler is run against this signed candidate during a
  representative idle period and normal app switching.
- [ ] Thermal state, wakeups, sustained energy impact, and test duration are
  recorded below.

| Measurement | Result |
| --- | --- |
| Instruments duration | Pending |
| Thermal state | Pending |
| Wakeups | Pending |
| Sustained energy impact | Pending |
| Trace location | Pending |

## Release decision

- [ ] Every required check above passes or has an explicitly accepted defect.
- [ ] All accepted defects have an owner and follow-up reference.
- [ ] The tested archive hash matches the archive approved for distribution.

Decision: **Pending**

Approved by: Pending

Approval date: Pending

Release notes or issue references: Pending
