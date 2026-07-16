# move-test-gen

![gate-selftest](https://github.com/mehvetero/move-test-gen/actions/workflows/gate.yml/badge.svg)

An [Agent Skill](https://github.com/agentskills/agentskills) that generates edge-case test suites for Sui Move functions.

## What it does

Give it a Move module and it produces `#[test]` and `#[expected_failure]` functions covering:

- **Boundary values** — zero, one, max u64/u128, empty collections
- **Arithmetic edges** — multiplication overflow, division by zero, rounding direction
- **Access control** — missing capability, wrong capability type, post-transfer use
- **State machine** — wrong call order, double execution, unresolved hot potato
- **Economic** — fee evasion via dust amounts, first-depositor share inflation, rounding profit

Output is a `.move` test file targeting `sui move test`. The example in `examples/` includes a complete package with `Move.toml`, source module with `#[test_only]` helpers, and generated tests — run `cd examples && sui move test` to verify.

## Usage

Install the skill in your Claude Code environment:

```
skills/
└── move-test-gen/
    ├── SKILL.md
    ├── scripts/
    │   └── check-coverage.mjs
    └── references/
        └── patterns.md
```

Then ask Claude Code:

```
Generate edge-case tests for sources/vault.move
```

or:

```
The audit found a rounding issue in calculate_shares().
Generate regression tests that fail without the fix.
```

## Coverage checker

After generating tests, verify nothing was missed:

```bash
node scripts/check-coverage.mjs ./sources ./tests
```

This scans every `assert!` and `abort` in your source modules, every `#[expected_failure]` in your tests, and reports unpaired asserts — abort paths that have no corresponding failure test.

For stronger verification, add `--mutate`:

```bash
node scripts/check-coverage.mjs ./sources ./tests --mutate
```

Mutation testing injects deterministic bugs (flip a comparison, drop an assert) and checks whether your test suite catches them. If a mutation survives, the test that should have caught it is too weak.

By default, `--mutate` applies one mutation per operator per line. All 7 operators (flip `<`/`>`/`<=`/`>=`/`==`/`!=`, drop `assert!`) run exhaustively — every matchable line is tested.

## What this proves — and what it doesn't

The coverage checker is a deterministic floor: it proves every assert has a matching `#[expected_failure]` test, that generated tests compile, and (with `--mutate`) that the suite actually catches injected bugs. It does **not** prove a test asserts the right thing — that judgment stays with the reviewer.

> "Never let the floor pretend to be the ceiling."
> — [HetCreep](https://github.com/TheColliery/CoalWash), who framed this better than I could.

Generation can be probabilistic; the gate never is.

## Coverage targets

The skill aims for:

| Function type | Minimum tests |
|--------------|---------------|
| Arithmetic (multiply/divide) | 5 |
| Access-controlled | 3 |
| State-transition | 4 |
| Economic (fees/rates) | 6 |

## Known limitations

The checker is a regex-based parser, not a compiler. It handles the common patterns — including multi-line asserts, module-qualified aborts, and string literals with `//` — but edge cases exist:

- **Multi-line attributes** — `#[expected_failure(...)]` split across lines is not detected. Keep attributes on a single line.
- **Mutation testing** requires `sui` CLI installed locally. Layer 1 (assert pairing) works anywhere.
- **Abort code pairing** is by error constant name, not by which function throws it. If two functions use the same `EZeroAmount`, one `#[expected_failure]` test covers both — the checker warns about this but does not flag it as unpaired.

## Eval lab

The skill is measured, not trusted: `eval/` holds a scenario lab that fires frozen
prompt templates at bait modules and scores every round with the gate — retirement
by saturation, dated records, figures never edited by hand. Two campaigns closed
so far: 53/53 mutants across six scenarios, then the survivor path — the gate
confessing what it can't decide. Full records: [eval/RESULTS.md](eval/RESULTS.md).

The lab's methodology — the retirement protocol, frozen templates, and the honesty-
channel assignment — is borrowed, with thanks, from
[HetCreep / TheColliery](https://github.com/TheColliery). Full lineage in the record.

## Pairs with

- Security audit agents (feed findings → generate regression tests)
- `sui move test --coverage` (fill gaps identified by coverage reports)
- CI pipelines (generate tests as part of PR review)

## References

See [references/patterns.md](references/patterns.md) for the full catalog of Move-specific edge cases with code templates and rationale.
