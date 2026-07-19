// scenario 10, round 2 (main v1.1)
#[test_only]
module suitears::fp64_r2 {
    use suitears::fixed_point64;

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r2_from_overflow() { fixed_point64::from(18446744073709551616); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r2_rational_zero() { fixed_point64::from_rational(1, 0); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r2_rational_overflow() { fixed_point64::from_rational(1, 340282366920938463463374607431768211455); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::ENegativeResult)]
    fun r2_sub_neg() { fixed_point64::sub(fixed_point64::from(1), fixed_point64::from(2)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun r2_add_overflow() {
        fixed_point64::add(fixed_point64::from_raw_value(340282366920938463463374607431768211455), fixed_point64::from(1));
    }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r2_div_zero() { fixed_point64::div(fixed_point64::from(1), fixed_point64::from(0)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r2_mul_div_zero() { fixed_point64::mul_div(fixed_point64::from(1), fixed_point64::from(1), fixed_point64::from(0)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EMultiplicationOverflow)]
    fun r2_mul_overflow() {
        fixed_point64::mul_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(340282366920938463463374607431768211455));
    }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r2_div_down_zero() { fixed_point64::div_down_u128(100, fixed_point64::from(0)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun r2_div_down_overflow() { fixed_point64::div_down_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun r2_div_up_zero() { fixed_point64::div_up_u128(100, fixed_point64::from(0)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun r2_div_up_overflow() { fixed_point64::div_up_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOverflowExp)]
    fun r2_exp_overflow() { fixed_point64::exp(fixed_point64::from(64)); }

    // functional — targeting survivors from R1

    #[test]
    fun r2_from_rational_exact() {
        let fp = fixed_point64::from_rational(1, 2);
        // 0.5 in fixed point = 2^63
        assert!(fixed_point64::value(fp) == 9223372036854775808);
    }

    #[test]
    fun r2_to_u128() {
        let fp = fixed_point64::from(42);
        assert!(fixed_point64::to_u128(fp) == 42);
    }

    #[test]
    fun r2_to_u128_down() {
        // 1.5 → floor = 1
        let fp = fixed_point64::from_raw_value(27670116110564327424); // 1.5 * 2^64
        assert!(fixed_point64::to_u128_down(fp) == 1);
    }

    #[test]
    fun r2_to_u128_up() {
        // 1.5 → ceil = 2
        let fp = fixed_point64::from_raw_value(27670116110564327424);
        assert!(fixed_point64::to_u128_up(fp) == 2);
    }

    #[test]
    fun r2_is_zero() {
        assert!(fixed_point64::is_zero(fixed_point64::from(0)) == true);
        assert!(fixed_point64::is_zero(fixed_point64::from(1)) == false);
    }

    #[test]
    fun r2_comparisons() {
        let a = fixed_point64::from(5);
        let b = fixed_point64::from(10);
        assert!(fixed_point64::lt(a, b) == true);
        assert!(fixed_point64::gt(b, a) == true);
        assert!(fixed_point64::lte(a, a) == true);
        assert!(fixed_point64::gte(b, b) == true);
        assert!(fixed_point64::eq(a, a) == true);
    }

    #[test]
    fun r2_min_max() {
        let a = fixed_point64::from(3);
        let b = fixed_point64::from(7);
        assert!(fixed_point64::value(fixed_point64::min(a, b)) == fixed_point64::value(a));
        assert!(fixed_point64::value(fixed_point64::max(a, b)) == fixed_point64::value(b));
    }

    #[test]
    fun r2_pow() {
        let two = fixed_point64::from(2);
        let result = fixed_point64::pow(two, 3);
        assert!(fixed_point64::to_u128(result) == 8);
    }

    #[test]
    fun r2_sqrt() {
        let four = fixed_point64::from(4);
        let result = fixed_point64::sqrt(four);
        assert!(fixed_point64::to_u128(result) == 2);
    }
}
