# Development Setup

## Requirements

- A Mac running macOS 14 or later
- Xcode with the macOS SDK and command-line tools
- Swift 5.9 compatibility or later
- Git

ModelWatch has no third-party package dependencies.

## Build

From the repository root:

```bash
swift build
```

## Test

```bash
swift test
```

The current package may emit concurrency-isolation warnings with newer Swift
toolchains. These should be resolved before adopting Swift 6 language mode.

## Run a local app bundle

```bash
./script/build_and_run.sh
```

The script builds the executable, assembles `dist/ModelWatch.app`, generates its
`.icns` file from the checked-in master icon, applies an ad-hoc local signature,
verifies the bundle, and opens a new instance. It does not terminate an existing
ModelWatch process. Additional modes are available:

```bash
./script/build_and_run.sh build
./script/build_and_run.sh --debug
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --verify
./script/build_and_run.sh --release
./script/build_and_run.sh --qa-light
./script/build_and_run.sh --qa-dark
```

`build` assembles a debug bundle without opening it. `--release` assembles an
optimized bundle without opening it. Both are ad-hoc signed for local integrity;
neither is Developer ID signed or notarized for distribution. `--verify` performs
an isolated launch smoke test with in-memory data and terminates only the process
it started.

The `--qa-light` and `--qa-dark` modes build a release bundle and launch an
isolated, in-memory instance with an app-only appearance override. Quit any
existing ModelWatch process first so the intended instance is unambiguous.
These modes do not change the system appearance, user data, monitoring
preferences, menu-bar preference, or notification authorization. They support
local visual inspection but do not replace testing the signed candidate under
the real system accessibility settings.

## Run the release-candidate preflight

```bash
./script/verify_release_candidate.sh
```

This runs the complete test suite, assembles and validates the release bundle,
and performs an isolated launch smoke test. It does not replace the manual
accessibility, appearance, lifecycle, or signed-build verification matrix.

Prepare the candidate-specific manual validation record after the preflight
passes:

```bash
./script/prepare_release_validation.sh
```

The generated file is placed under ignored `dist/validation/` and is meant to
travel with the exact signed release artifact it documents.

## Measure local performance

```bash
./script/measure_performance.sh
```

This assembles a release app, runs it with isolated in-memory data, and writes a
JSON launch, idle CPU, resident-memory, and relative-power result to the macOS
temporary directory. See the [performance baseline](performance.md) for metric
definitions, environment overrides, and current regression guardrails.

## Validate release configuration

```bash
./script/package_release.sh --validate
```

This validates release metadata and Apple tool availability without requiring
credentials or creating an artifact. Creating a signed and notarized archive is
documented in the [beta release workflow](releasing.md).

Update `CFBundleShortVersionString` and `CFBundleVersion` in
`Resources/Info.plist` when preparing a new version. The About tab reads those
values from the assembled application bundle.

## Repository layout

```text
Sources/ModelWatch/
  App/          Application scenes and dependency composition
  Config/       Application constants
  Models/       Domain and SwiftData models
  Services/     Business behavior and service protocols
  Stores/       Persistence protocols and SwiftData implementations
  Support/      Small shared helpers
  ViewModels/   Observable presentation state
  Views/        SwiftUI presentation
Tests/          Automated tests
docs/           Product and engineering documentation
script/         Local development scripts
```

## Development rules

- Keep changes scoped and preserve established architecture.
- Do not add a dependency when Apple frameworks or existing code are enough.
- Keep business logic outside SwiftUI views.
- Never commit credentials, `.env` files, generated builds, or user data.
- Update relevant documentation alongside behavior changes.
- Run tests and inspect compiler warnings before handing off a change.

Project-specific contributor guardrails are maintained in `AGENTS.md` at the
repository root.

