// scenario 11, round 3 (main v1.1)
#[test_only]
module integer_mate::i128_r3 {
    use integer_mate::i128;

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_from() { i128::from(170141183460469231731687303715884105728); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_neg_from() { i128::neg_from(170141183460469231731687303715884105729); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_add() { i128::add(i128::from(170141183460469231731687303715884105727), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_sub() { i128::sub(i128::neg_from(170141183460469231731687303715884105728), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r3_neg_min() { i128::neg(i128::neg_from(170141183460469231731687303715884105728)); }

    #[test]
    fun r3_mul_signs() {
        // pos * pos
        assert!(i128::as_u128(i128::mul(i128::from(3), i128::from(4))) == 12);
        // neg * neg = pos
        assert!(i128::sign(i128::mul(i128::neg_from(3), i128::neg_from(4))) == 0);
        // pos * neg = neg
        assert!(i128::sign(i128::mul(i128::from(3), i128::neg_from(4))) == 1);
        // neg * pos = neg
        assert!(i128::sign(i128::mul(i128::neg_from(3), i128::from(4))) == 1);
    }

    #[test]
    fun r3_div_signs() {
        // pos / neg = neg
        let q = i128::div(i128::from(12), i128::neg_from(3));
        assert!(i128::abs_u128(q) == 4);
        assert!(i128::sign(q) == 1);
        // neg / neg = pos
        let q2 = i128::div(i128::neg_from(12), i128::neg_from(3));
        assert!(i128::as_u128(q2) == 4);
        assert!(i128::sign(q2) == 0);
    }

    #[test]
    fun r3_add_neg_pos() {
        // -5 + 10 = 5
        let sum = i128::add(i128::neg_from(5), i128::from(10));
        assert!(i128::as_u128(sum) == 5);
        assert!(i128::sign(sum) == 0);
    }

    #[test]
    fun r3_sub_neg() {
        // 5 - 10 = -5
        let diff = i128::sub(i128::from(5), i128::from(10));
        assert!(i128::abs_u128(diff) == 5);
        assert!(i128::sign(diff) == 1);
    }

    #[test]
    fun r3_overflowing_sub() {
        let min = i128::neg_from(170141183460469231731687303715884105728);
        let one = i128::from(1);
        let (_, overflow) = i128::overflowing_sub(min, one);
        assert!(overflow == true);
    }

    #[test]
    fun r3_as_i64() {
        let v = i128::from(42);
        let _ = i128::as_i64(v);
    }

    #[test]
    fun r3_as_i32() {
        let v = i128::from(100);
        let _ = i128::as_i32(v);
    }

    #[test]
    fun r3_cmp() {
        let a = i128::from(5);
        let b = i128::from(10);
        assert!(i128::lt(a, b) == true);
        assert!(i128::gt(b, a) == true);
        assert!(i128::lte(a, a) == true);
        assert!(i128::gte(a, a) == true);
    }

    #[test]
    fun r3_neg_cmp() {
        let neg = i128::neg_from(5);
        let pos = i128::from(5);
        assert!(i128::lt(neg, pos) == true);
        assert!(i128::gt(pos, neg) == true);
    }
}
