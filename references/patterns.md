# Move Test Patterns Reference

Catalog of edge cases specific to Sui Move. Each pattern includes the rationale (why it matters) and a template (how to test it).

## 1. Arithmetic Boundaries

### 1.1 Multiplication Overflow

**Why:** `a * b` aborts if the result exceeds the type's max. Protocols that calculate `amount * price / precision` can overflow on large inputs even if the final result would fit.

**Template:**
```move
#[test]
#[expected_failure]  // arithmetic overflow
fun test_<fn>_mul_overflow() {
    // Choose a and b such that a * b > MAX_U64 but a * b / precision < MAX_U64
    let a: u64 = 1_000_000_000_000;  // 1T
    let b: u64 = 19_000_000_000;     // 19B
    // a * b = 1.9e22 > MAX_U64 (1.8e19) → overflow
    let _ = module::calculate(a, b);
}
```

**Fix pattern:** Cast to u128 before multiplication, divide, then downcast.

### 1.2 Division by Zero

**Why:** `a / b` aborts if `b == 0`. Any function that divides by a pool balance, total supply, or user-provided denominator must handle the zero case.

**Template:**
```move
#[test]
#[expected_failure]
fun test_<fn>_div_zero_total_supply() {
    // Create pool with zero total supply (empty pool state)
    let result = module::calculate_share(amount, 0);  // total_supply = 0
}
```

### 1.3 Rounding Direction

**Why:** Integer division truncates. Protocols must choose rounding direction deliberately — round down favors the protocol (user gets less), round up favors the user (protocol gives more).

**Template:**
```move
#[test]
fun test_<fn>_rounding_favors_protocol() {
    // Choose values where truncation vs round-up differ by 1
    // total_assets = 1000, total_shares = 3
    // User deposits 1 → shares = 1 * 3 / 1000 = 0 (truncated)
    // This is correct (protocol should not give shares for dust)
    let shares = module::calculate_shares(1, 1000, 3);
    assert!(shares == 0, 0);
}

#[test]
fun test_<fn>_rounding_boundary() {
    // Find the minimum deposit that yields 1 share
    // shares = amount * total_shares / total_assets
    // 1 = amount * 3 / 1000 → amount = 334 (ceiling of 1000/3)
    let shares = module::calculate_shares(334, 1000, 3);
    assert!(shares >= 1, 0);
}
```

## 2. Access Control

### 2.1 Missing Capability

**Why:** If a function requires `AdminCap` but an attacker calls it without one, the call should be rejected.

**Important:** In Move, this is enforced at **compile time**, not runtime. If a function takes `&AdminCap` as a parameter, you literally cannot call it without providing one — the compiler rejects it. This means you cannot write a runtime test for "calling without a capability." Instead, document that the type system enforces this invariant, and focus your tests on cases that ARE runtime-checkable (wrong capability type, capability after transfer, fee bounds with a valid cap).

### 2.2 Wrong Capability Type

**Why:** If module A has `AdminCap` and module B has a different `AdminCap`, passing B's cap to A's function should fail. Move's type system normally prevents this, but generic functions with `T: store` constraints might accept the wrong type.

**Template:**
```move
#[test]
#[expected_failure]
fun test_<fn>_wrong_cap_type() {
    let wrong_cap = other_module::create_admin_cap_for_testing(&mut ctx);
    module::admin_action(&wrong_cap, ...);  // should not compile or should abort
}
```

### 2.3 Capability After Transfer

**Why:** After transferring a capability to another address, the original holder should no longer be able to use it. Move's ownership model enforces this, but the test documents the expectation.

**Template:**
```move
#[test]
fun test_<fn>_cap_single_owner() {
    let cap = module::create_admin_cap_for_testing(&mut ctx);
    transfer::public_transfer(cap, @0xBEEF);
    // cap is now moved — any further use is a compile error
    // This test exists to document the invariant
}
```

## 3. State Machine

### 3.1 Wrong Order

**Why:** Some operations must happen in sequence (borrow → use → repay). Calling them out of order should abort.

**Template:**
```move
#[test]
#[expected_failure(abort_code = module::ENotBorrowed)]
fun test_repay_without_borrow() {
    // Call repay without a preceding borrow
    let coin = coin::mint_for_testing<SUI>(1000, &mut ctx);
    module::repay(&mut pool, coin, ???);  // no Receipt exists
}
```

### 3.2 Double Execution

**Why:** An operation that should happen exactly once (claim reward, initialize) must abort on the second call.

**Template:**
```move
#[test]
#[expected_failure(abort_code = module::EAlreadyClaimed)]
fun test_<fn>_double_claim() {
    module::claim_reward(&mut pool, &receipt, &mut ctx);
    module::claim_reward(&mut pool, &receipt, &mut ctx);  // second call should abort
}
```

### 3.3 Hot Potato Resolution

**Why:** Structs without `drop` (hot potato pattern) must be consumed by a specific function. If the consuming function has a bug or is called with wrong arguments, the transaction aborts.

**Important:** Not consuming a no-`drop` value is a **compile-time error** in Move, not a runtime abort. You cannot write a `#[test]` that leaves a hot potato unconsumed — the code will not compile. Instead, test the hot potato pattern by verifying that the consuming function enforces its invariants (e.g., repay amount >= borrow amount + fee).

**Template:**
```move
#[test]
#[expected_failure(abort_code = module::ERepayInsufficient)]
fun test_<fn>_hot_potato_underpay() {
    let (coin, receipt) = module::flash_borrow(&mut pool, 1000);
    // Attempt to repay less than required — consuming function aborts
    let partial = coin::split(&mut coin, 500);
    module::flash_repay(&mut pool, partial, receipt);
    // receipt is consumed but repay amount was insufficient → abort
    coin::burn_for_testing(coin);
}
```

## 4. Economic

### 4.1 Fee Evasion via Dust

**Why:** If fees are calculated as `amount * fee_bps / 10000`, amounts smaller than `10000 / fee_bps` produce zero fees. An attacker can split a large operation into many dust operations to avoid fees entirely.

**Template:**
```move
#[test]
fun test_<fn>_dust_fee_evasion() {
    // fee_bps = 30 (0.3%)
    // amount = 333 → fee = 333 * 30 / 10000 = 0 (truncated)
    let fee = module::calculate_fee(333, 30);
    assert!(fee == 0, 0);  // dust amount pays zero fee

    // Compare: single operation of 333 * 100 = 33300
    let fee_bulk = module::calculate_fee(33300, 30);
    assert!(fee_bulk == 99, 0);  // 99 units of fee

    // Attacker splits into 100 operations of 333 → pays 0 total fee
    // Protocol should enforce minimum fee or minimum amount
}
```

### 4.2 First Depositor / Share Inflation

**Why:** In vault-style contracts, the first depositor can manipulate the share price by depositing a tiny amount and then directly transferring a large amount to the vault. The second depositor gets zero shares due to rounding.

**Template:**
```move
#[test]
fun test_<fn>_first_depositor_inflation() {
    // Attacker deposits 1 unit → gets 1 share
    let shares_1 = module::deposit(&mut vault, coin::mint_for_testing(1, &mut ctx));
    assert!(shares_1 == 1, 0);

    // Attacker donates 1_000_000 directly to vault (no shares minted)
    module::donate_for_testing(&mut vault, 1_000_000);

    // Victim deposits 999_999
    // shares = 999_999 * 1 / 1_000_001 = 0 (truncated)
    let shares_2 = module::deposit(&mut vault, coin::mint_for_testing(999_999, &mut ctx));
    assert!(shares_2 == 0, 0);  // victim gets nothing

    // Protocol should enforce minimum initial deposit
}
```

## 5. Sui-Specific

### 5.1 Shared Object Contention

**Why:** Shared objects require consensus ordering. Tests should verify that the function behaves correctly when called concurrently by different transactions (simulated via test_scenario with multiple senders).

### 5.2 Object Wrapping Escape

**Why:** An object wrapped inside another object is not directly accessible. But if the wrapper provides a mutable reference to the inner object, the caller can modify it. Test that wrapper access controls are sufficient.

### 5.3 Clock Dependency

**Why:** Functions that read `Clock` (object `0x6`) for time-based logic must be tested at time boundaries — expiration edges, zero timestamps, far-future timestamps.

**Template:**
```move
#[test]
fun test_<fn>_at_exact_expiry() {
    let clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, EXPIRY_MS);
    // Call function at exact expiry moment — is it expired or not?
    let result = module::check_expiry(&thing, &clock);
    // Document which way the boundary goes (< vs <=)
    clock::destroy_for_testing(clock);
}
```

### 5.4 Clock Boundary Precision

**Why:** Many DeFi protocols use Clock for vesting schedules, lock periods, and oracle staleness. The boundary between "valid" and "expired" is a single millisecond — and protocols are inconsistent about whether they use `<` or `<=`.

**Template:**
```move
#[test]
fun test_not_expired_one_ms_before() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, EXPIRY_MS - 1);
    let result = module::is_active(&thing, &clock);
    assert!(result == true); // one ms before deadline: still active
    clock::destroy_for_testing(clock);
}

#[test]
fun test_expired_at_exact_deadline() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, EXPIRY_MS);
    let result = module::is_active(&thing, &clock);
    // Document which way the boundary goes: does EXPIRY_MS mean
    // "last valid moment" or "first invalid moment"?
    clock::destroy_for_testing(clock);
}

#[test]
fun test_expired_one_ms_after() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, EXPIRY_MS + 1);
    let result = module::is_active(&thing, &clock);
    assert!(result == false); // one ms past deadline: expired
    clock::destroy_for_testing(clock);
}
```

### 5.5 Shared Object Concurrent Modification

**Why:** When two transactions touch the same shared object, Sui sequences them through consensus. But `test_scenario` runs sequentially — you cannot test true concurrency. What you CAN test is that the function handles the state left by a previous caller correctly.

**Template:**
```move
#[test]
fun test_second_deposit_after_first() {
    let mut scenario = test_scenario::begin(@0xA);

    // User A deposits into the shared pool
    test_scenario::next_tx(&mut scenario, @0xA);
    {
        let mut pool = test_scenario::take_shared<Pool>(&scenario);
        let coin_a = coin::mint_for_testing<SUI>(1000, test_scenario::ctx(&mut scenario));
        pool::deposit(&mut pool, coin_a);
        test_scenario::return_shared(pool);
    };

    // User B deposits into the same pool
    test_scenario::next_tx(&mut scenario, @0xB);
    {
        let mut pool = test_scenario::take_shared<Pool>(&scenario);
        let coin_b = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let shares = pool::deposit(&mut pool, coin_b);
        // B gets shares proportional to deposit relative to pool
        // balance AFTER A's deposit, not the initial empty state
        assert!(shares == expected_for_second_depositor);
        test_scenario::return_shared(pool);
    };

    test_scenario::end(scenario);
}
```

The key insight: test the state transitions, not the concurrency. If deposit #2 calculates shares correctly given deposit #1's state change, the contract is safe regardless of consensus ordering.

