module s::s {
    const EDup: u64 = 1;
    public fun a(x: u64) { assert!(x > 0, EDup); }
    public fun b(y: u64) { assert!(y > 1, EDup); }
}
