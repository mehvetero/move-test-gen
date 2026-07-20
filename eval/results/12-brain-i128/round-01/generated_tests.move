#[test_only]
module integer_mate::i128_brain_tests {
    use integer_mate::i128::{Self, I128};

    // ============================================================
    // zero()
    // ============================================================
    #[test]
    fun test_zero() {
        let z = i128::zero();
        assert!(i128::as_u128(z) == 0);
    }

    // ============================================================
    // from()
    // ============================================================
    #[test]
    fun test_from_zero() {
        let v = i128::from(0);
        assert!(i128::as_u128(v) == 0);
    }

    #[test]
    fun test_from_max() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        assert!(i128::as_u128(v) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_from_one() {
        let v = i128::from(1);
        assert!(i128::as_u128(v) == 1);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_from_overflow() {
        i128::from(0x80000000000000000000000000000000);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_from_overflow_max_plus_one() {
        i128::from(0x7fffffffffffffffffffffffffffffff + 1);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_from_overflow_u128_max() {
        i128::from(0xffffffffffffffffffffffffffffffff);
    }

    // ============================================================
    // neg_from()
    // ============================================================
    #[test]
    fun test_neg_from_zero() {
        let v = i128::neg_from(0);
        assert!(i128::as_u128(v) == 0);
    }
#[test]
    fun test_neg_from_min_magnitude() {
        let v = i128::neg_from(0x80000000000000000000000000000000);
        assert!(i128::as_u128(v) == 0x80000000000000000000000000000000);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_neg_from_overflow() {
        i128::neg_from(0x80000000000000000000000000000001);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_neg_from_overflow_u128_max() {
        i128::neg_from(0xffffffffffffffffffffffffffffffff);
    }

    // ============================================================
    // neg()
    // ============================================================
    #[test]
    fun test_neg_zero() {
        let v = i128::neg(i128::zero());
        assert!(i128::as_u128(v) == 0);
    }
#[test]
    fun test_neg_negative_to_positive() {
        let v = i128::neg(i128::neg_from(5));
        assert!(i128::as_u128(v) == 5);
    }
#[test]
    fun test_neg_max_positive() {
        let v = i128::neg(i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(i128::as_u128(v) == 0x80000000000000000000000000000001);
    }

    // ============================================================
    // add()
    // ============================================================
    #[test]
    fun test_add_zero_zero() {
        let r = i128::add(i128::zero(), i128::zero());
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_add_zero_positive() {
        let r = i128::add(i128::zero(), i128::from(42));
        assert!(i128::as_u128(r) == 42);
    }

    #[test]
    fun test_add_positive_zero() {
        let r = i128::add(i128::from(42), i128::zero());
        assert!(i128::as_u128(r) == 42);
    }
#[test]
    fun test_add_pos_pos() {
        let r = i128::add(i128::from(100), i128::from(200));
        assert!(i128::as_u128(r) == 300);
    }
#[test]
    fun test_add_pos_neg_result_pos() {
        let r = i128::add(i128::from(200), i128::neg_from(100));
        assert!(i128::as_u128(r) == 100);
    }
#[test]
    fun test_add_neg_pos_result_pos() {
        let r = i128::add(i128::neg_from(100), i128::from(200));
        assert!(i128::as_u128(r) == 100);
    }
#[test]
    fun test_add_pos_pos_to_max() {
        let r = i128::add(i128::from(0x7fffffffffffffffffffffffffffffff), i128::zero());
        assert!(i128::as_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_pos_pos_overflow() {
        i128::add(i128::from(0x7fffffffffffffffffffffffffffffff), i128::from(1));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_pos_pos_overflow_large() {
        i128::add(i128::from(0x7ffffffffffffffffffffffffffffff0), i128::from(0x10));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_neg_neg_overflow() {
        i128::add(i128::neg_from(0x80000000000000000000000000000000), i128::neg_from(1));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_neg_neg_overflow_large() {
        i128::add(i128::neg_from(0x80000000000000000000000000000000), i128::neg_from(0x100));
    }

    #[test]
    fun test_add_pos_neg_boundary_max_pos() {
        let r = i128::add(i128::from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(1));
        assert!(i128::as_u128(r) == 0x7ffffffffffffffffffffffffffffffe);
    }

    #[test]
    fun test_add_neg_pos_boundary_min_neg() {
        let r = i128::add(i128::neg_from(0x80000000000000000000000000000000), i128::from(1));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000001);
    }

    #[test]
    fun test_add_opposite_signs_cancel() {
        let r = i128::add(i128::from(100), i128::neg_from(100));
        assert!(i128::as_u128(r) == 0);
    }

    // ============================================================
    // sub()
    // ============================================================
    #[test]
    fun test_sub_zero_zero() {
        let r = i128::sub(i128::zero(), i128::zero());
        assert!(i128::as_u128(r) == 0);
    }
#[test]
    fun test_sub_positive_zero() {
        let r = i128::sub(i128::from(42), i128::zero());
        assert!(i128::as_u128(r) == 42);
    }

    #[test]
    fun test_sub_zero_negative() {
        let r = i128::sub(i128::zero(), i128::neg_from(42));
        assert!(i128::as_u128(r) == 42);
    }
#[test]
    fun test_sub_pos_pos_result_pos() {
        let r = i128::sub(i128::from(200), i128::from(100));
        assert!(i128::as_u128(r) == 100);
    }
#[test]
    fun test_sub_neg_neg_result_pos() {
        let r = i128::sub(i128::neg_from(100), i128::neg_from(200));
        assert!(i128::as_u128(r) == 100);
    }
#[test]
    fun test_sub_pos_neg() {
        let r = i128::sub(i128::from(100), i128::neg_from(200));
        assert!(i128::as_u128(r) == 300);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_sub_pos_neg_overflow() {
        i128::sub(i128::from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(1));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_sub_neg_pos_overflow() {
        i128::sub(i128::neg_from(0x80000000000000000000000000000000), i128::from(1));
    }

    #[test]
    fun test_sub_pos_pos_boundary() {
        let r = i128::sub(i128::from(0x7fffffffffffffffffffffffffffffff), i128::from(1));
        assert!(i128::as_u128(r) == 0x7ffffffffffffffffffffffffffffffe);
    }

    #[test]
    fun test_sub_neg_neg_boundary() {
        let r = i128::sub(i128::neg_from(0x80000000000000000000000000000000), i128::neg_from(1));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000001);
    }

    #[test]
    fun test_sub_same_value() {
        let r = i128::sub(i128::from(100), i128::from(100));
        assert!(i128::as_u128(r) == 0);
    }

    // ============================================================
    // mul()
    // ============================================================
    #[test]
    fun test_mul_zero_zero() {
        let r = i128::mul(i128::zero(), i128::zero());
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_mul_zero_positive() {
        let r = i128::mul(i128::zero(), i128::from(42));
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_mul_positive_zero() {
        let r = i128::mul(i128::from(42), i128::zero());
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_mul_zero_negative() {
        let r = i128::mul(i128::zero(), i128::neg_from(42));
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_mul_negative_zero() {
        let r = i128::mul(i128::neg_from(42), i128::zero());
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_mul_pos_pos() {
        let r = i128::mul(i128::from(6), i128::from(7));
        assert!(i128::as_u128(r) == 42);
    }

    #[test]
    fun test_mul_neg_neg() {
        let r = i128::mul(i128::neg_from(6), i128::neg_from(7));
        assert!(i128::as_u128(r) == 42);
    }
#[test]
    fun test_mul_one_pos() {
        let r = i128::mul(i128::from(1), i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(i128::as_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_mul_one_neg() {
        let r = i128::mul(i128::from(1), i128::neg_from(0x80000000000000000000000000000000));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000000);
    }

    #[test]
    fun test_mul_neg_one_pos() {
        let r = i128::mul(i128::neg_from(1), i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000001);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_pos_pos_overflow() {
        i128::mul(i128::from(2), i128::from(0x40000000000000000000000000000000));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_pos_pos_overflow_large() {
        i128::mul(i128::from(0x7fffffffffffffffffffffffffffffff), i128::from(2));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_neg_neg_overflow() {
        i128::mul(i128::neg_from(2), i128::neg_from(0x40000000000000000000000000000000));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_neg_neg_overflow_large() {
        i128::mul(i128::neg_from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(2));
    }
#[test]
    fun test_mul_boundary_pos() {
        let r = i128::mul(i128::from(0x7fffffffffffffffffffffffffffffff), i128::from(1));
        assert!(i128::as_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_mul_boundary_neg() {
        let r = i128::mul(i128::neg_from(0x80000000000000000000000000000000), i128::from(1));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000000);
    }

    #[test]
    fun test_mul_large_no_overflow() {
        let r = i128::mul(i128::from(0x10000000000000000000000000000000), i128::from(7));
        assert!(i128::as_u128(r) == 0x70000000000000000000000000000000);
    }

    // ============================================================
    // div()
    // ============================================================
    #[test]
    fun test_div_zero_positive() {
        let r = i128::div(i128::zero(), i128::from(42));
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_div_zero_negative() {
        let r = i128::div(i128::zero(), i128::neg_from(42));
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_div_pos_pos() {
        let r = i128::div(i128::from(42), i128::from(7));
        assert!(i128::as_u128(r) == 6);
    }

    #[test]
    fun test_div_neg_neg() {
        let r = i128::div(i128::neg_from(42), i128::neg_from(7));
        assert!(i128::as_u128(r) == 6);
    }
#[test]
    fun test_div_one_by_one() {
        let r = i128::div(i128::from(1), i128::from(1));
        assert!(i128::as_u128(r) == 1);
    }

    #[test]
    fun test_div_max_by_one() {
        let r = i128::div(i128::from(0x7fffffffffffffffffffffffffffffff), i128::from(1));
        assert!(i128::as_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_div_min_neg_by_one() {
        let r = i128::div(i128::neg_from(0x80000000000000000000000000000000), i128::from(1));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000000);
    }

    #[test]
    fun test_div_max_by_neg_one() {
        let r = i128::div(i128::from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(1));
        assert!(i128::as_u128(r) == 0x80000000000000000000000000000001);
    }
#[test]
    fun test_div_truncation_pos() {
        let r = i128::div(i128::from(10), i128::from(3));
        assert!(i128::as_u128(r) == 3);
    }
#[test]
    fun test_div_truncation_neg_neg() {
        let r = i128::div(i128::neg_from(10), i128::neg_from(3));
        assert!(i128::as_u128(r) == 3);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_div_min_neg_by_neg_one_overflow() {
        i128::div(i128::neg_from(0x80000000000000000000000000000000), i128::neg_from(1));
    }

    #[test]
    fun test_div_large_numbers() {
        let r = i128::div(i128::from(0x70000000000000000000000000000000), i128::from(0x10000000000000000000000000000000));
        assert!(i128::as_u128(r) == 7);
    }

    // ============================================================
    // abs()
    // ============================================================
    #[test]
    fun test_abs_zero() {
        let r = i128::abs(i128::zero());
        assert!(i128::as_u128(r) == 0);
    }

    #[test]
    fun test_abs_positive() {
        let r = i128::abs(i128::from(42));
        assert!(i128::as_u128(r) == 42);
    }

    #[test]
    fun test_abs_negative() {
        let r = i128::abs(i128::neg_from(42));
        assert!(i128::as_u128(r) == 42);
    }

    #[test]
    fun test_abs_max_positive() {
        let r = i128::abs(i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(i128::as_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_abs_overflow_min_neg_plus_one() {
        i128::abs(i128::neg_from(0x80000000000000000000000000000001));
    }

    #[test]
    fun test_abs_negative_one() {
        let r = i128::abs(i128::neg_from(1));
        assert!(i128::as_u128(r) == 1);
    }

    // ============================================================
    // abs_u128()
    // ============================================================
    #[test]
    fun test_abs_u128_zero() {
        let r = i128::abs_u128(i128::zero());
        assert!(r == 0);
    }

    #[test]
    fun test_abs_u128_positive() {
        let r = i128::abs_u128(i128::from(42));
        assert!(r == 42);
    }

    #[test]
    fun test_abs_u128_negative() {
        let r = i128::abs_u128(i128::neg_from(42));
        assert!(r == 42);
    }

    #[test]
    fun test_abs_u128_max_positive() {
        let r = i128::abs_u128(i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(r == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_abs_u128_min_negative() {
        let r = i128::abs_u128(i128::neg_from(0x80000000000000000000000000000000));
        assert!(r == 0x80000000000000000000000000000000);
    }

    #[test]
    fun test_abs_u128_negative_one() {
        let r = i128::abs_u128(i128::neg_from(1));
        assert!(r == 1);
    }

    // ============================================================
    // sign()
    // ============================================================
    #[test]
    fun test_sign_zero() {
        let r = i128::sign(i128::zero());
        assert!(r == 0);
    }

    #[test]
    fun test_sign_positive() {
        let r = i128::sign(i128::from(42));
        assert!(r == 0);
    }

    #[test]
    fun test_sign_negative() {
        let r = i128::sign(i128::neg_from(42));
        assert!(r == 1);
    }

    #[test]
    fun test_sign_max_positive() {
        let r = i128::sign(i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(r == 0);
    }

    #[test]
    fun test_sign_min_negative() {
        let r = i128::sign(i128::neg_from(0x80000000000000000000000000000000));
        assert!(r == 1);
    }

    #[test]
    fun test_sign_boundary_positive() {
        let r = i128::sign(i128::from(0x7fffffffffffffffffffffffffffffff));
        assert!(r == 0);
    }

    #[test]
    fun test_sign_boundary_negative() {
        let r = i128::sign(i128::neg_from(1));
        assert!(r == 1);
    }

    // ============================================================
    // is_neg()
    // ============================================================
    #[test]
    fun test_is_neg_zero() {
        assert!(!i128::is_neg(i128::zero()));
    }

    #[test]
    fun test_is_neg_positive() {
        assert!(!i128::is_neg(i128::from(42)));
    }

    #[test]
    fun test_is_neg_negative() {
        assert!(i128::is_neg(i128::neg_from(42)));
    }

    #[test]
    fun test_is_neg_max_positive() {
        assert!(!i128::is_neg(i128::from(0x7fffffffffffffffffffffffffffffff)));
    }

    #[test]
    fun test_is_neg_min_negative() {
        assert!(i128::is_neg(i128::neg_from(0x80000000000000000000000000000000)));
    }

    // ============================================================
    // eq()
    // ============================================================
    #[test]
    fun test_eq_same_zero() {
        assert!(i128::eq(i128::zero(), i128::zero()));
    }

    #[test]
    fun test_eq_same_positive() {
        assert!(i128::eq(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_eq_same_negative() {
        assert!(i128::eq(i128::neg_from(42), i128::neg_from(42)));
    }

    #[test]
    fun test_eq_different() {
        assert!(!i128::eq(i128::from(42), i128::from(43)));
    }

    #[test]
    fun test_eq_pos_neg_same_magnitude() {
        assert!(!i128::eq(i128::from(42), i128::neg_from(42)));
    }

    #[test]
    fun test_eq_zero_neg_zero() {
        assert!(i128::eq(i128::zero(), i128::neg_from(0)));
    }

    #[test]
    fun test_eq_max_min() {
        assert!(!i128::eq(i128::from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(0x80000000000000000000000000000000)));
    }

    // ============================================================
    // gt()
    // ============================================================
    #[test]
    fun test_gt_pos_pos_true() {
        assert!(i128::gt(i128::from(43), i128::from(42)));
    }

    #[test]
    fun test_gt_pos_pos_false() {
        assert!(!i128::gt(i128::from(42), i128::from(43)));
    }

    #[test]
    fun test_gt_pos_pos_equal() {
        assert!(!i128::gt(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_gt_neg_neg_true() {
        assert!(i128::gt(i128::neg_from(42), i128::neg_from(43)));
    }

    #[test]
    fun test_gt_neg_neg_false() {
        assert!(!i128::gt(i128::neg_from(43), i128::neg_from(42)));
    }

    #[test]
    fun test_gt_pos_neg() {
        assert!(i128::gt(i128::from(1), i128::neg_from(42)));
    }

    #[test]
    fun test_gt_neg_pos() {
        assert!(!i128::gt(i128::neg_from(1), i128::from(42)));
    }

    #[test]
    fun test_gt_zero_neg() {
        assert!(i128::gt(i128::zero(), i128::neg_from(1)));
    }

    #[test]
    fun test_gt_zero_pos() {
        assert!(!i128::gt(i128::zero(), i128::from(1)));
    }

    #[test]
    fun test_gt_max_min() {
        assert!(i128::gt(i128::from(0x7fffffffffffffffffffffffffffffff), i128::neg_from(0x80000000000000000000000000000000)));
    }

    // ============================================================
    // lt()
    // ============================================================
    #[test]
    fun test_lt_pos_pos_true() {
        assert!(i128::lt(i128::from(42), i128::from(43)));
    }

    #[test]
    fun test_lt_pos_pos_false() {
        assert!(!i128::lt(i128::from(43), i128::from(42)));
    }

    #[test]
    fun test_lt_pos_pos_equal() {
        assert!(!i128::lt(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_lt_neg_neg_true() {
        assert!(i128::lt(i128::neg_from(43), i128::neg_from(42)));
    }

    #[test]
    fun test_lt_neg_neg_false() {
        assert!(!i128::lt(i128::neg_from(42), i128::neg_from(43)));
    }

    #[test]
    fun test_lt_pos_neg() {
        assert!(!i128::lt(i128::from(1), i128::neg_from(42)));
    }

    #[test]
    fun test_lt_neg_pos() {
        assert!(i128::lt(i128::neg_from(1), i128::from(42)));
    }

    #[test]
    fun test_lt_zero_neg() {
        assert!(!i128::lt(i128::zero(), i128::neg_from(1)));
    }

    #[test]
    fun test_lt_zero_pos() {
        assert!(i128::lt(i128::zero(), i128::from(1)));
    }
}
