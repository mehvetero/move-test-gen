// scenario 03 round 3 (varied v1.1)
#[test_only]
module s03::feemath_varied {
    use s03::feemath;

    #[test]
    #[expected_failure(abort_code = feemath::EFeeTooHigh)]
    fun path_bps() { feemath::fee_for(1, 10_001); }

    #[test]
    #[expected_failure(abort_code = feemath::EAmountTooLarge)]
    fun path_amt() { feemath::fee_for(1_000_000_000_000_001, 0); }

    #[test]
    #[expected_failure(abort_code = feemath::EZeroParts)]
    fun path_parts() { feemath::split_fee(1, 1, 0); }

    #[test]
    fun bound_bps_max() { assert!(feemath::fee_for(10_000, 10_000) == 10_000); }

    #[test]
    fun bound_amt_max() { assert!(feemath::fee_for(1_000_000_000_000_000, 10_000) == 1_000_000_000_000_000); }

    #[test]
    fun bound_fee_one() { assert!(feemath::fee_for(100, 100) == 1); }

    #[test]
    fun bound_fee_zero() { assert!(feemath::fee_for(99, 100) == 0); }

    #[test]
    fun net_normal() { assert!(feemath::net_after_fee(10_000, 500) == 9_500); }

    #[test]
    fun split_one_part() { assert!(feemath::split_fee(10_000, 1000, 1) == 1000); }
}
