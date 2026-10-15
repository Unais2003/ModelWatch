# ADR-0002: Use a scripted Developer ID release workflow for beta

## Status

Accepted

## Context

ModelWatch is currently a single native Swift executable built with Swift
Package Manager. Beta distribution outside the Mac App Store requires a proper
application bundle, hardened-runtime signing with a Developer ID Application
certificate, Apple notarization, stapling, and a verifiable archive.

Migrating to an Xcode application project would add project-file maintenance
before the beta needs capabilities that Swift Package Manager cannot express.

## Decision

Keep Swift Package Manager as the build definition for the beta and use a
reviewable shell workflow to assemble, sign, notarize, staple, assess, archive,
and checksum the application.

Signing identities remain in the macOS Keychain. Notarization credentials are
referenced through a named `notarytool` Keychain profile. No certificate,
password, private key, or App Store Connect credential may be stored in the
repository or passed through a committed configuration file.

The release workflow requires a clean Git checkout and refuses to overwrite an
existing versioned archive.

## Consequences

- Local development continues to use the existing ad-hoc signed bundle.
- Authorized maintainers can create consistent notarized beta archives without
  changing source or embedding credentials.
- Release automation remains macOS-specific and requires Apple command-line
  tools plus external team credentials.
- The workflow does not provide Mac App Store submission, automatic updates, or
  Xcode archive management.
- An Xcode project should be reconsidered if the app adopts capabilities,
  extensions, App Store distribution, or release requirements that are awkward
  to maintain in the scripted bundle.

## Alternatives considered

- An Xcode application project was deferred because the current bundle has one
  executable and no extension targets or special entitlements.
- Ad-hoc signing was rejected for distribution because it does not establish a
  trusted developer identity or support notarization.
- Storing signing or notarization secrets in environment files was rejected to
  avoid credential leakage and repository-specific secret management.
