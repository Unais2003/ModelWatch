# Settings

## Purpose

Settings provide understandable control over monitoring, startup behavior, and
locally stored data.

## Current implementation

The native Settings scene lets users select macOS application bundles, remove
approved applications, and enable or pause activity monitoring. Monitoring is
off by default, stops automatically when the last approved application is
removed, and displays persistence failures. A first-run privacy explanation
describes the collected and excluded data before directing users to Settings.
“Launch at login” and “Show menu bar status” remain `AppStorage` values that do
not yet control system behavior. The dashboard also contains a separate
placeholder Settings page.

## MVP settings

### Monitoring

- Enable or pause monitoring.
- Select applications approved for tracking.
- Show the current monitoring state.

### Application

- Launch ModelWatch at login using the supported macOS service API.
- Define whether the main dashboard opens at launch.
- Keep menu-bar behavior consistent with the product's operating mode.

### Data and privacy

- Explain what activity fields are stored.
- Show the local-only status of the MVP.
- Delete activity history with confirmation.
- Provide application and data version information useful for support.

### About

- Application name and version
- Minimum supported macOS version
- License and privacy information

## Design direction

Use the native Settings scene as the canonical settings experience. The
dashboard sidebar should open that scene or present the same shared controls;
it should not maintain a second disconnected implementation.

Preferences that invoke system behavior must report registration or permission
failures. Saving a boolean alone is not sufficient evidence that the requested
behavior is active.
