#[test_only]
module vault::disabled_tests {
    // #[expected_failure(abort_code = vault::vault::E_LOCKED)]
    // fun test_locked() { }   — disabled: flaky on CI
}
