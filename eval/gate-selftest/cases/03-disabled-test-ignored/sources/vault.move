module vault::vault {
    const E_NOT_OWNER: u64 = 1;
    const E_ZERO_AMOUNT: u64 = 2;
    const E_INSUFFICIENT: u64 = 3;
    const E_LOCKED: u64 = 4;
    const E_FEE: u64 = 5;
    const E_BAD_URL: u64 = 6;
    const E_OVER_CAP: u64 = 7;
    const E_EMPTY: u64 = 8;
    const E_NOT_ADMIN: u64 = 9;
    const E_BAD_PREFIX: u64 = 10;
    const E_PAREN_ONE: u64 = 11;

    public fun withdraw(cap: &OwnerCap, sender: address, amount: u64, balance: u64, fee: u64, max_fee: u64) {
        assert!(is_owner(cap, sender), E_NOT_OWNER);
        assert!(amount > 0, E_ZERO_AMOUNT);
        assert!(balance >= amount, E_INSUFFICIENT);
        assert!(fee <= max_fee, E_FEE); // cap check
    }

    public fun set_url(url: vector<u8>) {
        assert!(url == b"https://x.io", E_BAD_URL);
    }

    public fun deposit(total: u64, cap: u64, v: vector<u64>, admin: &AdminCap, addr: address) {
        assert!(
            total <= cap,
            E_OVER_CAP
        );
        assert!(vector::length(&v) > 0,
            E_EMPTY);
        assert!(is_admin(admin, addr),
            E_NOT_ADMIN);
    }

    public fun check_prefix(url: vector<u8>) {
        assert!(starts_with(url, b"v2)"),
            E_BAD_PREFIX);
        assert!(matches(url, b"x)y"), E_PAREN_ONE);
    }

    public fun guard(locked: bool) {
        emit_event(); // abort E_PHANTOM happens upstream, not here
        if (locked) {
            abort E_LOCKED
        }
    }
}
