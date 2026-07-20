#[test_only]
module integer_mate::i128_brain_r2 {
    use integer_mate::i128::{Self, I128};
    use integer_mate::i64;
    use integer_mate::i32;

    // ============================================================
    // zero()
    // ============================================================

    #[test]
    fun test_zero() {
        let z = i128::zero();
        assert!(z == i128::from(0));
    }

    // ============================================================
    // from() — positive boundary & overflow
    // ============================================================

    #[test]
    fun test_from_zero() {
        let v = i128::from(0);
        assert!(v == i128::zero());
    }

    #[test]
    fun test_from_max() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        assert!(i128::sign(v) == 0);
        assert!(i128::abs_u128(v) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_from_overflow_max_plus_one() {
        i128::from(0x80000000000000000000000000000000);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_from_overflow_u128_max() {
        i128::from(0xffffffffffffffffffffffffffffffff);
    }

    // ============================================================
    // neg_from() — negative boundary & overflow
    // ============================================================

    #[test]
    fun test_neg_from_zero() {
        let v = i128::neg_from(0);
        assert!(i128::sign(v) == 0);
        assert!(i128::abs_u128(v) == 0);
    }

    #[test]
    fun test_neg_from_one() {
        let v = i128::neg_from(1);
        assert!(i128::is_neg(v));
        assert!(i128::abs_u128(v) == 1);
    }

    #[test]
    fun test_neg_from_min() {
        let v = i128::neg_from(0x80000000000000000000000000000000);
        assert!(i128::is_neg(v));
        assert!(i128::abs_u128(v) == 0x80000000000000000000000000000000);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_neg_from_overflow_min_plus_one() {
        i128::neg_from(0x80000000000000000000000000000001);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_neg_from_overflow_u128_max() {
        i128::neg_from(0xffffffffffffffffffffffffffffffff);
    }

    // ============================================================
    // neg() — toggle sign
    // ============================================================

    #[test]
    fun test_neg_positive_to_negative() {
        let v = i128::from(42);
        let n = i128::neg(v);
        assert!(i128::is_neg(n));
        assert!(i128::abs_u128(n) == 42);
    }

    #[test]
    fun test_neg_negative_to_positive() {
        let v = i128::neg_from(42);
        let n = i128::neg(v);
        assert!(i128::sign(n) == 0);
        assert!(i128::abs_u128(n) == 42);
    }

    #[test]
    fun test_neg_zero() {
        let v = i128::zero();
        let n = i128::neg(v);
        assert!(i128::sign(n) == 0);
        assert!(i128::abs_u128(n) == 0);
    }
#[test]
    fun test_neg_max_positive() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        let n = i128::neg(v);
        assert!(i128::is_neg(n));
        assert!(i128::abs_u128(n) == 0x7fffffffffffffffffffffffffffffff);
    }

    // ============================================================
    // add() — overflow paths
    // ============================================================

    #[test]
    fun test_add_zero_zero() {
        let r = i128::add(i128::zero(), i128::zero());
        assert!(r == i128::zero());
    }

    #[test]
    fun test_add_pos_pos_no_overflow() {
        let a = i128::from(100);
        let b = i128::from(200);
        let r = i128::add(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_add_pos_neg() {
        let a = i128::from(500);
        let b = i128::neg_from(200);
        let r = i128::add(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_add_neg_pos() {
        let a = i128::neg_from(500);
        let b = i128::from(200);
        let r = i128::add(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_add_neg_neg_no_overflow() {
        let a = i128::neg_from(100);
        let b = i128::neg_from(200);
        let r = i128::add(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_add_pos_pos_at_max() {
        let a = i128::from(0x7fffffffffffffffffffffffffffffff);
        let b = i128::from(0);
        let r = i128::add(a, b);
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_pos_pos_overflow() {
        let a = i128::from(0x7fffffffffffffffffffffffffffffff);
        let b = i128::from(1);
        i128::add(a, b);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_pos_pos_overflow_large() {
        let a = i128::from(0x40000000000000000000000000000000);
        let b = i128::from(0x40000000000000000000000000000000);
        i128::add(a, b);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_neg_neg_overflow() {
        let a = i128::neg_from(0x80000000000000000000000000000000);
        let b = i128::neg_from(1);
        i128::add(a, b);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_add_neg_neg_overflow_large() {
        let a = i128::neg_from(0x40000000000000000000000000000001);
        let b = i128::neg_from(0x40000000000000000000000000000001);
        i128::add(a, b);
    }

    #[test]
    fun test_add_pos_neg_cancel() {
        let a = i128::from(100);
        let b = i128::neg_from(100);
        let r = i128::add(a, b);
        assert!(r == i128::zero());
    }

    #[test]
    fun test_add_neg_pos_cancel() {
        let a = i128::neg_from(100);
        let b = i128::from(100);
        let r = i128::add(a, b);
        assert!(r == i128::zero());
    }

    #[test]
    fun test_add_pos_neg_result_neg() {
        let a = i128::from(100);
        let b = i128::neg_from(200);
        let r = i128::add(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 100);
    }

    #[test]
    fun test_add_neg_pos_result_pos() {
        let a = i128::neg_from(100);
        let b = i128::from(200);
        let r = i128::add(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 100);
    }

    // ============================================================
    // sub() — overflow paths
    // ============================================================

    #[test]
    fun test_sub_zero_zero() {
        let r = i128::sub(i128::zero(), i128::zero());
        assert!(r == i128::zero());
    }

    #[test]
    fun test_sub_pos_pos_no_overflow() {
        let a = i128::from(500);
        let b = i128::from(200);
        let r = i128::sub(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_sub_pos_pos_result_neg() {
        let a = i128::from(100);
        let b = i128::from(200);
        let r = i128::sub(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 100);
    }

    #[test]
    fun test_sub_pos_neg() {
        let a = i128::from(100);
        let b = i128::neg_from(200);
        let r = i128::sub(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_sub_neg_pos() {
        let a = i128::neg_from(100);
        let b = i128::from(200);
        let r = i128::sub(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_sub_neg_neg_no_overflow() {
        let a = i128::neg_from(500);
        let b = i128::neg_from(200);
        let r = i128::sub(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 300);
    }

    #[test]
    fun test_sub_neg_neg_result_pos() {
        let a = i128::neg_from(100);
        let b = i128::neg_from(200);
        let r = i128::sub(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 100);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_sub_pos_neg_overflow() {
        let a = i128::from(0x7fffffffffffffffffffffffffffffff);
        let b = i128::neg_from(1);
        i128::sub(a, b);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_sub_neg_pos_overflow() {
        let a = i128::neg_from(0x80000000000000000000000000000000);
        let b = i128::from(1);
        i128::sub(a, b);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_sub_pos_pos_overflow() {
        let a = i128::from(0x7fffffffffffffffffffffffffffffff);
        let b = i128::neg_from(0x80000000000000000000000000000000);
        i128::sub(a, b);
    }

    #[test]
    fun test_sub_self() {
        let a = i128::from(42);
        let r = i128::sub(a, a);
        assert!(r == i128::zero());
    }

    // ============================================================
    // mul() — sign combinations & overflow
    // ============================================================

    #[test]
    fun test_mul_zero_by_pos() {
        let r = i128::mul(i128::zero(), i128::from(100));
        assert!(r == i128::zero());
    }

    #[test]
    fun test_mul_zero_by_neg() {
        let r = i128::mul(i128::zero(), i128::neg_from(100));
        assert!(r == i128::zero());
    }

    #[test]
    fun test_mul_pos_pos_no_overflow() {
        let a = i128::from(3);
        let b = i128::from(7);
        let r = i128::mul(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 21);
    }

    #[test]
    fun test_mul_pos_neg() {
        let a = i128::from(3);
        let b = i128::neg_from(7);
        let r = i128::mul(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 21);
    }

    #[test]
    fun test_mul_neg_pos() {
        let a = i128::neg_from(3);
        let b = i128::from(7);
        let r = i128::mul(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 21);
    }

    #[test]
    fun test_mul_neg_neg() {
        let a = i128::neg_from(3);
        let b = i128::neg_from(7);
        let r = i128::mul(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 21);
    }

    #[test]
    fun test_mul_one_pos() {
        let a = i128::from(1);
        let b = i128::from(0x7fffffffffffffffffffffffffffffff);
        let r = i128::mul(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_mul_one_neg() {
        let a = i128::from(1);
        let b = i128::neg_from(0x80000000000000000000000000000000);
        let r = i128::mul(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 0x80000000000000000000000000000000);
    }

    #[test]
    fun test_mul_neg_one_pos() {
        let a = i128::neg_from(1);
        let b = i128::from(0x7fffffffffffffffffffffffffffffff);
        let r = i128::mul(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_pos_pos_overflow() {
        let a = i128::from(0x40000000000000000000000000000000);
        let b = i128::from(2);
        i128::mul(a, b);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_neg_neg_overflow() {
        let a = i128::neg_from(0x40000000000000000000000000000000);
        let b = i128::neg_from(2);
        i128::mul(a, b);
    }
#[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_mul_min_neg_by_neg_one_overflow() {
        let a = i128::neg_from(0x80000000000000000000000000000000);
        let b = i128::neg_from(1);
        i128::mul(a, b);
    }

    // ============================================================
    // div() — sign combinations & boundary
    // ============================================================

    #[test]
    fun test_div_pos_pos_exact() {
        let a = i128::from(21);
        let b = i128::from(7);
        let r = i128::div(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 3);
    }

    #[test]
    fun test_div_pos_pos_truncate() {
        let a = i128::from(22);
        let b = i128::from(7);
        let r = i128::div(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 3);
    }

    #[test]
    fun test_div_pos_neg() {
        let a = i128::from(21);
        let b = i128::neg_from(7);
        let r = i128::div(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 3);
    }

    #[test]
    fun test_div_neg_pos() {
        let a = i128::neg_from(21);
        let b = i128::from(7);
        let r = i128::div(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 3);
    }

    #[test]
    fun test_div_neg_neg() {
        let a = i128::neg_from(21);
        let b = i128::neg_from(7);
        let r = i128::div(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 3);
    }

    #[test]
    fun test_div_zero_by_pos() {
        let r = i128::div(i128::zero(), i128::from(100));
        assert!(r == i128::zero());
    }

    #[test]
    fun test_div_zero_by_neg() {
        let r = i128::div(i128::zero(), i128::neg_from(100));
        assert!(r == i128::zero());
    }

    #[test]
    fun test_div_max_by_one() {
        let a = i128::from(0x7fffffffffffffffffffffffffffffff);
        let b = i128::from(1);
        let r = i128::div(a, b);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_div_min_neg_by_one() {
        let a = i128::neg_from(0x80000000000000000000000000000000);
        let b = i128::from(1);
        let r = i128::div(a, b);
        assert!(i128::is_neg(r));
        assert!(i128::abs_u128(r) == 0x80000000000000000000000000000000);
    }
#[test]
    fun test_div_self_pos() {
        let a = i128::from(42);
        let r = i128::div(a, a);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 1);
    }

    #[test]
    fun test_div_self_neg() {
        let a = i128::neg_from(42);
        let r = i128::div(a, a);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 1);
    }

    // ============================================================
    // abs() — overflow on MIN negative
    // ============================================================

    #[test]
    fun test_abs_zero() {
        let r = i128::abs(i128::zero());
        assert!(r == i128::zero());
    }

    #[test]
    fun test_abs_positive() {
        let v = i128::from(42);
        let r = i128::abs(v);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 42);
    }

    #[test]
    fun test_abs_negative() {
        let v = i128::neg_from(42);
        let r = i128::abs(v);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 42);
    }

    #[test]
    fun test_abs_max_positive() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        let r = i128::abs(v);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_abs_max_negative() {
        let v = i128::neg_from(0x7fffffffffffffffffffffffffffffff);
        let r = i128::abs(v);
        assert!(i128::sign(r) == 0);
        assert!(i128::abs_u128(r) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun test_abs_min_negative_overflow() {
        let v = i128::neg_from(0x80000000000000000000000000000000);
        i128::abs(v);
    }

    // ============================================================
    // abs_u128() — no overflow possible, but boundary
    // ============================================================

    #[test]
    fun test_abs_u128_zero() {
        assert!(i128::abs_u128(i128::zero()) == 0);
    }

    #[test]
    fun test_abs_u128_positive() {
        let v = i128::from(42);
        assert!(i128::abs_u128(v) == 42);
    }

    #[test]
    fun test_abs_u128_negative() {
        let v = i128::neg_from(42);
        assert!(i128::abs_u128(v) == 42);
    }

    #[test]
    fun test_abs_u128_max_positive() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        assert!(i128::abs_u128(v) == 0x7fffffffffffffffffffffffffffffff);
    }

    #[test]
    fun test_abs_u128_min_negative() {
        let v = i128::neg_from(0x80000000000000000000000000000000);
        assert!(i128::abs_u128(v) == 0x80000000000000000000000000000000);
    }

    // ============================================================
    // sign() & is_neg()
    // ============================================================

    #[test]
    fun test_sign_zero() {
        assert!(i128::sign(i128::zero()) == 0);
        assert!(!i128::is_neg(i128::zero()));
    }

    #[test]
    fun test_sign_positive() {
        let v = i128::from(1);
        assert!(i128::sign(v) == 0);
        assert!(!i128::is_neg(v));
    }

    #[test]
    fun test_sign_negative() {
        let v = i128::neg_from(1);
        assert!(i128::sign(v) == 1);
        assert!(i128::is_neg(v));
    }

    #[test]
    fun test_sign_max_positive() {
        let v = i128::from(0x7fffffffffffffffffffffffffffffff);
        assert!(i128::sign(v) == 0);
    }

    #[test]
    fun test_sign_min_negative() {
        let v = i128::neg_from(0x80000000000000000000000000000000);
        assert!(i128::sign(v) == 1);
    }

    // ============================================================
    // eq()
    // ============================================================

    #[test]
    fun test_eq_same() {
        assert!(i128::eq(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_eq_diff() {
        assert!(!i128::eq(i128::from(42), i128::from(43)));
    }

    #[test]
    fun test_eq_pos_neg_same_magnitude() {
        assert!(!i128::eq(i128::from(42), i128::neg_from(42)));
    }

    #[test]
    fun test_eq_zero() {
        assert!(i128::eq(i128::zero(), i128::zero()));
    }

    // ============================================================
    // gt()
    // ============================================================

    #[test]
    fun test_gt_pos_pos_true() {
        assert!(i128::gt(i128::from(100), i128::from(50)));
    }

    #[test]
    fun test_gt_pos_pos_false() {
        assert!(!i128::gt(i128::from(50), i128::from(100)));
    }

    #[test]
    fun test_gt_pos_neg() {
        assert!(i128::gt(i128::from(1), i128::neg_from(100)));
    }

    #[test]
    fun test_gt_neg_pos() {
        assert!(!i128::gt(i128::neg_from(1), i128::from(100)));
    }

    #[test]
    fun test_gt_neg_neg_true() {
        assert!(i128::gt(i128::neg_from(50), i128::neg_from(100)));
    }

    #[test]
    fun test_gt_neg_neg_false() {
        assert!(!i128::gt(i128::neg_from(100), i128::neg_from(50)));
    }

    #[test]
    fun test_gt_equal() {
        assert!(!i128::gt(i128::from(42), i128::from(42)));
    }

    // ============================================================
    // lt()
    // ============================================================

    #[test]
    fun test_lt_pos_pos_true() {
        assert!(i128::lt(i128::from(50), i128::from(100)));
    }

    #[test]
    fun test_lt_pos_pos_false() {
        assert!(!i128::lt(i128::from(100), i128::from(50)));
    }

    #[test]
    fun test_lt_pos_neg() {
        assert!(!i128::lt(i128::from(1), i128::neg_from(100)));
    }

    #[test]
    fun test_lt_neg_pos() {
        assert!(i128::lt(i128::neg_from(1), i128::from(100)));
    }

    #[test]
    fun test_lt_neg_neg_true() {
        assert!(i128::lt(i128::neg_from(100), i128::neg_from(50)));
    }

    #[test]
    fun test_lt_neg_neg_false() {
        assert!(!i128::lt(i128::neg_from(50), i128::neg_from(100)));
    }

    #[test]
    fun test_lt_equal() {
        assert!(!i128::lt(i128::from(42), i128::from(42)));
    }

    // ============================================================
    // gte()
    // ============================================================

    #[test]
    fun test_gte_greater() {
        assert!(i128::gte(i128::from(100), i128::from(50)));
    }

    #[test]
    fun test_gte_equal() {
        assert!(i128::gte(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_gte_less() {
        assert!(!i128::gte(i128::from(50), i128::from(100)));
    }

    #[test]
    fun test_gte_pos_neg() {
        assert!(i128::gte(i128::from(1), i128::neg_from(100)));
    }

    #[test]
    fun test_gte_neg_pos() {
        assert!(!i128::gte(i128::neg_from(1), i128::from(100)));
    }

    // ============================================================
    // lte()
    // ============================================================

    #[test]
    fun test_lte_less() {
        assert!(i128::lte(i128::from(50), i128::from(100)));
    }

    #[test]
    fun test_lte_equal() {
        assert!(i128::lte(i128::from(42), i128::from(42)));
    }

    #[test]
    fun test_lte_greater() {
        assert!(!i128::lte(i128::from(100), i128::from(50)));
    }

    #[test]
    fun test_lte_neg_pos() {
        assert!(i128::lte(i128::neg_from(1), i128::from(100)));
    }

    #[test]
    fun test_lte_pos_neg() {
        assert!(!i128::lte(i128::from(1), i128::neg_from(100)));
    }
}
