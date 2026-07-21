/**
 * Selftest for lint rules — synthetic Move source, no sui needed.
 * Tests all 3 rules: MOV-001, MOV-002, MOV-003.
 */
import { check as check001 } from '../../../../rules/mov-001-missing-access-control.mjs';
import { check as check002 } from '../../../../rules/mov-002-unchecked-arithmetic.mjs';
import { check as check003 } from '../../../../rules/mov-003-division-without-zero-check.mjs';

const errs = [];
function check(label, cond) {
  if (!cond) errs.push(label);
}

// ── MOV-001: access control ──

const unsafe = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    public fun drain(pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}`;

const safe = `
module example::pool {
    public struct Pool has key { id: UID, balance: u64 }
    public struct AdminCap has key { id: UID }
    public fun drain(cap: &AdminCap, pool: &mut Pool, amount: u64) {
        pool.balance = pool.balance - amount;
    }
}`;

const initFn = `
module example::pool {
    public struct Pool has key { id: UID }
    fun init(ctx: &mut TxContext) { }
}`;

const r001a = check001(unsafe, 'pool.move');
check('MOV-001: flags public fun without cap', r001a.length > 0);
check('MOV-001: rule ID correct', r001a[0].rule === 'MOV-001');
check('MOV-001: severity HIGH', r001a[0].severity === 'HIGH');

const r001b = check001(safe, 'pool.move');
check('MOV-001: passes when AdminCap present', r001b.length === 0);

const r001c = check001(initFn, 'pool.move');
check('MOV-001: skips init function', r001c.length === 0);

// ── MOV-002: unchecked multiplication ──

const unsafeMul = `
module example::fee {
    public fun calc(amount: u64, rate: u64): u64 {
        amount * rate
    }
}`;

const safeMul = `
module example::fee {
    public fun calc(amount: u64, rate: u64): u64 {
        ((amount as u128) * (rate as u128) / 10000 as u64)
    }
}`;

const r002a = check002(unsafeMul, 'fee.move');
check('MOV-002: flags u64 * u64 without cast', r002a.length > 0);
check('MOV-002: rule ID correct', r002a[0].rule === 'MOV-002');

const r002b = check002(safeMul, 'fee.move');
check('MOV-002: passes when u128 cast present', r002b.length === 0);

// ── MOV-003: division without zero check ──

const unsafeDiv = `
module example::vault {
    public fun shares(amount: u64, total: u64): u64 {
        amount / total
    }
}`;

const safeDiv = `
module example::vault {
    const EZero: u64 = 1;
    public fun shares(amount: u64, total: u64): u64 {
        assert!(total != 0, EZero);
        amount / total
    }
}`;

const literalDiv = `
module example::fee {
    public fun basis(amount: u64): u64 {
        amount / 10000
    }
}`;

const r003a = check003(unsafeDiv, 'vault.move');
check('MOV-003: flags division by unchecked variable', r003a.length > 0);
check('MOV-003: rule ID correct', r003a[0].rule === 'MOV-003');

const r003b = check003(safeDiv, 'vault.move');
check('MOV-003: passes when assert before division', r003b.length === 0);

const r003c = check003(literalDiv, 'fee.move');
check('MOV-003: skips division by literal', r003c.length === 0);

// ── Summary ──

if (errs.length) {
  console.log('FAIL:');
  for (const e of errs) console.log(`  ✗ ${e}`);
  process.exit(1);
} else {
  console.log('lint-rules selftest: all checks passed');
  process.exit(0);
}
