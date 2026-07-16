module s03::feemath {
    const EFeeTooHigh: u64 = 1;
    const EAmountTooLarge: u64 = 2;
    const EZeroParts: u64 = 3;

    const MAX_BPS: u64 = 10_000;
    const MAX_AMOUNT: u64 = 1_000_000_000_000_000;

    public fun fee_for(amount: u64, bps: u64): u64 {
        assert!(bps <= MAX_BPS, EFeeTooHigh);
        assert!(amount <= MAX_AMOUNT, EAmountTooLarge);
        (((amount as u128) * (bps as u128) / 10_000) as u64)
    }

    public fun net_after_fee(amount: u64, bps: u64): u64 {
        let f = fee_for(amount, bps);
        amount - f
    }

    public fun split_fee(amount: u64, bps: u64, parts: u64): u64 {
        assert!(parts > 0, EZeroParts);
        fee_for(amount, bps) / parts
    }
}
