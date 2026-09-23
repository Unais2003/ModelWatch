# ModelWatch

ModelWatch is a privacy-first macOS menu bar app for understanding how much
time you spend in AI tools. It records activity only for applications you
explicitly approve, keeps the data on your Mac, and presents daily, weekly,
and monthly usage in a native SwiftUI dashboard.

The project is currently in active MVP development and requires macOS 14 or
later.

## What works today

- Native macOS dashboard and menu bar controls
- Opt-in monitoring for user-selected application bundles
- Automatic session tracking when an approved application becomes active
- Pause and resume controls from the menu bar or Settings
- Local persistence with SwiftData
- Daily, weekly, and monthly usage summaries
- Per-application usage charts and breakdowns
- First-run privacy onboarding
- Loading, empty, failure, and retry states
- Automated coverage for tracking, analytics, preferences, and view models

Subscription records can be displayed from the local data store, but the user
interface for adding, editing, deactivating, and deleting them is still
planned.

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
it is not signed or notarized. The script also supports `--debug`, `--logs`,
`--telemetry`, and `--verify` modes.

## Using ModelWatch

1. Launch ModelWatch and review the privacy onboarding.
2. Open Settings and add one or more macOS applications to the approved list.
3. Enable activity monitoring.
4. Use the menu bar item to check status, pause monitoring, or open the
   dashboard.
5. Review usage for today, this week, or this month in the dashboard.

## Architecture

ModelWatch follows MVVM and uses protocol-driven services and stores so that
business logic remains separate from SwiftUI views.

```text
Sources/ModelWatch/
  App/          App lifecycle and dependency composition
  Config/       Application constants
  Models/       Domain and SwiftData models
  Services/     Activity tracking and analytics behavior
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

The next MVP milestones are:

- Complete edge-case validation for analytics ranges
- Add subscription creation and management
- Implement launch-at-login and remaining settings behavior
- Add activity-data inspection, export, and deletion controls
- Prepare signing, notarization, and beta distribution

Provider billing integrations, token analytics, budgets, forecasts, sync, and
team dashboards are longer-term opportunities rather than current features.
See the [project roadmap](docs/product/roadmap.md) for details.

## Documentation

The [documentation index](docs/README.md) links to product requirements,
architecture decisions, feature specifications, privacy guidance, development
setup, testing, and distribution notes.

## Project status

ModelWatch is an early-stage project under active development. APIs, storage
models, and interface details may change before the first beta release.
