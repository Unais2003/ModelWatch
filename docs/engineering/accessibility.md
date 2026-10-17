# Accessibility and Appearance

## Product baseline

ModelWatch uses native SwiftUI controls, semantic system colors, and standard
macOS keyboard behavior. Information must remain understandable without color,
and primary workflows must be usable with VoiceOver and a keyboard.

## Implemented safeguards

- Dashboard headers and metric cards adapt when horizontal space is limited.
- Subscription totals use an adaptive grid instead of a fixed row.
- Settings and subscription-editor windows can grow beyond their ideal size.
- Summary cards and charts expose concise VoiceOver labels and values.
- Decorative symbols are hidden from VoiceOver where adjacent text carries the
  same meaning.
- Errors and successful operations pair text with semantic symbols instead of
  relying on red or green alone.
- Destructive and row-specific actions include descriptive labels.
- Onboarding and editor actions use standard cancel and default keyboard
  shortcuts.
- Surfaces use semantic materials and foreground styles so they follow Light
  and Dark Mode without separate color constants.

## Manual verification matrix

Complete this matrix on a release candidate before beta distribution:

- [ ] Navigate onboarding, dashboard, subscriptions, Settings, and deletion
  confirmations using only the keyboard.
- [ ] Confirm VoiceOver reading order, control names, values, and action menus.
- [ ] Check the dashboard, sheets, menu-bar menu, and Settings in Light Mode.
- [ ] Repeat the appearance check in Dark Mode.
- [ ] Verify layouts with the largest supported accessibility text size.
- [ ] Verify Increase Contrast and Reduce Transparency do not hide state or
  actions.
- [ ] Confirm focus returns to a predictable control after sheets and alerts
  close.

Record defects as scoped issues. Do not mark the roadmap verification item
complete until every workflow above has been exercised on a signed build.

## Automated preflight coverage

Run the release-candidate preflight before the manual matrix:

```bash
./script/verify_release_candidate.sh
```

The preflight runs all tests, builds and validates the release bundle, verifies
its signature structure, and launches it with isolated in-memory data. The
isolated launch skips onboarding and disables the menu-bar item only for the
smoke test; it does not read or change the user's ModelWatch data or preferences.

The live accessibility-tree inspection on October 17, 2026 confirmed semantic
names and values for the dashboard range control, summary cards, empty states,
subscription actions, and every subscription-editor field. Editor and deletion
flows explicitly restore keyboard focus to a predictable available control.

Automated inspection does not validate spoken phrasing, visual contrast,
alternate system appearances, accessibility display settings, or subjective
reading order. Those checks remain manual and must be performed on the signed
release candidate.
