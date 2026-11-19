# Iteration <NNN>: <sanitized title>

- Date/time: `<timestamp-with-timezone>`
- Owner: `<role-or-redacted-id>`
- Baseline config/run: `<config-id>` / `<run-id>`
- Candidate config/run: `<config-id>` / `<run-id>`
- Decision: `<keep/drop/pending>`

## Hypothesis

What bottleneck should this change affect, and why?

## Change

- Variable or explicit bundle: `<name>`
- Baseline value: `<value>`
- Candidate value: `<value>`
- Fixed conditions: `<runtime, hardware, workload, SLO>`

## Test level and gates

- Level: `<smoke/anchor/short/boundary/long/matrix>`
- Correctness: `<pass/fail/not-run + reason>`
- Keep-up: `<pass/fail>`
- SLO: `<pass/fail>`
- Exceptions: `<none or documented reason>`

## Evidence

Link to raw run directories and a compact result table. Do not paste sensitive raw logs.

## Interpretation

Separate observed facts from the explanation. State uncertainty and possible confounders.

## Decision and next step

Why keep, drop or defer the change? What exact test would resolve a pending decision?
