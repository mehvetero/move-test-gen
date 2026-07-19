// scenario 11, round 2 (main v1.1)
#[test_only]
module integer_mate::i128_r2 {
    use integer_mate::i128;

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r2_from() { i128::from(170141183460469231731687303715884105728); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r2_neg_from() { i128::neg_from(170141183460469231731687303715884105729); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r2_add() { i128::add(i128::from(170141183460469231731687303715884105727), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r2_sub() { i128::sub(i128::neg_from(170141183460469231731687303715884105728), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r2_neg_min() { i128::neg(i128::neg_from(170141183460469231731687303715884105728)); }

    // targeting survivors: L183/186/194 (mul sign logic) + L76 (add overflow check)
    #[test]
    fun r2_mul_neg_neg() {
        let a = i128::neg_from(7);
        let b = i128::neg_from(6);
        let p = i128::mul(a, b);
        assert!(i128::as_u128(p) == 42);
        assert!(i128::sign(p) == 0); // positive
    }

    #[test]
    fun r2_mul_pos_neg() {
        let a = i128::from(7);
        let b = i128::neg_from(6);
        let p = i128::mul(a, b);
        assert!(i128::abs_u128(p) == 42);
        assert!(i128::sign(p) == 1); // negative
    }

    #[test]
    fun r2_mul_zero() {
        let a = i128::from(999);
        let z = i128::zero();
        let p = i128::mul(a, z);
        assert!(i128::as_u128(p) == 0);
    }

    #[test]
    fun r2_div_neg() {
        let a = i128::neg_from(42);
        let b = i128::from(7);
        let q = i128::div(a, b);
        assert!(i128::abs_u128(q) == 6);
        assert!(i128::sign(q) == 1);
    }

    #[test]
    fun r2_overflowing_add() {
        let max = i128::from(170141183460469231731687303715884105727);
        let one = i128::from(1);
        let (_, overflow) = i128::overflowing_add(max, one);
        assert!(overflow == true);
    }

    #[test]
    fun r2_overflowing_add_no() {
        let a = i128::from(100);
        let b = i128::from(200);
        let (sum, overflow) = i128::overflowing_add(a, b);
        assert!(overflow == false);
        assert!(i128::as_u128(sum) == 300);
    }

    #[test]
    fun r2_wrapping_sub() {
        let a = i128::from(10);
        let b = i128::from(3);
        let diff = i128::wrapping_sub(a, b);
        assert!(i128::as_u128(diff) == 7);
    }

    #[test]
    fun r2_abs_negative() {
        let neg = i128::neg_from(99);
        let a = i128::abs(neg);
        assert!(i128::as_u128(a) == 99);
        assert!(i128::sign(a) == 0);
    }

    #[test]
    fun r2_shl_negative() {
        let a = i128::neg_from(1);
        let shifted = i128::shl(a, 3);
        assert!(i128::abs_u128(shifted) == 8);
        assert!(i128::sign(shifted) == 1);
    }
}
