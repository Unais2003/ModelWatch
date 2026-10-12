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
