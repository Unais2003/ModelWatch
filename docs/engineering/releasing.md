# Beta Release Workflow

ModelWatch beta releases use Developer ID distribution outside the Mac App
Store. The workflow signs with the hardened runtime, submits the app to Apple's
notary service, staples the accepted ticket, runs local Gatekeeper validation,
and creates a versioned ZIP with a SHA-256 checksum.

## Prerequisites

- A clean Git checkout at the intended release commit
- Xcode command-line tools
- Membership in the Apple Developer Program
- A `Developer ID Application` certificate and private key installed in the
  login Keychain
- A `notarytool` credential profile stored in Keychain

Create the notarization profile once using credentials issued for the Apple
developer team:

```bash
xcrun notarytool store-credentials "modelwatch-notary" \
  --apple-id "APPLE_ID" \
  --team-id "TEAM_ID"
```

`notarytool` securely prompts for the app-specific password when `--password` is
omitted, keeping it out of shell history. App Store Connect API-key credentials
are also supported and are preferable for managed release automation. Never
place credentials, certificates, private keys, or passwords in this repository.

## Validate project configuration

This check does not require Apple credentials and does not build or modify an
artifact:

```bash
./script/package_release.sh --validate
```

It validates the source metadata, version format, required assets, and Apple
tool availability.

## Create a notarized beta

Set the exact Keychain identity and the name of the stored notarization profile
for the command invocation:

```bash
MODELWATCH_SIGNING_IDENTITY="Developer ID Application: ORGANIZATION (TEAM_ID)" \
MODELWATCH_NOTARY_PROFILE="modelwatch-notary" \
./script/package_release.sh
```

The script intentionally has no unsigned or skip-notarization release mode. It
performs the following gates before publishing an archive:

1. Validate version metadata and required tools.
2. Confirm the requested Developer ID identity exists in Keychain.
3. Refuse a dirty Git checkout or an existing archive with the same version.
4. Build a release application and copy it into an isolated staging directory.
5. Sign with a trusted timestamp and the hardened runtime.
6. Submit a temporary ZIP to Apple and wait for acceptance.
7. Staple and validate the notarization ticket.
8. Verify the signature and run a Gatekeeper assessment.
9. Write the final ZIP and SHA-256 file under `dist/releases/`.

For version `0.1.0` build `1`, the output names are:

```text
dist/releases/ModelWatch-0.1.0-1.zip
dist/releases/ModelWatch-0.1.0-1.zip.sha256
```

## Release verification

Before sharing the archive:

- Compare the SHA-256 value with the generated checksum file.
- Extract the ZIP on a separate Mac or clean user account.
- Confirm Gatekeeper accepts the application without an override.
- Complete the manual accessibility and appearance matrix.
- Verify monitoring across app switching, lock, sleep, wake, and restart.
- Run Instruments Power Profiler against the signed candidate.
- Record the release commit, notarization submission identifier, checksum, and
  manual verification result in the release notes.

## Versioning and rollback

Update both `CFBundleShortVersionString` and the monotonically increasing
`CFBundleVersion` in `Resources/Info.plist` before creating a new release.

ModelWatch does not yet include an automatic updater. Retain every shipped,
notarized archive and checksum in controlled release storage. A rollback is a
re-distribution of the last accepted archive; do not rebuild an old version,
because its binary and checksum would differ. User data remains local and must
not be removed as part of rollback.
