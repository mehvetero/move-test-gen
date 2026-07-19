/**
 * Selftest for testability.mjs — pure function, no sui needed.
 */
import { checkTestability } from '../../../../scripts/testability.mjs';

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

// Case 1: module with CoinMetadata and no test_only — should warn (farm pattern)
const farmLike = `
module example::farm {
    use sui::coin::CoinMetadata;
    public struct Farm has key { id: UID }
    public fun new_farm(meta: &CoinMetadata<T>, amount: u64): Farm { abort 0 }
    public fun stake(farm: &mut Farm, amount: u64) { assert!(amount > 0, 1); }
}`;
const r1 = checkTestability(farmLike, 'farm');
check('farm-like: not testable', r1.testable === false);
check('farm-like: has CoinMetadata warning', r1.warnings.some(w => w.includes('CoinMetadata')));

// Case 2: module with test_only constructor — should pass (vault pattern)
const vaultLike = `
module example::vault {
    public struct Vault has key { id: UID, balance: u64 }
    public fun deposit(vault: &mut Vault, amount: u64) { assert!(amount > 0, 1); }
    #[test_only]
    public fun create_for_testing(ctx: &mut TxContext): Vault {
        Vault { id: object::new(ctx), balance: 0 }
    }
}`;
const r2 = checkTestability(vaultLike, 'vault');
check('vault-like: testable', r2.testable === true);
check('vault-like: no warnings', r2.warnings.length === 0);

// Case 3: pure math module (no structs needing construction) — should pass
const mathLike = `
module example::math {
    public fun add(a: u64, b: u64): u64 { a + b }
    public fun checked_add(a: u64, b: u64): u64 { assert!(a + b >= a, 1); a + b }
}`;
const r3 = checkTestability(mathLike, 'math');
check('math-like: testable', r3.testable === true);

// Case 4: module with struct but public constructor exists
const withCtor = `
module example::token {
    public struct Token has drop { value: u64 }
    public fun new(value: u64): Token { Token { value } }
    public fun burn(t: Token) { let Token { value: _ } = t; }
}`;
const r4 = checkTestability(withCtor, 'token');
check('with-ctor: testable', r4.testable === true);

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('testability-check selftest: all checks passed');
  process.exit(0);
}
