# ModelWatch Documentation

This directory is the source of truth for ModelWatch product and engineering
documentation. The files use standard Markdown so they remain readable in
GitHub, editors, and optional local knowledge tools such as Obsidian.

## Product

- [Vision](product/vision.md)
- [Product requirements](product/requirements.md)
- [Roadmap](product/roadmap.md)

## Architecture

- [Architecture overview](architecture/overview.md)
- [Data model](architecture/data-model.md)
- [Activity-tracking design](architecture/activity-tracking.md)
- [Architecture decision records](architecture/decisions/README.md)

## Features

- [Analytics](features/analytics.md)
- [Subscriptions](features/subscriptions.md)
- [Settings](features/settings.md)

## Privacy

- [Data handling](privacy/data-handling.md)
- [macOS permissions](privacy/macos-permissions.md)

## Engineering

- [Development setup](engineering/development-setup.md)
- [Testing](engineering/testing.md)
- [Distribution](engineering/distribution.md)

## Documentation conventions

- Keep durable product decisions in this directory rather than in task notes.
- Update the relevant document in the same change as its implementation.
- Prefer relative Markdown links so documentation works outside a specific app.
- Record consequential, hard-to-reverse architecture choices as an ADR.
- Describe planned behavior as planned; do not present incomplete work as shipped.

