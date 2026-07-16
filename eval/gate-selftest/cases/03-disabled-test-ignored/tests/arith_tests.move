#[test_only]
module vault::arith_tests {
    #[test]
    #[expected_failure(arithmetic_error, location = vault::vault)]
    fun test_overflow() { }
}
