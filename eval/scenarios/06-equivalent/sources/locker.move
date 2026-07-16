module s06::locker {
    const EZeroAmount: u64 = 1;
    const EOverBalance: u64 = 2;
    const ENotOwner: u64 = 3;

    public struct Locker has drop { owner: address, balance: u64 }

    #[test_only]
    public fun new_for_testing(owner: address, balance: u64): Locker {
        Locker { owner, balance }
    }

    public fun withdraw(l: &mut Locker, who: address, amount: u64) {
        assert!(who == l.owner, ENotOwner);
        assert!(amount > 0, EZeroAmount);      // site A — outer guard
        take(l, amount);
    }

    fun take(l: &mut Locker, amount: u64) {
        assert!(amount > 0, EZeroAmount);      // site B — inner guard, redundant, private
        assert!(amount <= l.balance, EOverBalance);
        l.balance = l.balance - amount;
    }

    public fun balance(l: &Locker): u64 { l.balance }
}
