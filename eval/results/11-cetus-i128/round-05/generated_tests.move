// scenario 11, round 5 (varied v1.1)
// Abort paths: from(L25), neg_from(L32), add(L69), sub(L88), neg(L118) — all EOverflow
// Numeric comparisons: lt/gt/lte/gte/eq + mul sign logic + div sign logic

#[test_only]
module integer_mate::i128_varied {
    use integer_mate::i128;

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun path_from() { i128::from(170141183460469231731687303715884105728); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun path_neg_from() { i128::neg_from(170141183460469231731687303715884105729); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun path_add() { i128::add(i128::from(170141183460469231731687303715884105727), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun path_sub() { i128::sub(i128::neg_from(170141183460469231731687303715884105728), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun path_neg() { i128::neg(i128::neg_from(170141183460469231731687303715884105728)); }

    #[test]
    fun varied_mul_exhaustive() {
        let p3 = i128::from(3);
        let n3 = i128::neg_from(3);
        let p4 = i128::from(4);
        let n4 = i128::neg_from(4);
        // all sign combos
        assert!(i128::as_u128(i128::mul(p3, p4)) == 12);
        assert!(i128::abs_u128(i128::mul(p3, n4)) == 12);
        assert!(i128::abs_u128(i128::mul(n3, p4)) == 12);
        assert!(i128::as_u128(i128::mul(n3, n4)) == 12);
        assert!(i128::sign(i128::mul(p3, n4)) == 1);
        assert!(i128::sign(i128::mul(n3, n4)) == 0);
    }

    #[test]
    fun varied_div_exhaustive() {
        let p12 = i128::from(12);
        let n12 = i128::neg_from(12);
        let p3 = i128::from(3);
        let n3 = i128::neg_from(3);
        assert!(i128::as_u128(i128::div(p12, p3)) == 4);
        assert!(i128::sign(i128::div(p12, n3)) == 1);
        assert!(i128::sign(i128::div(n12, p3)) == 1);
        assert!(i128::sign(i128::div(n12, n3)) == 0);
    }

    #[test]
    fun varied_cmp_boundary() {
        let z = i128::zero();
        let one = i128::from(1);
        let neg_one = i128::neg_from(1);
        assert!(i128::lt(neg_one, z) == true);
        assert!(i128::lt(z, one) == true);
        assert!(i128::gt(one, neg_one) == true);
        assert!(i128::eq(z, i128::zero()) == true);
        assert!(i128::lte(neg_one, neg_one) == true);
        assert!(i128::gte(one, one) == true);
    }

    #[test]
    fun varied_add_cross_zero() {
        // negative + larger positive = positive
        let sum = i128::add(i128::neg_from(10), i128::from(15));
        assert!(i128::as_u128(sum) == 5);
        assert!(i128::sign(sum) == 0);
    }

    #[test]
    fun varied_sub_cross_zero() {
        // small positive - larger positive = negative
        let diff = i128::sub(i128::from(3), i128::from(10));
        assert!(i128::abs_u128(diff) == 7);
        assert!(i128::sign(diff) == 1);
    }

    #[test]
    fun varied_shl_shr_neg() {
        let n = i128::neg_from(4);
        let shifted = i128::shl(n, 2);
        assert!(i128::abs_u128(shifted) == 16);
        assert!(i128::sign(shifted) == 1);
    }
}
