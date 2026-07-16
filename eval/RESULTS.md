# move-test-gen eval lab — Campaign 1 digest

<!-- version-frozen: figures below are filled from eval/results/*/rounds.json (dated records).
     Never edit a figure without a matching record. -->

**Measured:** 2026-07-16 · repo state through `f5e0909` · gate: `scripts/check-coverage.mjs` v1.0.1 (its own regression suite `eval/gate-selftest` at 5/5 green, enforced in CI) · engine: agent VM · generator model: `GPT-5.5` · `sui 1.74.1-8fc60f1fa966` · framework pin `mainnet-v1.74.1` · prompts: frozen templates — v1.0 (scenario 00 round 1 only), v1.1 with scenario isolation (all later rounds).

> **TL;DR:** the generation-side campaign is **CLOSED — 6 scenarios × 3 rounds = 18 rounds, every scenario retired on the 2-consecutive-dry + varied-angle protocol.** Cumulative gate verdicts: **53/53 mutants killed, zero survivors, zero unpaired asserts, every round.** That includes scenario 05, which was engineered to *force* a survivor (two mutants on a bool helper killable only by functional truth-table tests, never by `expected_failure`) — the skill wrote the functional tests unprompted and swept it. Scenario 00 round 1 is tagged **may-be-contaminated** (the answer-key suite was in the generation context under template v1.0); round 2 under v1.1 isolation reproduced the identical score, resolving the ambiguity toward capability. Figures are model- and version-bound to this date and this machine.

## Campaign totals

| # | Scenario | Trap class | Rounds (main/main/varied) | Covered | Mutants | Verdict |
|---|---|---|---|---|---|---|
| 00 | vault (calibration — the skill's own example module) | none; baseline | 3 | 7/7 every round | **14/14** every round | RETIRED † |
| 01 | shared-abort | one error code (`ENotPositive`) shared by 3 functions — does the skill test per SITE or per code | 3 | 5/5 | **10/10** | RETIRED |
| 02 | multi-guard | 5 order-dependent guards in one function — can it stage state to reach guard *k* | 3 | 5/5 | **9/9** | RETIRED |
| 03 | arith-corner | u128 promotion, `/10_000` truncation, exact `MAX` boundaries | 3 | 3/3 | **6/6** | RETIRED |
| 04 | cap-access | capability check repeated on 3 privileged paths + a forgeable wrong-cap helper | 3 | 5/5 | **9/9** | RETIRED |
| 05 | vacuous-bait | bool helper whose two comparison mutants are killable **only** by functional tests | 3 | 2/2 | **5/5** | RETIRED |

† Round 1 ran under template v1.0 with `examples/tests` present in the generation context (open-book condition). The output shared 0/18 test names with the answer key; the figure stands per the figures-never-edited rule, tagged may-be-contaminated. Round 2 (template v1.1, scenario-isolated) reproduced 7/7 + 14/14 — the clean control.

## Protocol

- **Findings** = unpaired asserts ∪ surviving mutants (deterministic gate output). A round is **DRY** when it adds zero new findings.
- **Retirement** = 2 consecutive dry rounds, then one **varied-angle sweep** on a second frozen template; a dry varied round closes the scenario. Enforced by `eval/run.mjs`, not by discipline — a main-template round after 2 dries is refused by the runner.
- **Prompts are frozen templates** (placeholders only, never re-composed per run). One amendment mid-campaign: v1.1 added a scenario-isolation protection line after the round-1 contamination review; the template's git history is its version record.
- **Every round**: generated suite archived to `eval/results/<scenario>/round-NN/`, scenario restored to empty tests before the next round.
- Gate verdicts are deterministic and taken from single runs; no averaging. Yield-type observations below are small-N and labeled as such.

## Notable artifacts (from the archived suites)

- **Scenario 05 is the headline.** The trap was built to produce this campaign's first survivor: `is_valid`'s comparison mutants cannot be killed by any `expected_failure` test. The generated suites included boundary truth-table tests (`is_valid(0,·)=false`, `is_valid(1,·)=true`, upper edge) in all 3 rounds — the vacuous-suite failure mode did not materialize.
- **Scenario 01**: one dedicated test per `ENotPositive` site (add/scale/reserve), annotated with source line numbers — the name-based-pairing shortcut (one test "covering" three sites) was available and not taken.
- **Scenario 02**: tests carry sequencing comments ("must pass guards 1-2"), and boundary tests sit on the exact unlock edge — explicit evidence the skill staged preconditions rather than guessing.
- **Varied rounds** open with a full abort-path + comparison-boundary enumeration in the header — frozen-template compliance is visible in the artifact itself.
- **One find outside the gate's domain**: scenario 00 round 1's generated header comment miscounts its own expected-failure tests (says 6, contains 7). The gate reads code, not comments; only a human read catches this class.
- **Gate cross-check**: per-scenario mutant counts (10/9/6/9/5) match the trap designs' operator arithmetic exactly — the exhaustive sweep behaved per spec on five modules it had never seen.

## What this campaign did NOT prove

1. **Generality.** Six fixture-scale modules, one trap author. The traps share their designer's blind spots; a defect class the author didn't think to bait is unmeasured.
2. **Anything outside the gate's operator set.** Seven mutation operators are the measurement ceiling. A wrong-but-comparison-preserving logic error is invisible to this campaign.
3. **Cross-family robustness.** All 18 rounds ran one model family. Upstream bench results (TheColliery) showed prompt/role diversity does not break a shared model blind spot — only a second model family does. This campaign's varied-angle sweep is a depth tool, not a decorrelation tool; the shared-blind-spot risk is **unmeasured** here.
4. **Semantic test quality beyond killing.** A suite can kill every mutant and still assert weakly elsewhere; the gate does not read intent.
5. **Scenario 00 round 1** remains may-be-contaminated by record; the claim rests on round 2's clean reproduction, not on round 1.

## Honest scope

Fixture-scale modules, scripted traps, N = 18 rounds on one date, one machine, one model family. The numbers are this campaign's, not a universal promise. The next axes, in order of information value: a second model family on the same scenarios (decorrelation), a second trap author, and operators beyond the current seven.

## Method lineage

The lab's shape is borrowed, with thanks, from **HetCreep / TheColliery** ([github.com/TheColliery](https://github.com/TheColliery)) — several of its rules were handed over in conversation before this campaign ran:

- **Retirement-by-saturation** — "*stop at 2 consecutive dry rounds, then one varied-angle sweep before closing*" — from the CoalWash durability campaign's measured protocol.
- **Frozen TEMPLATE-ONLY prompts** — from their lab's sharpest recorded loss (T71, a hand-composed contract that silently dropped a protection line): "*the operator is a louder noise source than the model.*"
- **Deterministic verdicts need no averaging; yield wears its low confidence openly** — the SAFETY/YIELD split.
- **A dry verdict is angle-relative** — hence the mandatory varied sweep before retirement.
- **Revert in the same round** — archived-and-restored scenarios, never a caught artifact left in place.
- **"data ∝ sharpness × angle-diversity, not ∝ cost"** — the reason honest-scope item 3 exists, and the next campaign's axis.
- This record's format (Measured line, per-arm scorecards, a *what-this-did-NOT-prove* section) is modeled on the [CoalWash campaign records](https://github.com/TheColliery/.github/tree/main/benchmarks/CoalWash).

The mutation-testing layer itself (`--mutate`) also began as their suggestion — credited in the main README since v1.
