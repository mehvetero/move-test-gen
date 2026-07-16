// scenario 04 round 3 (varied v1.1)
#[test_only]
module s04::treasury_varied {
    use s04::treasury;

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun path_set_rate_wrong() {
        let (mut t, _) = treasury::new_for_testing(10);
        treasury::set_rate(&treasury::forge_cap_for_testing(11), &mut t, 1);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun path_pause_wrong() {
        let (mut t, _) = treasury::new_for_testing(10);
        treasury::pause(&treasury::forge_cap_for_testing(11), &mut t);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun path_drain_wrong() {
        let (mut t, _) = treasury::new_for_testing(10);
        treasury::drain(&treasury::forge_cap_for_testing(11), &mut t, 1);
    }

    #[test]
    #[expected_failure(abort_code = treasury::ERateTooHigh)]
    fun path_rate_high() {
        let (mut t, cap) = treasury::new_for_testing(10);
        treasury::set_rate(&cap, &mut t, 501);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EPaused)]
    fun path_drain_paused() {
        let (mut t, cap) = treasury::new_for_testing(10);
        treasury::pause(&cap, &mut t);
        treasury::drain(&cap, &mut t, 1);
    }

    #[test]
    fun bound_rate_at_500() {
        let (mut t, cap) = treasury::new_for_testing(10);
        treasury::set_rate(&cap, &mut t, 500);
        assert!(treasury::rate(&t) == 500);
    }

    #[test]
    fun bound_rate_zero() {
        let (mut t, cap) = treasury::new_for_testing(10);
        treasury::set_rate(&cap, &mut t, 0);
        assert!(treasury::rate(&t) == 0);
    }
}
