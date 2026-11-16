# ModelWatch

ModelWatch is a privacy-first macOS menu bar app for understanding how much
time you spend in AI tools. It records activity only for applications you
explicitly approve, keeps the data on your Mac, and presents daily, weekly,
and monthly usage in a native SwiftUI dashboard.

The local-first MVP feature set is implemented. The project is now in beta
validation and requires macOS 14 or later.

## What works today

- Native macOS dashboard and menu bar controls
- Opt-in monitoring for user-selected application bundles
- Automatic session tracking when an approved application becomes active
- Pause and resume controls from the menu bar or Settings
- Local persistence with SwiftData
- Daily, weekly, and monthly usage summaries
- Per-application usage charts and breakdowns
- Subscription creation, editing, activation, and deletion
- Opt-in, privacy-safe local subscription renewal reminders
- Versioned local-data export and confirmed deletion controls
- Launch-at-login and startup preferences
- First-run privacy onboarding
- Loading, empty, failure, and retry states
- Accessible native controls with verified row labels and focus restoration
- Automated coverage for tracking, analytics, subscriptions, preferences, and
  view models

## Privacy

Monitoring is off by default. ModelWatch stores only the following information
for applications you approve:

- Application name
- Bundle identifier
- Session start time
- Session end time

ModelWatch does not read window titles, keystrokes, prompts, files, browser
tabs, or screen contents. The MVP does not require an account and does not
send activity data to a remote service.

See [Data Handling](docs/privacy/data-handling.md) for the full privacy model.

## Requirements

- A Mac running macOS 14 or later
- Xcode with the macOS SDK and command-line tools
- A Swift 5.9-compatible toolchain or later
- Git

ModelWatch has no third-party package dependencies.

## Getting started

Clone the repository, then build and test it from the project root:

```bash
swift build
swift test
```

To create and open a local development app bundle:

```bash
./script/build_and_run.sh
```

The generated app at `dist/ModelWatch.app` is intended for local development;
it is ad-hoc signed, not Developer ID signed or notarized. The script also
supports `build`, `--debug`, `--logs`, `--telemetry`, `--verify`, and
`--release` modes.

## Using ModelWatch

1. Launch ModelWatch and review the privacy onboarding.
2. Open Settings and add one or more macOS applications to the approved list.
3. Enable activity monitoring.
4. Use the menu bar item to check status, pause monitoring, or open the
   dashboard.
5. Review usage for today, this week, or this month in the dashboard.
6. Add recurring AI subscriptions and optional next-renewal dates.
7. Optionally enable privacy-safe renewal reminders in General Settings.

Notification permission is requested only when renewal reminders are enabled.
The notification text is generic and does not include provider names, prices,
or currencies.

## Release validation

Run the complete local release-candidate gate:

```bash
./script/verify_release_candidate.sh
```

This runs the test suite, builds the production app, validates its bundle and
ad-hoc signature, and performs an isolated launch without reading user data or
requesting notification permission.

Create an auditable, commit-specific record for the remaining manual and signed
checks:

```bash
./script/prepare_release_validation.sh
```

The record is written under ignored `dist/validation/`. Complete it against the
exact signed and notarized archive being considered for distribution.

Additional release checks:

```bash
./script/measure_performance.sh
./script/package_release.sh --validate
```

Creating the notarized archive requires a Developer ID Application certificate
and a Keychain-backed `notarytool` profile. See the
[beta release workflow](docs/engineering/releasing.md) for the credential-safe
process.

## Architecture

ModelWatch follows MVVM and uses protocol-driven services and stores so that
business logic remains separate from SwiftUI views.

```text
Sources/ModelWatch/
  App/          App lifecycle and dependency composition
  Config/       Application constants
  Models/       Domain and SwiftData models
  Services/     Tracking, analytics, subscriptions, and reminder behavior
  Stores/       Persistence protocols and implementations
  Support/      Shared helpers
  ViewModels/   Presentation state and actions
  Views/        SwiftUI interface
Tests/          Automated tests
docs/           Product and engineering documentation
script/         Local development scripts
```

The app is built with Swift, SwiftUI, MenuBarExtra, SwiftData, Charts, and
AppKit where native workspace integration is required.

## Roadmap

The remaining beta-validation milestones are:

- Complete manual VoiceOver, keyboard, and appearance verification
- Verify activity tracking across screen lock and unlock
- Validate a signed and notarized beta with Apple team credentials
- Verify signed-candidate energy impact with Instruments Power Profiler

Provider billing integrations, token analytics, budgets, forecasts, sync, and
team dashboards are longer-term opportunities rather than current features.
See the [project roadmap](docs/product/roadmap.md) for details.

## Documentation

The [documentation index](docs/README.md) links to product requirements,
architecture decisions, feature specifications, privacy guidance, development
setup, testing, distribution, and the
[release validation template](docs/engineering/release-validation-template.md).

## Project status

ModelWatch is feature-complete for its local-first MVP and is preparing for its
first signed beta. Automated and local preflight gates pass; cross-version
lifecycle testing, the complete manual accessibility and appearance matrix,
Developer ID notarization, and signed-candidate Instruments profiling remain
required before distribution.
