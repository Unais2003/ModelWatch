# Activity Lifecycle Verification

ModelWatch closes active usage sessions when macOS sleeps or the current login
session resigns active, and resumes only after every active suspension reason has
cleared. Sleep and screen lock can overlap and may arrive in different orders,
so neither wake nor unlock alone is sufficient when the other condition remains.

## Automated coverage

`WorkspaceActivityTrackingServiceTests` verifies that ModelWatch:

- closes an active session on sleep and resumes after wake;
- closes an active session when the login session resigns active and resumes
  after it becomes active;
- ignores application activation events while locked or asleep;
- waits for both wake and session activation when sleep and lock overlap;
- treats duplicate lifecycle notifications idempotently; and
- does not restart tracking when activity history is deleted while suspended.

Run the coverage with the complete suite:

```bash
swift test
```

These tests validate the state machine with deterministic events and timestamps.
They cannot prove which notifications a particular macOS release delivers.

## Manual supported-version matrix

Exercise this matrix on the minimum supported macOS release and the latest
supported release before distributing a beta. Use a signed candidate and a
non-sensitive test application approved in ModelWatch.

| Scenario | Expected result |
| --- | --- |
| Lock while the approved app is frontmost | The active session ends at lock and no locked time is counted. |
| Unlock to the same approved app | A new session starts; the pre-lock session is not extended. |
| Unlock to an unapproved app | Monitoring is active without an application session. |
| Sleep and wake without locking | The session ends before sleep and resumes after wake. |
| Sleep while locked, then wake to the lock screen | No session starts until the login session becomes active. |
| Receive repeated wake or unlock notifications | At most one new session starts. |
| Disable monitoring while suspended | Unlocking does not resume monitoring. |
| Quit or restart after unlock | No unfinished session is counted as background usage. |

For every run, record:

- ModelWatch version and build number
- macOS version and hardware model
- scenario and event order when observable
- session start/end times from the local data export
- pass/fail result and a scoped defect reference when applicable

Do not automate locking, sleeping, or changing security settings in the release
script. Those operations affect the user's macOS session and require deliberate
manual control. Do not mark the roadmap item complete until the matrix passes on
the supported release range.
