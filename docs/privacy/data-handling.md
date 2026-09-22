# Data Handling

## Privacy posture

ModelWatch is local-first. The MVP does not require an account, cloud service,
remote analytics, or advertising SDK.

## Data collected by the MVP

For user-approved applications, ModelWatch may store:

- Application bundle identifier
- Application display name
- Session start time
- Session end time

For subscriptions entered by the user, ModelWatch stores:

- Service or plan name
- Monthly cost and currency
- Optional renewal date
- Active status

Preferences include monitoring state, approved applications, startup behavior,
and display choices.

## Data explicitly not collected

The MVP must not collect:

- Keystrokes or clipboard contents
- Window titles or document names
- Screenshots or screen recordings
- Browser history, URLs, or tab contents
- Prompts, responses, source code, or chat content
- Authentication tokens or provider credentials
- Contacts, location, or unrelated application activity

## Storage and transmission

- Activity and subscription data remain in local SwiftData storage.
- Preferences remain in local application preferences.
- No collected activity is transmitted by default.
- Operational logs must not include session histories or sensitive content.

## User control

Before monitoring begins, onboarding should explain the collection scope. Users
must be able to pause monitoring, change the approved application list, inspect
the categories of stored data, and delete activity history.

## Demonstration data

Random sample data must not be inserted into a normal production data store.
Deterministic fixtures may be used in previews, tests, screenshots, or a clearly
identified demo mode.

## Future integrations

Provider APIs, synchronization, telemetry, or team features require a new
privacy review. Documentation must specify data categories, destination,
retention, credentials, opt-in behavior, and deletion before implementation.

