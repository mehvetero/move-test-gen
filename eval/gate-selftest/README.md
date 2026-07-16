# gate-selftest — the scorer's own regression suite

The eval lab trusts `scripts/check-coverage.mjs` as its judge. This folder is why
that trust is earned: every parser trap found during the five review rounds
(2026-07-14/15) is pinned here as a case with expected output.

Run from the repo root:

```bash
node eval/gate-selftest/run.mjs
```

All green = the scorer still catches everything it ever caught. Run it before
trusting any gate change, and in CI.

| Case | Pins |
|---|---|
| 01-gauntlet | 11 assert/abort sites through every parser trap: comma-in-condition, trailing comments, `//` and `)` inside string literals, three multiline styles, inline-comment abort. One true unpaired (E_LOCKED), exit 1. |
| 02-wildcard-no-inflate | A bare `#[expected_failure]` is reported as unscoped and does NOT inflate coverage. |
| 03-disabled-test-ignored | A commented-out `#[expected_failure(...)]` attribute does not count as coverage. |
| 04-shared-code-warning | Two functions sharing one abort code → the shared-code warning fires. |
| 05-known-tail-one-line | KNOWN LIMITATION pinned on purpose: two asserts on one line — the greedy regex sees only the last. If this case ever fails by finding both, the limitation was fixed: update the README and re-pin. |

What this does **not** prove: Layer 2 (`--mutate`) behavior — that path needs a
real `sui` CLI and is field-verified separately (see the review thread record).
