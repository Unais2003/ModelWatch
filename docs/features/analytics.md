# Analytics

## Purpose

Analytics turns stored activity sessions into understandable daily, weekly,
and monthly summaries.

## Current implementation

The dashboard can fetch sessions from the start of the selected calendar range,
sum completed positive durations, group them by application name, and render a
bar chart. The live application starts without demonstration sessions because
real activity monitoring is not implemented yet.

## Required MVP behavior

- Calculate an explicit start and exclusive end for each reporting range.
- Include only the portion of each session overlapping that range.
- Use the current time as the temporary end of an active session.
- Group applications by bundle identifier, retaining a suitable display name.
- Sort the application breakdown by descending duration.
- Count only applications with a positive duration in the range.
- Refresh after tracking or stored data changes.

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
- Invalid negative-duration sessions must not reduce totals and should be
  surfaced through diagnostics.

## Future considerations

Historical trends, comparisons, filters, export, and cost-per-hour analysis are
outside the first analytics milestone. They should build on the same tested
range-intersection rules.
