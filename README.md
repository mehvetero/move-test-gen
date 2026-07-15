# move-test-gen

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

- **Line-based parsing** — the checker reads one line at a time, so multi-line `assert!(...)` or multi-line attributes are not seen. Keep asserts on a single line for accurate coverage.
- **String literals** — `//` inside a string literal (e.g., `b"https://..."`) is treated as a comment boundary and may cause that line to be skipped. In practice this rarely affects error-constant extraction.
- **Module-qualified aborts** — `abort 0x2::module::ECode` currently captures `0x2` instead of `ECode`. Use unqualified abort constants for accurate pairing.

## Pairs with

- Security audit agents (feed findings → generate regression tests)
- `sui move test --coverage` (fill gaps identified by coverage reports)
- CI pipelines (generate tests as part of PR review)

## References

See [references/patterns.md](references/patterns.md) for the full catalog of Move-specific edge cases with code templates and rationale.
