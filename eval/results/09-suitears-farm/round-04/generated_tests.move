// scenario 09, round 4 (main v1.1)
#[test_only]
module suitears::farm_r4_tests {
    use sui::clock;
    use suitears::farm;

    #[test]
    fun r4_cap_lifecycle() {
        let mut ctx = tx_context::dummy();
        let cap = farm::new_cap(&mut ctx);
        farm::destroy_cap(cap);
    }

    #[test]
    fun r4_clock_zero() {
        let mut ctx = tx_context::dummy();
        let mut c = clock::create_for_testing(&mut ctx);
        clock::set_for_testing(&mut c, 0);
        assert!(farm::clock_timestamp_s(&c) == 0);
        clock::destroy_for_testing(c);
    }

    #[test]
    fun r4_clock_sub_second() {
        let mut ctx = tx_context::dummy();
        let mut c = clock::create_for_testing(&mut ctx);
        clock::set_for_testing(&mut c, 999);
        assert!(farm::clock_timestamp_s(&c) == 0);
        clock::destroy_for_testing(c);
    }
}
