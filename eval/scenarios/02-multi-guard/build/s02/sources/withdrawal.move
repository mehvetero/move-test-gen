module s02::withdrawal {
    const ENotOpen: u64 = 1;
    const ENotOwner: u64 = 2;
    const ELocked: u64 = 3;
    const EZeroAmount: u64 = 4;
    const EInsufficient: u64 = 5;

    public struct Account has drop {
        open: bool,
        owner: address,
        unlock_at: u64,
        balance: u64,
    }

    #[test_only]
    public fun new_for_testing(open: bool, owner: address, unlock_at: u64, balance: u64): Account {
        Account { open, owner, unlock_at, balance }
    }

    public fun withdraw(a: &mut Account, who: address, amount: u64, now: u64) {
        assert!(a.open, ENotOpen);
        assert!(who == a.owner, ENotOwner);
        assert!(now >= a.unlock_at, ELocked);
        assert!(amount > 0, EZeroAmount);
        assert!(amount <= a.balance, EInsufficient);
        a.balance = a.balance - amount;
    }

    public fun close(a: &mut Account) { a.open = false; }
    public fun balance(a: &Account): u64 { a.balance }
}
