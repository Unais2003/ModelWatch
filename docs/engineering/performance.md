# Performance Baseline

ModelWatch includes a repeatable local benchmark for launch readiness, idle CPU,
resident memory, and a relative power indicator. The benchmark uses a release
build and an isolated, in-memory data store, so it does not read or modify the
user's ModelWatch history or monitoring preferences.

## Run the benchmark

From the repository root:

```bash
./script/measure_performance.sh
```

The command writes a versioned JSON result to the macOS temporary directory and
prints both the path and result. Pass a different new path as the first argument
when retaining multiple runs:

```bash
./script/measure_performance.sh /tmp/ModelWatch-performance-run.json
```

The script refuses to overwrite an existing result. Its sample window can be
adjusted with positive integer environment variables:

- `MODELWATCH_PERF_WARMUP_SECONDS` (default: `5`)
- `MODELWATCH_PERF_SAMPLE_COUNT` (default: `10`)
- `MODELWATCH_PERF_SAMPLE_INTERVAL_SECONDS` (default: `1`)

## Metric definitions

- **Launch ready:** elapsed time from `ModelWatchApp` initialization until
  `applicationDidFinishLaunching`. This captures application dependency setup
  and launch work, but not process creation or dynamic-loader time.
- **Idle CPU:** average process CPU after the warm-up interval. The invalid first
  `top` sample is discarded, as required by the macOS `top` contract.
- **Resident memory:** average and peak resident memory during the same sample
  window.
- **Relative power:** the process `POWER` score reported by macOS `top`. This is
  useful for detecting local regressions, but it is not energy in joules and is
  not comparable across different hardware.

The benchmark launches with monitoring disabled and does not request notification
permission. Keep the machine on AC power, close unrelated high-load work, and use
at least three runs when comparing changes.

## Initial baseline

Recorded on October 14, 2026 using ModelWatch 0.1.0 (build 1), a release build,
macOS 26.5, and a `MacBookAir10,1`. Values are the median of three complete runs;
ranges show observed run-to-run variation.

| Metric | Median | Observed range |
| --- | ---: | ---: |
| Launch ready | 331 ms | 319–596 ms |
| Idle CPU | 0.93% | 0.81–1.09% |
| Average resident memory | 27.6 MB | 25.0–30.9 MB |
| Peak resident memory | 45 MB | 45–46 MB |
| Relative power score | 0.93 | 0.81–1.10 |

These initial regression guardrails allow normal measurement noise while keeping
the menu bar utility lightweight:

- Median launch readiness at or below 750 ms across three runs
- Median idle CPU at or below 1.5%
- Peak resident memory at or below 75 MB
- Median relative power score at or below 1.5 on the baseline hardware

Treat a threshold breach as an investigation trigger, not an automatic release
failure. Re-establish the baseline when the hardware, operating system, or
measurement method changes.

## Release verification

Before distributing a signed beta, profile the signed release candidate with
Instruments' Power Profiler over a longer representative idle period and during
normal app switching. Record thermal state, wakeups, and sustained energy impact.
The lightweight script is intended for repeatable development checks; it does not
replace Instruments or real-device usage validation.
