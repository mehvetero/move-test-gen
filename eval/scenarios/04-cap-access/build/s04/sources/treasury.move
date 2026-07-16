module s04::treasury {
    const EWrongCap: u64 = 1;
    const ERateTooHigh: u64 = 2;
    const EPaused: u64 = 3;

    const MAX_RATE: u64 = 500;

    public struct AdminCap has drop { treasury_id: u64 }

    public struct Treasury has drop {
        id: u64,
        rate: u64,
        paused: bool,
        drained: u64,
    }

    #[test_only]
    public fun new_for_testing(id: u64): (Treasury, AdminCap) {
        (Treasury { id, rate: 0, paused: false, drained: 0 }, AdminCap { treasury_id: id })
    }

    #[test_only]
    public fun forge_cap_for_testing(treasury_id: u64): AdminCap {
        AdminCap { treasury_id }
    }

    public fun set_rate(cap: &AdminCap, t: &mut Treasury, rate: u64) {
        assert!(cap.treasury_id == t.id, EWrongCap);
        assert!(rate <= MAX_RATE, ERateTooHigh);
        t.rate = rate;
    }

    public fun pause(cap: &AdminCap, t: &mut Treasury) {
        assert!(cap.treasury_id == t.id, EWrongCap);
        t.paused = true;
    }

    public fun drain(cap: &AdminCap, t: &mut Treasury, amount: u64) {
        assert!(cap.treasury_id == t.id, EWrongCap);
        assert!(!t.paused, EPaused);
        t.drained = t.drained + amount;
    }

    public fun rate(t: &Treasury): u64 { t.rate }
    public fun drained(t: &Treasury): u64 { t.drained }
}
