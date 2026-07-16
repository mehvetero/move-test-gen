module s05::gatecheck {
    const EInvalid: u64 = 1;
    const EEmpty: u64 = 2;

    public fun is_valid(len: u64, max: u64): bool {
        len > 0 && len <= max
    }

    public fun validate(len: u64, max: u64) {
        assert!(is_valid(len, max), EInvalid);
    }

    public fun last_index(len: u64): u64 {
        assert!(len > 0, EEmpty);
        len - 1
    }
}
