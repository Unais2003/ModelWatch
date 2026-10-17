# Distribution

## Current status

Local development uses an ad-hoc signed `.app` assembled under `dist/`. The
dedicated [beta release workflow](releasing.md) stages that bundle separately,
applies hardened-runtime Developer ID signing, notarizes and staples it, performs
Gatekeeper validation, and produces a versioned ZIP and SHA-256 checksum. A real
release still requires Apple team credentials and manual release-candidate
verification.

## Beta release requirements

- [x] Stable bundle identifier
- [x] Marketing version and build number
- [x] Application icon and local `.icns` generation
- [x] Complete local `Info.plist` metadata
- [x] Required entitlements reviewed; none are currently needed
- [x] Hardened runtime and Developer ID signing automation
- [x] Apple notarization and stapling automation
- [x] Versioned release archive and checksum
- [x] Documented versioning and rollback process
- [x] Privacy information consistent with shipped behavior
- [ ] Produce and validate a release with Apple team credentials

## Validation checklist

Before distributing a build:

- Run `./script/verify_release_candidate.sh` successfully.
- Build and test using the release toolchain.
- Confirm the minimum supported macOS version.
- Verify first launch on a clean user account.
- Verify Light Mode, Dark Mode, keyboard navigation, and VoiceOver labels.
- Exercise monitoring across app switching, sleep, wake, lock, and restart.
- Verify persistence migration from the previous released version.
- Confirm login-item and notification behavior when enabled and denied.
- Confirm launch-at-login registration from the signed app in `/Applications`;
  development builds may report the service as unavailable.
- Compare launch, idle CPU, memory, and relative power against the documented
  [performance baseline](performance.md).
- Profile the signed release candidate with Instruments Power Profiler.
- Confirm no sample data, secrets, debug logging, or development paths ship.
- Verify code signature and notarization status.

## Packaging direction

The beta retains Swift Package Manager and uses a dedicated scripted release
workflow. This decision and the conditions for reconsidering an Xcode project
are recorded in
[ADR-0002](../architecture/decisions/0002-scripted-developer-id-release.md).

