// scenario 09, round 5 (varied v1.1)
// Abort path enumeration for farm.move:
//   L135: start_timestamp > clock_timestamp_s(c) → EInvalidStartTime
//   L367: object::id(farm) == account.farm_id   → EInvalidAccount
//   L431: object::id(farm) == account.farm_id   → EInvalidAccount
//   L434: account.amount >= amount              → EInsufficientStakeAmount
//   L486: amount == 0                           → EAccountHasValue
//
// Limitation: all five abort sites require a Farm object, which needs
// CoinMetadata (OTW + create_currency). No test_only constructor exists.
// Only clock_timestamp_s and new_cap/destroy_cap are testable without
// the full object chain.

#[test_only]
module suitears::farm_varied_tests {
    use sui::clock;
    use suitears::farm;

    #[test]
    fun varied_cap() {
        let mut ctx = tx_context::dummy();
        let cap = farm::new_cap(&mut ctx);
        farm::destroy_cap(cap);
    }

    #[test]
    fun varied_clock_boundary() {
        let mut ctx = tx_context::dummy();
        let mut c = clock::create_for_testing(&mut ctx);
        clock::set_for_testing(&mut c, 999);
        assert!(farm::clock_timestamp_s(&c) == 0);
        clock::set_for_testing(&mut c, 1000);
        assert!(farm::clock_timestamp_s(&c) == 1);
        clock::set_for_testing(&mut c, 1001);
        assert!(farm::clock_timestamp_s(&c) == 1);
        clock::destroy_for_testing(c);
    }
}
