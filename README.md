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

## Coverage targets

The skill aims for:

| Function type | Minimum tests |
|--------------|---------------|
| Arithmetic (multiply/divide) | 5 |
| Access-controlled | 3 |
| State-transition | 4 |
| Economic (fees/rates) | 6 |

## Pairs with

- Security audit agents (feed findings → generate regression tests)
- `sui move test --coverage` (fill gaps identified by coverage reports)
- CI pipelines (generate tests as part of PR review)

## References

See [references/patterns.md](references/patterns.md) for the full catalog of Move-specific edge cases with code templates and rationale.
