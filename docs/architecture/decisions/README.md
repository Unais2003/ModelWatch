# Architecture Decision Records

Architecture decision records (ADRs) capture consequential technical choices
that future contributors need to understand. They complement code and should be
short enough to review with the change they describe.

## Records

- [ADR-0001: Observe frontmost applications with NSWorkspace](0001-observe-frontmost-app-with-nsworkspace.md)

## When to add an ADR

Create an ADR when a decision:

- Changes persistence or migration strategy
- Introduces a dependency or external service
- Changes actor or concurrency ownership
- Expands collected data or required macOS permissions
- Establishes synchronization, authentication, or encryption behavior
- Is expensive or risky to reverse

Small implementation details do not require ADRs.

## Naming

Use sequential names:

```text
0001-short-decision-title.md
0002-next-decision.md
```

## Template

```markdown
# ADR-NNNN: Decision title

## Status

Proposed | Accepted | Superseded

## Context

What problem or constraint requires a decision?

## Decision

What was selected?

## Consequences

What becomes easier, harder, or constrained?

## Alternatives considered

What credible alternatives were rejected, and why?
```

When an ADR is replaced, preserve it and link to the superseding record.
