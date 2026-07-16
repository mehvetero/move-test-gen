// scenario 06 round 3 (varied v1.1)
// Abort paths:
//   withdraw L14: who == l.owner   → ENotOwner
//   withdraw L15: amount > 0       → EZeroAmount
//   take     L20: amount > 0       → EZeroAmount (private, same check)
//   take     L21: amount <= balance → EOverBalance

#[test_only]
module s06::locker_varied {
    use s06::locker;

    #[test]
    #[expected_failure(abort_code = locker::ENotOwner)]
    fun path_wrong_owner() {
        let mut l = locker::new_for_testing(@0xAA, 100);
        locker::withdraw(&mut l, @0xBB, 1);
    }

    #[test]
    #[expected_failure(abort_code = locker::EZeroAmount)]
    fun path_zero() {
        let mut l = locker::new_for_testing(@0xAA, 100);
        locker::withdraw(&mut l, @0xAA, 0);
    }

    #[test]
    #[expected_failure(abort_code = locker::EOverBalance)]
    fun path_over() {
        let mut l = locker::new_for_testing(@0xAA, 10);
        locker::withdraw(&mut l, @0xAA, 11);
    }

    #[test]
    fun bound_exact() {
        let mut l = locker::new_for_testing(@0xAA, 999);
        locker::withdraw(&mut l, @0xAA, 999);
        assert!(locker::balance(&l) == 0);
    }

    #[test]
    fun bound_one() {
        let mut l = locker::new_for_testing(@0xAA, 1);
        locker::withdraw(&mut l, @0xAA, 1);
        assert!(locker::balance(&l) == 0);
    }

    #[test]
    fun state_two_withdrawals() {
        let mut l = locker::new_for_testing(@0xAA, 100);
        locker::withdraw(&mut l, @0xAA, 40);
        locker::withdraw(&mut l, @0xAA, 60);
        assert!(locker::balance(&l) == 0);
    }
}
