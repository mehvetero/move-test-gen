#[test_only]
module edge::edge_tests {
    #[test]
    #[expected_failure(abort_code = edge::edge::E1)]
    fun t1() { }
    #[test]
    #[expected_failure(abort_code = edge::edge::E2)]
    fun t2() { }
}
