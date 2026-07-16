// scenario 03 round 2 (main v1.1)
#[test_only]
module s03::feemath_r2 {
    use s03::feemath;

    #[test]
    #[expected_failure(abort_code = feemath::EFeeTooHigh)]
    fun bps_over() { feemath::fee_for(100, 10_001); }

    #[test]
    #[expected_failure(abort_code = feemath::EAmountTooLarge)]
    fun amt_over() { feemath::fee_for(1_000_000_000_000_001, 1); }

    #[test]
    #[expected_failure(abort_code = feemath::EZeroParts)]
    fun parts_zero() { feemath::split_fee(100, 10, 0); }

    #[test]
    fun bps_at_max() {
        assert!(feemath::fee_for(500, 10_000) == 500);
    }

    #[test]
    fun amt_at_max() {
        assert!(feemath::fee_for(1_000_000_000_000_000, 1) == 100_000_000_000);
    }

    #[test]
    fun dust_zero() {
        assert!(feemath::fee_for(33, 300) == 0);
    }

    #[test]
    fun dust_one() {
        assert!(feemath::fee_for(34, 300) == 1);
    }

    #[test]
    fun net_zero_bps() {
        assert!(feemath::net_after_fee(999, 0) == 999);
    }

    #[test]
    fun net_full_fee() {
        assert!(feemath::net_after_fee(1000, 10_000) == 0);
    }

    #[test]
    fun split_rounds_down() {
        assert!(feemath::split_fee(10_000, 100, 7) == 14);
    }
}
