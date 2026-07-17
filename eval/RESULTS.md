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


---

# Campaign 2 — the survivor path

**Measured:** 2026-07-16 · repo state through `e8d463f` · gate: v1.1 (`bd521f9` → `6957be1`, survivor reframe + measured mutual-redundancy probe; `eval/gate-selftest` 6/6 green, CI-attested) · engine: agent VM · `sui 1.74.1-8fc60f1fa966` · pin `mainnet-v1.74.1` · generator model: `Claude 4.8` — a **fresh session on a different model family from the build agent (GPT-5.5)**, so generation was isolated from the answer key at both the context and the weight level · prompts: frozen templates v1.1.

> **TL;DR:** the assignment was to exercise the one path campaign 1 never touched — a survivor — with a **true equivalent mutant**, unkillable by construction, where the pass condition flips: the gate must confess *undecidable* instead of blaming the suite. **Scenario 06 is RETIRED after 3 protocol rounds, all identical: 8 mutants = 6 killed + 2 planted equivalents, and the gate confessed both survivors with measured evidence in every round.** `planted_silent` (the gate-honesty failure bucket) stayed empty throughout. The floor admitted what it can't decide, enforced by code rather than prose.

## The trap

`locker.move`: a redundant guard pair — public `withdraw` checks `amount > 0`, then calls private `take`, which re-checks the same condition with the same abort code. Through the callable surface, each `drop-assert` on the pair is semantically invisible: exactly two equivalent mutants by construction. The other six mutants are honestly killable (verified in the design table in `eval/CAMPAIGN2.md`, reproduced in the field below).

## Rounds

| Round | Template | Covered | Mutants | Adjudicated equivalent | planted_silent | Verdict |
|---|---|---|---|---|---|---|
| 1 | main v1.1 | 4/4 | 6/8 killed | 2 (L15, L20 — with evidence) | 0 | DRY |
| 2 | main v1.1 | 4/4 | 6/8 killed | 2 | 0 | DRY |
| 3 | varied v1.1 | 4/4 | 6/8 killed | 2 | 0 | DRY → **RETIRED** |

## How the honesty channel works (and what it deliberately does not do)

- The gate no longer blames the suite for a survivor. It reports: *SURVIVED — undecidable by this gate: weak suite OR equivalent mutant. Judgment needed above this floor.*
- For surviving `drop-assert` groups sharing an abort code, the gate runs one **higher-order joint mutant** (all guards in the group dropped at once). Evidence is stamped **only when the singles survive and the joint dies** — measured, never pattern-matched. In the field, the joint mutant died in all three rounds: the pair is individually removable, jointly load-bearing.
- **The gate never reads the answer key.** `eval/keys/06-equivalent.json` is read by `eval/run.mjs` only, which adjudicates: planted + gate-confessed → `adjudicated_equivalent` (not a finding); planted but gate-silent → stays a finding (**a gate failure, not a suite failure** — this is the flipped pass condition); unplanted survivors stay findings even if the gate offers evidence.
- The gate's raw numbers are untouched by all of this: mutation score stayed 75% and exit stayed 1 in every round. **Fail-closed is preserved** — the floor never greenlights what it can't decide; interpretation happens strictly above it.

## What campaign 2 did NOT prove (pre-registered in eval/CAMPAIGN2.md §5)

1. The gate is **not** an equivalence decider — the opposite is the point. Equivalence is undecidable; the channel is a confession, and the mutual-redundancy probe covers exactly **one equivalence class**. Equivalents outside the redundant-guard shape would receive the generic *undecidable* framing with no evidence.
2. One scenario, N = 3 rounds, one planted class. The generator's quality was secondary here; the unit under test was the floor's honesty.
3. Generator families now span two campaigns (GPT-5.5 in campaign 1, Claude 4.8 here) — noted as the **first entry of a second family**, not as a controlled comparison: the scenarios differ. A same-scenario cross-family campaign remains the next axis.
4. Build-phase operator errors occurred twice (an answer-count typo in the problem sheet; trap-hint comments copied into sources) and were caught in review before any round ran. Recorded because the operator remains the noise floor.

## Lineage

The assignment — plant a true equivalent, flip the pass condition to a confession, move the judgment back above the floor — was set by **HetCreep / TheColliery** in conversation (2026-07-16), as was the framing it closes on: *"the floor admits what it can't decide; the judgment moves back to the stochastic side."* The campaign is that sentence, run three times.


---

# Campaign 3 — real protocol

**Measured:** 2026-07-17 · repo state through `3a0890e` · gate: v1.1 with `--scope` filter (`eval/gate-selftest` 7/7 green, CI-attested) · engine: agent VM · generator model: `GPT-5.5` (all three scenarios, same session) · `sui 1.74.1-8fc60f1fa966` · pin `mainnet-v1.74.1` · prompts: frozen templates v1.1 · source: [Interest Protocol / SuiTears](https://github.com/interest-protocol/suitears) at `f39693a00e23`.

> **TL;DR:** the "fixture-scale" self-disclosure from campaigns 1–2 is retired. Three scenarios ran against production SuiTears modules — an ERC-4626 vault (fund.move, 153 lines), a multi-feed oracle with hot-potato + Clock + OwnerCap (oracle.move, 477 lines), and a staking farm with no test constructors (farm.move, 500+ lines). **fund: target mutants 3/3 killed every round. oracle: 19/22 → 21/22 (self-improvement across generations), with a defense-in-depth survivor identified (by reviewer judgment) as the first naturally occurring instance of the equivalent-mutant class from campaign 2. farm: mutation could not run (baseline fails — the module lacks test_only constructors, making its abort paths untestable without upstream changes). All three retired by protocol.**

## Scenarios

| # | Module | Type | Rounds | Target mutants | Layer 1 | Notable |
|---|---|---|---|---|---|---|
| 07 | fund.move | pure arithmetic vault | 4 | **3/3** every round | 0/0 (no asserts) | 56 dep-library survivors: no counterexample in 4 generations |
| 08 | oracle.move | hot-potato + Clock + OwnerCap | 4 | R1: **19/22** → R2–4: **21/22** | 10/95† | R2 cracked two complex setups (dual-oracle ID mismatch + unregistered feed). 1 survivor = defense-in-depth (EOracleMustHaveFeeds) |
| 09 | farm.move | staking/rewards, no test helpers | 5 | **null/null** | 0/95† | unmeasurable — infrastructure gap (see below) |

† Layer 1 denominator is the full package (95 asserts across all SuiTears modules). The `--scope` filter restricts mutation to the target file only; Layer 1 still scans all sources.

## Notable findings

**Scenario 08 — score improvement R1→R2.** R1 generated 19/22 with two gaps documented as coverage-gap comments ("two Oracle instances needed", "unregistered feed setup complex"). R2 closed both: created dual-oracle instances for `ERequestAndOracleIdMismatch` and introduced an unregistered feed type for `EInvalidReportFeeds`. This progression is recorded in the archived suites. Note: all rounds ran in one session — R2 had R1's output in context, so the improvement is correlated, not independent (see item 6 below).

**Scenario 08 — naturally occurring equivalent mutant.** The surviving `EOracleMustHaveFeeds` (L147) is a defense-in-depth guard: `new()` constructs the Oracle with a non-empty feed set via `vectors::to_vec_set`, so `request()`'s emptiness check can never fire through the public API. This is structurally identical to campaign 2's planted equivalent (redundant guard pair where the outer gate prevents the inner from ever triggering) — but here it was not planted, it exists in shipped production code. The gate does not flag this as suspected-equivalent because the mutual-redundancy probe only covers same-file drop-assert pairs sharing an abort code; cross-function redundancy across the call graph is outside the probe's design. This survivor was classified by reviewer judgment, not by gate evidence — honest scope.

**Scenario 09 — unmeasurable, not failed.** Farm requires `CoinMetadata<StakeCoin>`, constructible only via `coin::create_currency` with a one-time witness — no `#[test_only]` constructor exists. Every abort path (5 sites) sits behind this gate. The skill correctly identified the limitation, documented it in generated comments, and produced only the tests it could compile (cap lifecycle + clock conversion). This is a testability finding about the target code, not a skill failure: *the module ships untestable without upstream changes*. A future SuiTears issue is warranted.

## What campaign 3 did NOT prove

1. **One protocol.** All three modules are from the same codebase (SuiTears). A second protocol (Scallop was attempted, build-dependency chain blocked it in this session) remains the next axis for style-diversity.
2. **Training-data contamination is uncontrollable.** SuiTears is a public, starred repository. The generator may have seen it during training. This is noted, not fixable — `target protocols are public code and may be present in the generator's training data.`
3. **Layer 1 denominator is the full package,** not the target module. The 10/95 figure for oracle reflects that only oracle's 11 abort paths are the skill's homework; the other 84 are dependency asserts. A target-scoped Layer 1 mode does not exist yet.
4. **Cross-function equivalent detection** is outside the gate's probe design. The oracle L147 survivor was classified by human review, not by measured evidence.
5. **Scenario 09's "null" is an infrastructure measurement,** not a skill measurement. The verdict is RETIRED by protocol (3 consecutive dry after varied sweep), but the underlying data is "could not run" — a new verdict class (`unmeasurable`) that the protocol does not yet formally distinguish from "measured and saturated."
6. **All rounds share one session.** Later generations had earlier outputs in context. Saturation claims (fund's 4-round plateau) and score-improvement claims (oracle R1→R2) are correlated observations, not independent samples. The "4 independent generations" language from the commit message does not apply — "4 generations, same context" is the accurate description.
