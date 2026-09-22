# Distribution

## Current status

The repository contains a development script that assembles the Swift Package
Manager executable into a minimal `.app` directory under `dist/`. This is useful
for local testing but is not a production distribution pipeline.

## Beta release requirements

- Stable bundle identifier
- Marketing version and build number
- Application icon and asset catalog
- Complete `Info.plist` metadata
- Required entitlements only
- Hardened runtime configuration
- Developer ID signing
- Apple notarization and stapling
- Reproducible release archive
- Documented update and rollback process
- Privacy information consistent with shipped behavior

## Validation checklist

Before distributing a build:

- Build and test using the release toolchain.
- Confirm the minimum supported macOS version.
- Verify first launch on a clean user account.
- Verify Light Mode, Dark Mode, keyboard navigation, and VoiceOver labels.
- Exercise monitoring across app switching, sleep, wake, lock, and restart.
- Verify persistence migration from the previous released version.
- Confirm login-item and notification behavior when enabled and denied.
- Measure idle CPU, memory, and energy impact.
- Confirm no sample data, secrets, debug logging, or development paths ship.
- Verify code signature and notarization status.

## Packaging direction

Before beta distribution, prefer an Xcode application project or another
explicit Apple-platform release configuration capable of managing assets,
entitlements, signing, archives, and version metadata. Keep Swift packages for
modular code only when their separation provides clear value.

Choosing a final packaging and update mechanism is a release architecture
decision and should be recorded as an ADR.

