// scenario 10, round 4 (varied v1.1)
// Abort path enumeration:
//   L68: from() — scaled_value <= MAX_U128 → EOutOfRange
//   L98: from_rational() — denominator != 0 → EZeroDivision
//   L100: from_rational() — quotient != 0 || numerator == 0 → EOutOfRange
//   L101: from_rational() — quotient <= MAX_U128 → EOutOfRange
//   L250: sub() — x_raw >= y_raw → ENegativeResult
//   L268: add() — result <= MAX_U128 → EOutOfRange
//   L299: div() — y.value != 0 → EZeroDivision
//   L317: mul_div() — z.value != 0 → EZeroDivision
//   L337: mul_u128() — MAX_U128 >= product → EMultiplicationOverflow
//   L354: div_down_u128() — denominator.value != 0 → EZeroDivision
//   L357: div_down_u128() — quotient <= MAX_U128 → EDivisionOverflow
//   L374: div_up_u128() — denominator.value != 0 → EZeroDivision
//   L377: div_up_u128() — quotient <= MAX_U128 → EDivisionOverflow
//   L432: exp() — shift_long <= 63 → EOverflowExp

#[test_only]
module suitears::fp64_varied {
    use suitears::fixed_point64;

    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun path_from() { fixed_point64::from(18446744073709551616); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun path_rat_z() { fixed_point64::from_rational(100, 0); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun path_rat_o() { fixed_point64::from_rational(1, 340282366920938463463374607431768211455); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::ENegativeResult)]
    fun path_sub() { fixed_point64::sub(fixed_point64::from(0), fixed_point64::from(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOutOfRange)]
    fun path_add() { fixed_point64::add(fixed_point64::from_raw_value(340282366920938463463374607431768211455), fixed_point64::from_raw_value(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun path_div() { fixed_point64::div(fixed_point64::from(5), fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun path_md() { fixed_point64::mul_div(fixed_point64::from(2), fixed_point64::from(3), fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EMultiplicationOverflow)]
    fun path_mul() { fixed_point64::mul_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(340282366920938463463374607431768211455)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun path_dd0() { fixed_point64::div_down_u128(1, fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun path_ddo() { fixed_point64::div_down_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EZeroDivision)]
    fun path_du0() { fixed_point64::div_up_u128(1, fixed_point64::from(0)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EDivisionOverflow)]
    fun path_duo() { fixed_point64::div_up_u128(340282366920938463463374607431768211455, fixed_point64::from_raw_value(1)); }
    #[test]
    #[expected_failure(abort_code = fixed_point64::EOverflowExp)]
    fun path_exp() { fixed_point64::exp(fixed_point64::from(65)); }

    // boundary comparisons
    #[test]
    fun bound_lt_eq() {
        let a = fixed_point64::from(5);
        let b = fixed_point64::from(5);
        assert!(fixed_point64::lt(a, b) == false);
        assert!(fixed_point64::lte(a, b) == true);
        assert!(fixed_point64::eq(a, b) == true);
    }
    #[test]
    fun bound_gt_eq() {
        let a = fixed_point64::from(10);
        let b = fixed_point64::from(10);
        assert!(fixed_point64::gt(a, b) == false);
        assert!(fixed_point64::gte(a, b) == true);
    }
    #[test]
    fun bound_min_max_equal() {
        let x = fixed_point64::from(7);
        assert!(fixed_point64::value(fixed_point64::min(x, x)) == fixed_point64::value(x));
        assert!(fixed_point64::value(fixed_point64::max(x, x)) == fixed_point64::value(x));
    }
    #[test]
    fun bound_to_u128_floor_ceil() {
        let fp = fixed_point64::from_raw_value(27670116110564327424); // 1.5
        assert!(fixed_point64::to_u128_down(fp) == 1);
        assert!(fixed_point64::to_u128_up(fp) == 2);
        
    }
    #[test]
    fun bound_zero_ops() {
        let z = fixed_point64::from(0);
        assert!(fixed_point64::is_zero(z) == true);
        assert!(fixed_point64::to_u128(z) == 0);
        let sum = fixed_point64::add(z, fixed_point64::from(1));
        assert!(fixed_point64::to_u128(sum) == 1);
    }
}
