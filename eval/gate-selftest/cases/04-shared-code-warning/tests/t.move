#[test_only]
module s::t {
    #[test]
    #[expected_failure(abort_code = s::s::EDup)]
    fun t_a_zero() { }
}
