# Local Data Management

## Purpose

ModelWatch gives users direct control over the activity and subscription data
stored on their Mac. These controls are available in the Data tab of Settings.

## Inspection

The Data tab reports the number of stored activity sessions and subscription
records. Counts come from the same local SwiftData stores used by analytics and
subscription management.

## Export

Users can export a UTF-8 JSON file to a location they choose. The export uses a
versioned schema and contains:

- Export schema version and timestamp
- Activity session IDs, application identity, display name, and timestamps
- Subscription IDs, service name, monthly cost, currency, renewal date, and
  active state

The export does not contain prompts, responses, window titles, credentials, or
other content ModelWatch does not collect. Exporting does not transmit data;
the system save panel writes the file to the destination selected by the user.

## Deletion

Users can independently delete activity history, subscription data, or both.
Every destructive operation requires confirmation. Approved application choices
and general preferences are retained.

When monitoring is active, clearing activity history safely closes the current
session, deletes all prior sessions, and starts a fresh session for the approved
frontmost application. This prevents the tracker from retaining a reference to
a deleted record while allowing monitoring to continue.

The dashboard reloads after a deletion. Persistence failures remain visible,
and the Settings data summary is refreshed to show the resulting state.

## Schema evolution

The current JSON `schemaVersion` is `1`. Future export changes must preserve
existing field meanings or increment the schema version. Import is outside the
current MVP and must define conflict and validation behavior before shipping.
