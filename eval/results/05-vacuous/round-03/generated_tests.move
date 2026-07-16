// scenario 05 round 3 (varied v1.1)
#[test_only]
module s05::gatecheck_varied {
    use s05::gatecheck;

    #[test]
    #[expected_failure(abort_code = gatecheck::EInvalid)]
    fun path_validate_zero() { gatecheck::validate(0, 100); }

    #[test]
    #[expected_failure(abort_code = gatecheck::EInvalid)]
    fun path_validate_over() { gatecheck::validate(101, 100); }

    #[test]
    #[expected_failure(abort_code = gatecheck::EEmpty)]
    fun path_last_index_zero() { gatecheck::last_index(0); }

    #[test]
    fun bound_validate_max() { gatecheck::validate(100, 100); }

    #[test]
    fun bound_validate_one() { gatecheck::validate(1, 100); }

    #[test]
    fun bound_last_index_one() { assert!(gatecheck::last_index(1) == 0); }

    #[test]
    fun truth_valid_mid() { assert!(gatecheck::is_valid(50, 100) == true); }

    #[test]
    fun truth_valid_max() { assert!(gatecheck::is_valid(100, 100) == true); }

    #[test]
    fun truth_valid_one() { assert!(gatecheck::is_valid(1, 100) == true); }

    #[test]
    fun truth_invalid_zero() { assert!(gatecheck::is_valid(0, 100) == false); }

    #[test]
    fun truth_invalid_over() { assert!(gatecheck::is_valid(101, 100) == false); }
}
