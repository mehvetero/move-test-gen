module edge::edge {
    const E1: u64 = 1;
    const E2: u64 = 2;
    public fun f(a: bool, b: bool) {
        assert!(a, E1); assert!(b, E2);
    }
}
