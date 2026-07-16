#[test_only]
module vault::vault_tests {
    #[test]
    #[expected_failure(abort_code = vault::vault::E_ZERO_AMOUNT)]
    fun test_zero_amount() { }

    #[test]
    #[expected_failure(abort_code = E_INSUFFICIENT, location = vault::vault)]
    fun test_insufficient() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_NOT_OWNER)]
    fun test_not_owner() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_FEE)]
    fun test_fee_too_high() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_BAD_URL)]
    fun test_bad_url() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_OVER_CAP)]
    fun test_over_cap() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_EMPTY)]
    fun test_empty_vector() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_NOT_ADMIN)]
    fun test_not_admin() { }
    #[test]
    #[expected_failure(abort_code = vault::vault::E_BAD_PREFIX)]
    fun test_bad_prefix() { }

    #[test]
    #[expected_failure(abort_code = vault::vault::E_PAREN_ONE)]
    fun test_paren_one() { }
}
