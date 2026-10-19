# macOS Permissions

## Principle

Request the smallest set of permissions necessary, at the moment a user enables
the related feature. Explain the benefit before showing a system prompt.

## Activity tracking

The MVP design observes which application becomes frontmost through macOS
workspace lifecycle events. It does not require reading screen content,
keystrokes, or window text.

Implementation must verify permission behavior on every supported macOS
version. If the selected APIs do not require a protected permission, the app
must not request Accessibility or Screen Recording proactively.

The current implementation uses `NSWorkspace` application activation, sleep,
wake, and session lifecycle notifications. It does not request Accessibility or
Screen Recording permission.

## Accessibility

Accessibility permission is not part of the MVP requirement. It would become
relevant only if a future feature inspected other applications' UI elements.
Such a feature requires separate product justification and privacy review.

## Screen Recording

Screen Recording permission is not part of the MVP requirement. ModelWatch
must not capture screen pixels or infer usage from screenshots.

## Notifications

Notification authorization is requested only after the user enables renewal
reminders in General Settings. Declining or later revoking authorization turns
the reminder preference off and must not affect tracking, subscription
management, or dashboard functionality.

Pending reminders are scheduled and stored by macOS. Their content is generic:
ModelWatch does not put provider names, prices, or currencies in notification
titles or bodies. Disabling reminders removes ModelWatch's pending renewal
requests.

## Launch at login

Launch-at-login registration is a user preference rather than protected data.
Use the current macOS service-management API and show whether registration
succeeded.

## Distribution implications

Before release, document and verify required entitlements, sandbox behavior,
usage descriptions, signing, and notarization. Add permissions only for shipped
features and remove obsolete declarations.
