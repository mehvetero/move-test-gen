// scenario 04 round 2 (main v1.1)
#[test_only]
module s04::treasury_r2 {
    use s04::treasury;

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun wrong_cap_set_rate() {
        let (mut t, _) = treasury::new_for_testing(5);
        let fake = treasury::forge_cap_for_testing(6);
        treasury::set_rate(&fake, &mut t, 10);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun wrong_cap_pause() {
        let (mut t, _) = treasury::new_for_testing(5);
        let fake = treasury::forge_cap_for_testing(6);
        treasury::pause(&fake, &mut t);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EWrongCap)]
    fun wrong_cap_drain() {
        let (mut t, _) = treasury::new_for_testing(5);
        let fake = treasury::forge_cap_for_testing(6);
        treasury::drain(&fake, &mut t, 1);
    }

    #[test]
    #[expected_failure(abort_code = treasury::ERateTooHigh)]
    fun rate_501() {
        let (mut t, cap) = treasury::new_for_testing(5);
        treasury::set_rate(&cap, &mut t, 501);
    }

    #[test]
    #[expected_failure(abort_code = treasury::EPaused)]
    fun drain_paused() {
        let (mut t, cap) = treasury::new_for_testing(5);
        treasury::pause(&cap, &mut t);
        treasury::drain(&cap, &mut t, 1);
    }

    #[test]
    fun rate_500() {
        let (mut t, cap) = treasury::new_for_testing(5);
        treasury::set_rate(&cap, &mut t, 500);
        assert!(treasury::rate(&t) == 500);
    }

    #[test]
    fun drain_zero() {
        let (mut t, cap) = treasury::new_for_testing(5);
        treasury::drain(&cap, &mut t, 0);
        assert!(treasury::drained(&t) == 0);
    }
}
