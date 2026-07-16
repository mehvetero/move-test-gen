// scenario 06 round 2 (main v1.1)
#[test_only]
module s06::locker_r2 {
    use s06::locker;

    #[test]
    #[expected_failure(abort_code = locker::ENotOwner)]
    fun wrong_owner() {
        let mut l = locker::new_for_testing(@0x1, 500);
        locker::withdraw(&mut l, @0x2, 10);
    }

    #[test]
    #[expected_failure(abort_code = locker::EZeroAmount)]
    fun zero_amount() {
        let mut l = locker::new_for_testing(@0x1, 500);
        locker::withdraw(&mut l, @0x1, 0);
    }

    #[test]
    #[expected_failure(abort_code = locker::EOverBalance)]
    fun over_balance() {
        let mut l = locker::new_for_testing(@0x1, 50);
        locker::withdraw(&mut l, @0x1, 51);
    }

    #[test]
    fun exact_drain() {
        let mut l = locker::new_for_testing(@0x1, 777);
        locker::withdraw(&mut l, @0x1, 777);
        assert!(locker::balance(&l) == 0);
    }

    #[test]
    fun partial_withdraw() {
        let mut l = locker::new_for_testing(@0x1, 1000);
        locker::withdraw(&mut l, @0x1, 1);
        assert!(locker::balance(&l) == 999);
    }
}
