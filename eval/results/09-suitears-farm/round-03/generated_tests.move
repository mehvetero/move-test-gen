// scenario 09, round 3 (main v1.1)
#[test_only]
module suitears::farm_r3_tests {
    use sui::clock;
    use suitears::farm;

    #[test]
    fun r3_cap() {
        let mut ctx = tx_context::dummy();
        let cap = farm::new_cap(&mut ctx);
        farm::destroy_cap(cap);
    }

    #[test]
    fun r3_clock() {
        let mut ctx = tx_context::dummy();
        let mut c = clock::create_for_testing(&mut ctx);
        clock::set_for_testing(&mut c, 3600_000);
        assert!(farm::clock_timestamp_s(&c) == 3600);
        clock::destroy_for_testing(c);
    }
}
