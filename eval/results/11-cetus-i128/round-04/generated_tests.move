// scenario 11, round 4 (main v1.1)
#[test_only]
module integer_mate::i128_r4 {
    use integer_mate::i128;

    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r4_from() { i128::from(170141183460469231731687303715884105728); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r4_neg_from() { i128::neg_from(170141183460469231731687303715884105729); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r4_add() { i128::add(i128::from(170141183460469231731687303715884105727), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r4_sub() { i128::sub(i128::neg_from(170141183460469231731687303715884105728), i128::from(1)); }
    #[test]
    #[expected_failure(abort_code = i128::EOverflow)]
    fun r4_neg_min() { i128::neg(i128::neg_from(170141183460469231731687303715884105728)); }

    #[test]
    fun r4_mul_all_signs() {
        let p = i128::from(5);
        let n = i128::neg_from(5);
        let z = i128::zero();
        // p*p=pos, n*n=pos, p*n=neg, n*p=neg, anything*0=0
        assert!(i128::sign(i128::mul(p, p)) == 0);
        assert!(i128::sign(i128::mul(n, n)) == 0);
        assert!(i128::sign(i128::mul(p, n)) == 1);
        assert!(i128::sign(i128::mul(n, p)) == 1);
        assert!(i128::as_u128(i128::mul(p, z)) == 0);
        assert!(i128::as_u128(i128::mul(z, n)) == 0);
    }

    #[test]
    fun r4_div_all_signs() {
        let p = i128::from(20);
        let n = i128::neg_from(20);
        let d = i128::from(4);
        let nd = i128::neg_from(4);
        assert!(i128::as_u128(i128::div(p, d)) == 5);
        assert!(i128::sign(i128::div(p, nd)) == 1);
        assert!(i128::sign(i128::div(n, d)) == 1);
        assert!(i128::sign(i128::div(n, nd)) == 0);
    }

    #[test]
    fun r4_cmp_mixed() {
        let neg_big = i128::neg_from(100);
        let neg_small = i128::neg_from(1);
        let pos = i128::from(1);
        assert!(i128::lt(neg_big, neg_small) == true);
        assert!(i128::lt(neg_small, pos) == true);
        assert!(i128::gt(pos, neg_big) == true);
    }

    #[test]
    fun r4_abs() {
        assert!(i128::abs_u128(i128::from(77)) == 77);
        assert!(i128::abs_u128(i128::neg_from(77)) == 77);
        assert!(i128::abs_u128(i128::zero()) == 0);
    }
}
