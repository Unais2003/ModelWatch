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

The script stops an existing `ModelWatch` process, builds the executable,
replaces `dist/ModelWatch.app`, and opens it. Additional modes are available:

```bash
./script/build_and_run.sh --debug
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --verify
```

The generated bundle is intended for local development. It is not a signed or
notarized release artifact.

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

