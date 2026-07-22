/**
 * Selftest for lint rules — synthetic Move source, no sui needed.
 * Tests all 3 rules: MOV-001, MOV-002, MOV-003.
 * Each new skip pattern gets a pin here BEFORE the rule ships.
 */
import { check as check001 } from '../../../../rules/mov-001-missing-access-control.mjs';
import { check as check002 } from '../../../../rules/mov-002-unchecked-arithmetic.mjs';
import { check as check003 } from '../../../../rules/mov-003-division-without-zero-check.mjs';

const errs = [];
function assert(label, cond) {
  if (!cond) errs.push(label);
}

// ── MOV-001: access control ──────────────────────────────────────────

const unsafe001 = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    public fun drain(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}`;

const safe_cap = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    public struct AdminCap has key { id: UID }
    public fun drain(cap: &AdminCap, pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}`;

const safe_init = `
module example::pool {
    public struct Pool has key { id: UID }
    fun init(ctx: &mut TxContext) { }
}`;

// generic function — MUST be detected (was silently skipped before fix)
const unsafe_generic = `
module example::dex {
    public struct Pool<phantom X, phantom Y> has key { id: UID, reserve_x: u64 }
    public fun update_pool<X, Y>(pool: &mut Pool<X, Y>, configs: &Configs) {
        abort 0
    }
}`;

// #[test_only] function — must be skipped
const safe_test_only = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    #[test_only]
    public fun add_balance_test(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance + amount;
    }
}`;

// _test suffix — must be skipped
const safe_test_suffix = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    public fun drain_test(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}`;

// Version parameter — must be skipped (Scallop pattern)
const safe_version = `
module example::lending {
    public fun accrue_interest(version: &Version, market: &mut Market, clock: &Clock) {
        version::assert_current_version(version);
    }
}`;

// Key parameter — must be skipped (ObligationKey pattern)
const safe_key = `
module example::obligation {
    public fun unlock(self: &mut Obligation, obligation_key: &ObligationKey, key: u64) {
        abort 0
    }
}`;

// Witness parameter — must be skipped
const safe_witness = `
module example::market {
    public fun uid_mut_delegated(market: &mut Market, _: Witness<Market>): &mut UID {
        &mut market.id
    }
}`;

// Coin<T> parameter — permissionless DeFi function, must be skipped
const safe_coin = `
module example::dex {
    public struct Pool<phantom X, phantom Y> has key { id: UID }
    public fun swap<X, Y>(pool: &mut Pool<X, Y>, coin_in: Coin<X>, ctx: &mut TxContext): Coin<Y> {
        abort 0
    }
}`;

// LPToken parameter — must be skipped
const safe_lp = `
module example::dex {
    public struct Pool<phantom X, phantom Y> has key { id: UID }
    public fun remove_liquidity<X, Y>(pool: &mut Pool<X, Y>, lp: KriyaLPToken<X, Y>, amount: u64, ctx: &mut TxContext) {
        abort 0
    }
}`;

// key/witness named param (generic T: drop pattern) — must be skipped
const safe_key_param = `
module example::lock {
    public fun force_unlock<T: drop>(obligation: &mut Obligation, _key: T) {
        abort 0
    }
}`;

const r001 = check001(unsafe001, 'pool.move');
assert('MOV-001: flags public fun without cap', r001.length > 0);
assert('MOV-001: rule ID correct', r001[0].rule === 'MOV-001');
assert('MOV-001: severity HIGH', r001[0].severity === 'HIGH');

assert('MOV-001: passes with AdminCap', check001(safe_cap, 'pool.move').length === 0);
assert('MOV-001: skips init', check001(safe_init, 'pool.move').length === 0);

const r001_generic = check001(unsafe_generic, 'dex.move');
assert('MOV-001: catches generic function <X, Y>', r001_generic.length > 0);
assert('MOV-001: generic finding names update_pool', r001_generic[0].message.includes('update_pool'));

assert('MOV-001: skips #[test_only] function', check001(safe_test_only, 'pool.move').length === 0);
assert('MOV-001: skips _test suffix', check001(safe_test_suffix, 'pool.move').length === 0);
assert('MOV-001: skips Version param', check001(safe_version, 'lending.move').length === 0);
assert('MOV-001: skips Key param', check001(safe_key, 'obligation.move').length === 0);
assert('MOV-001: skips Witness param', check001(safe_witness, 'market.move').length === 0);
assert('MOV-001: skips Coin<T> param', check001(safe_coin, 'dex.move').length === 0);
assert('MOV-001: skips LPToken param', check001(safe_lp, 'dex.move').length === 0);
assert('MOV-001: skips _key witness param', check001(safe_key_param, 'lock.move').length === 0);

// ── MOV-002: unchecked multiplication ────────────────────────────────

const unsafe_mul = `
module example::fee {
    public fun calc(amount: u64, rate: u64): u64 {
        amount * rate
    }
}`;

const safe_mul_cast = `
module example::fee {
    public fun calc(amount: u64, rate: u64): u64 {
        ((amount as u128) * (rate as u128) / 10000 as u64)
    }
}`;

// #[test] function body — must be skipped
const safe_mul_test = `
module example::setup {
    public fun real_fn(): u64 { 42 }

    #[test]
    fun setup_test() {
        let amount = 1_000_000 * std::u64::pow(10, 6);
        assert!(amount > 0, 0);
    }
}`;

// _u256 suffix variables — already promoted, must be skipped
const safe_mul_u256 = `
module example::math {
    public fun calc(a: u128, b: u128): u256 {
        let a_u256 = (a as u256);
        let b_u256 = (b as u256);
        a_u256 * b_u256
    }
}`;

const r002a = check002(unsafe_mul, 'fee.move');
assert('MOV-002: flags u64 * u64 without cast', r002a.length > 0);
assert('MOV-002: rule ID correct', r002a[0].rule === 'MOV-002');

assert('MOV-002: passes with u128 cast', check002(safe_mul_cast, 'fee.move').length === 0);
assert('MOV-002: skips #[test] function body', check002(safe_mul_test, 'setup.move').length === 0);
assert('MOV-002: skips _u256 suffix vars', check002(safe_mul_u256, 'math.move').length === 0);

// ── MOV-003: division without zero check ─────────────────────────────

const unsafe_div = `
module example::vault {
    public fun shares(amount: u64, total: u64): u64 {
        amount / total
    }
}`;

const safe_div_assert = `
module example::vault {
    const EZero: u64 = 1;
    public fun shares(amount: u64, total: u64): u64 {
        assert!(total != 0, EZero);
        amount / total
    }
}`;

const safe_div_literal = `
module example::fee {
    public fun basis(amount: u64): u64 {
        amount / 10000
    }
}`;

// #[test] function body — must be skipped
const safe_div_test = `
module example::limiter {
    public fun real_fn(): u64 { 42 }

    #[test]
    fun outflow_limit_test() {
        let segment_duration: u64 = 60 * 30;
        let cycle_duration: u64 = 60 * 60 * 24;
        let segment_count = cycle_duration / segment_duration;
    }
}`;

const r003a = check003(unsafe_div, 'vault.move');
assert('MOV-003: flags division by unchecked variable', r003a.length > 0);
assert('MOV-003: rule ID correct', r003a[0].rule === 'MOV-003');

assert('MOV-003: passes with assert before division', check003(safe_div_assert, 'vault.move').length === 0);
assert('MOV-003: skips division by literal', check003(safe_div_literal, 'fee.move').length === 0);
assert('MOV-003: skips #[test] function body', check003(safe_div_test, 'limiter.move').length === 0);

// ── Summary ──────────────────────────────────────────────────────────

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('lint-rules selftest: all checks passed');
  process.exit(0);
}
