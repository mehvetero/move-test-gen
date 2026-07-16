// scenario 05 round 2 (main v1.1)
#[test_only]
module s05::gatecheck_r2 {
    use s05::gatecheck;

    #[test]
    #[expected_failure(abort_code = gatecheck::EInvalid)]
    fun validate_zero() { gatecheck::validate(0, 5); }

    #[test]
    #[expected_failure(abort_code = gatecheck::EInvalid)]
    fun validate_over() { gatecheck::validate(6, 5); }

    #[test]
    #[expected_failure(abort_code = gatecheck::EEmpty)]
    fun last_index_zero() { gatecheck::last_index(0); }

    #[test]
    fun validate_at_max() { gatecheck::validate(5, 5); }

    #[test]
    fun validate_at_one() { gatecheck::validate(1, 5); }

    #[test]
    fun last_index_normal() { assert!(gatecheck::last_index(10) == 9); }

    #[test]
    fun is_valid_true() { assert!(gatecheck::is_valid(3, 5) == true); }

    #[test]
    fun is_valid_boundary_max() { assert!(gatecheck::is_valid(5, 5) == true); }

    #[test]
    fun is_valid_false_zero() { assert!(gatecheck::is_valid(0, 5) == false); }

    #[test]
    fun is_valid_false_over() { assert!(gatecheck::is_valid(6, 5) == false); }
}
