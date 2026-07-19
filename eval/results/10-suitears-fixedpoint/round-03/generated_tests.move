// scenario 10, round 3 (main v1.1)
#[test_only]
module suitears::fp64_r3 {
    use suitears::fixed_point64;

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r3_from() { fixed_point64::from(18446744073709551616); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r3_rat_z() { fixed_point64::from_rational(1, 0); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r3_rat_o() { fixed_point64::from_rational(1, 340282366920938463463374607431768211455); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::ENegativeResult)]
    fun r3_sub() { fixed_point64::sub(fixed_point64::from(1), fixed_point64::from(2)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r3_add() { fixed_point64::add(fixed_point64::from_raw_value(340282366920938463463374607431768211455), fixed_point64::from(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r3_div() { fixed_point64::div(fixed_point64::from(1), fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r3_md() { fixed_point64::mul_div(fixed_point64::from(1), fixed_point64::from(1), fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EMultiplicationOverflow)]
    fun r3_mul() { fixed_point64::mul_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(340282366920938463463374607431768211455)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r3_dd0() { fixed_point64::div_down_u128(100, fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun r3_ddo() { fixed_point64::div_down_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r3_du0() { fixed_point64::div_up_u128(100, fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun r3_duo() { fixed_point64::div_up_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOverflowExp)]
    fun r3_exp() { fixed_point64::exp(fixed_point64::from(64)); }

    #[test]
    fun r3_cmp() {
        let a = fixed_point64::from(3);
        let b = fixed_point64::from(7);
        let c = fixed_point64::from(3);
        assert!(fixed_point64::lt(a, b) == true);
        assert!(fixed_point64::gt(b, a) == true);
        assert!(fixed_point64::lte(a, c) == true);
        assert!(fixed_point64::gte(a, c) == true);
        assert!(fixed_point64::eq(a, c) == true);
        assert!(fixed_point64::lt(a, c) == false);
    }

    #[test]
    fun r3_rational_half() {
        let fp = fixed_point64::from_rational(1, 2);
        assert!(fixed_point64::to_u128_down(fp) == 0);
        assert!(fixed_point64::to_u128_up(fp) == 1);
    }

    #[test]
    fun r3_pow_sqrt() {
        let three = fixed_point64::from(3);
        let nine = fixed_point64::pow(three, 2);
        assert!(fixed_point64::to_u128(nine) == 9);
        let root = fixed_point64::sqrt(nine);
        assert!(fixed_point64::to_u128(root) == 3);
    }

    #[test]
    fun r3_mul_div_roundtrip() {
        let a = fixed_point64::from(6);
        let b = fixed_point64::from(7);
        let product = fixed_point64::mul(a, b);
        let back = fixed_point64::div(product, b);
        assert!(fixed_point64::to_u128(back) == 6);
    }

    #[test]
    fun r3_is_zero() {
        assert!(fixed_point64::is_zero(fixed_point64::from(0)) == true);
        assert!(fixed_point64::is_zero(fixed_point64::from_raw_value(1)) == false);
    }
}
