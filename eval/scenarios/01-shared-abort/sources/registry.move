module s01::registry {
    const ENotPositive: u64 = 1;
    const ECapExceeded: u64 = 2;
    const EInsufficientTotal: u64 = 3;

    public struct Registry has drop {
        total: u64,
        cap: u64,
        entries: u64,
    }

    #[test_only]
    public fun new_for_testing(cap: u64): Registry {
        Registry { total: 0, cap, entries: 0 }
    }

    public fun add(r: &mut Registry, amount: u64) {
        assert!(amount > 0, ENotPositive);
        assert!(r.total + amount <= r.cap, ECapExceeded);
        r.total = r.total + amount;
        r.entries = r.entries + 1;
    }

    public fun scale(r: &mut Registry, factor: u64) {
        assert!(factor > 0, ENotPositive);
        r.total = r.total * factor;
    }

    public fun reserve(r: &mut Registry, amount: u64) {
        assert!(amount > 0, ENotPositive);
        assert!(r.total >= amount, EInsufficientTotal);
        r.total = r.total - amount;
    }

    public fun total(r: &Registry): u64 { r.total }
    public fun entries(r: &Registry): u64 { r.entries }
}
