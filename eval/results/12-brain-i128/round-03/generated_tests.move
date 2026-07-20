#[test_only]
module integer_mate::i128_brain_r3 {
    use integer_mate::i128;

    #[test]
    fun r3_from_max() {
        let v = i128::from(170141183460469231731687303715884105727);
        assert!(i128::as_u128(v) == 170141183460469231731687303715884105727);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_from_overflow() {
        i128::from(170141183460469231731687303715884105728);
    }

    #[test]
    fun r3_neg_from_max() {
        let v = i128::neg_from(170141183460469231731687303715884105728);
        assert!(i128::abs_u128(v) == 170141183460469231731687303715884105728);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_neg_from_overflow() {
        i128::neg_from(170141183460469231731687303715884105729);
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_add_overflow() {
        i128::add(i128::from(170141183460469231731687303715884105727), i128::from(1));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_sub_overflow() {
        i128::sub(i128::neg_from(170141183460469231731687303715884105728), i128::from(1));
    }

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_neg_min() {
        i128::neg(i128::neg_from(170141183460469231731687303715884105728));
    }

    #[test]
    fun r3_add_basic() {
        let sum = i128::add(i128::from(50), i128::from(70));
        assert!(i128::as_u128(sum) == 120);
    }

    #[test]
    fun r3_mul_pos_pos() {
        assert!(i128::as_u128(i128::mul(i128::from(6), i128::from(7))) == 42);
    }

    #[test]
    fun r3_mul_neg_neg() {
        let p = i128::mul(i128::neg_from(6), i128::neg_from(7));
        assert!(i128::as_u128(p) == 42);
        assert!(i128::sign(p) == 0);
    }

    #[test]
    fun r3_div_pos_pos() {
        assert!(i128::as_u128(i128::div(i128::from(42), i128::from(6))) == 7);
    }

    #[test]
    fun r3_cmp() {
        assert!(i128::lt(i128::neg_from(1), i128::from(1)) == true);
        assert!(i128::gt(i128::from(1), i128::neg_from(1)) == true);
        assert!(i128::eq(i128::from(5), i128::from(5)) == true);
    }

    #[test]
    fun r3_zero() {
        let z = i128::zero();
        assert!(i128::as_u128(z) == 0);
        assert!(i128::sign(z) == 0);
    }

    #[test]
    fun r3_abs() {
        assert!(i128::abs_u128(i128::neg_from(99)) == 99);
        assert!(i128::abs_u128(i128::from(99)) == 99);
    }
}
