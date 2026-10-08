# Analytics

## Purpose

Analytics turns stored activity sessions into understandable daily, weekly,
and monthly summaries.

## Current implementation

The dashboard calculates a single consistent analytics snapshot for the current
day, week, or month. It queries every session that overlaps the selected
calendar interval, clips each contribution to the interval and current time,
and includes the elapsed part of the active session.

Application totals are grouped by bundle identifier so display-name changes do
not split one application into multiple rows. The most recent display name is
retained, positive totals are sorted by descending duration, and ties are
ordered by name. The summary and chart use the same snapshot, avoiding totals
that disagree because they were loaded at different times.

The dashboard reloads after the tracking service creates, closes, or recovers a
session. While an approved application remains active, it refreshes once per
minute so the visible elapsed duration stays current.

## Required MVP behavior

- [x] Calculate an explicit start and exclusive end for each reporting range.
- [x] Include only the portion of each session overlapping that range.
- [x] Use the current time as the temporary end of an active session.
- [x] Group applications by bundle identifier, retaining a suitable display name.
- [x] Sort the application breakdown by descending duration.
- [x] Count only applications with a positive duration in the range.
- [x] Refresh after tracking changes and while a session is active.

## Presentation states

The dashboard must distinguish:

- Loading: a request is in progress.
- Loaded: summary and breakdown are available.
- Empty: the request succeeded but found no usage.
- Failed: data could not be loaded, with a retry action.

Changing ranges should cancel or supersede the previous load. A slower earlier
request must never replace the result for the currently selected range.

## Time semantics

- “Today” uses the user's current calendar and time zone.
- “This Week” follows the user's calendar week definition.
- “This Month” begins at the user's calendar month boundary.
- Daylight-saving transitions must use calendar boundaries, not fixed numbers
  of seconds.
- Invalid or negative-duration sessions are ignored so they cannot reduce
  totals. A dedicated user-facing diagnostics surface is deferred.

## Future considerations

Historical trends, comparisons, filters, export, mutation-driven refreshes from
future data-management screens, diagnostics, and cost-per-hour analysis are
outside this milestone. They should build on the same tested range-intersection
rules.
