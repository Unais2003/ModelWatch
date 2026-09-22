# Product Vision

## Purpose

ModelWatch is a native macOS utility that helps people understand their use of
AI applications and the recurring costs associated with them.

The product should answer three questions quickly:

1. Which AI tools did I use?
2. How much time did I spend using them?
3. How much do my AI subscriptions cost?

## Target users

- Developers working across several AI-assisted tools
- Students trying to understand study habits
- Researchers comparing tool usage over time
- Freelancers monitoring software expenses
- AI enthusiasts managing several subscriptions

## Product principles

### Native first

ModelWatch should feel like a built-in macOS utility. Prefer SwiftUI, AppKit,
SwiftData, Apple Charts, and established macOS interaction patterns over web UI
conventions or cross-platform abstractions.

### Private by default

Usage and subscription records remain on the user's Mac by default. The MVP
requires no account and sends no activity data to a remote service.

### Trustworthy over impressive

Usage totals must be accurate and explainable. Real empty states are preferable
to fabricated production data, and failures must be visible rather than silently
reported as zero usage.

### Lightweight

Monitoring should have negligible impact on CPU, memory, energy use, and launch
time. The application should avoid polling when macOS events can provide the
same information.

### Focused

The MVP is a local activity and subscription tracker. API billing, token
analytics, forecasting, team dashboards, and cloud sync are later capabilities.

## Desired experience

ModelWatch lives in the menu bar, quietly records activity for user-approved AI
applications, and provides a dashboard for daily, weekly, and monthly review.
Users can pause monitoring, inspect what is stored, manage subscriptions, and
delete local data without creating an account.

## Success criteria

- Activity sessions are captured accurately across application switches, sleep,
  screen lock, quit, and relaunch.
- Users understand what is collected before monitoring begins.
- Dashboard totals match stored sessions for each selected date range.
- Users can manage subscriptions without editing data outside the application.
- The app launches quickly and consumes minimal resources while idle.
- The app supports current Light and Dark appearances and keyboard navigation.

