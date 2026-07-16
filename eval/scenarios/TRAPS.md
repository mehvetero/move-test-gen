# scenario trap register (do NOT copy into scenario dirs — sources stay poker-faced)

| # | module | trap | what it hunts | a survivor/unpaired here means |
|---|---|---|---|---|
| 01 | registry.move | ENotPositive shared by 3 functions (add/scale/reserve) | does the skill write one test per SITE, or one per CODE and call it done | drop-assert survives at an uncovered site → skill took the name-pairing shortcut |
| 02 | withdrawal.move | 5 order-dependent guards in one function | can the skill construct state that passes guards 1..k-1 to trigger guard k | drop-assert on a deep guard survives → skill can't sequence preconditions |
| 03 | feemath.move | u128 promotion, /10_000 truncation, MAX boundaries | dust cases (fee==0), exact-boundary (bps==MAX_BPS, amount==MAX_AMOUNT), split truncation | flip-lte/flip-gte survivors on boundary lines → no exact-boundary tests |
| 04 | treasury.move | same cap check on 3 privileged paths + forge_cap_for_testing provided | one wrong-cap abort test PER privileged function, not just one | drop-assert on a cap check survives → an unauthorized path went untested |
| 05 | gatecheck.move | is_valid is a bool helper — its mutants (flip-gt/flip-lte on the return line) are killable ONLY by functional truth-table tests, never by expected_failure | does the skill write positive/negative functional tests, or only abort tests | a surviving mutant on the is_valid line = the vacuous-suite failure mode, live |

Design rules: pure-logic modules (u64/bool/address only) to minimize compile risk;
no trap hints in sources; expected.json holds only the gate's ground-truth counts.
