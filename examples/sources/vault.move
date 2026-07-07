module example::vault {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};

    const EInsufficientBalance: u64 = 0;
    const EInsufficientShares: u64 = 1;
    const EZeroAmount: u64 = 2;
    const EFlashRepayInsufficient: u64 = 4;
    const EFeeTooHigh: u64 = 5;
    const MAX_FEE_BPS: u64 = 500; // 5%
    const DEFAULT_FEE_BPS: u64 = 30; // 0.3%

    public struct Vault has key {
        id: UID,
        balance: Balance<SUI>,
        total_shares: u64,
        fee_bps: u64,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    // Hot potato — no drop, no store, no copy, no key
    public struct FlashReceipt {
        amount: u64,
    }

    fun init(ctx: &mut TxContext) {
        let vault = Vault {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            total_shares: 0,
            fee_bps: DEFAULT_FEE_BPS,
        };
        let cap = AdminCap { id: object::new(ctx) };
        transfer::share_object(vault);
        transfer::transfer(cap, ctx.sender());
    }

    public fun deposit(vault: &mut Vault, coin: Coin<SUI>): u64 {
        let amount = coin.value();
        assert!(amount > 0, EZeroAmount);

        let shares = if (vault.total_shares == 0) {
            amount
        } else {
            (((amount as u128) * (vault.total_shares as u128) / (vault.balance.value() as u128)) as u64)
        };

        vault.balance.join(coin.into_balance());
        vault.total_shares = vault.total_shares + shares;

        shares
    }

    public fun withdraw(vault: &mut Vault, shares: u64, ctx: &mut TxContext): Coin<SUI> {
        assert!(shares > 0, EZeroAmount);
        assert!(shares <= vault.total_shares, EInsufficientShares);

        let total_balance = vault.balance.value();
        let amount = (((shares as u128) * (total_balance as u128) / (vault.total_shares as u128)) as u64);

        let fee = (((amount as u128) * (vault.fee_bps as u128) / 10000) as u64);
        let net_amount = amount - fee;

        vault.total_shares = vault.total_shares - shares;

        coin::from_balance(vault.balance.split(net_amount), ctx)
    }

    public fun flash_borrow(vault: &mut Vault, amount: u64, ctx: &mut TxContext): (Coin<SUI>, FlashReceipt) {
        assert!(amount > 0, EZeroAmount);
        assert!(amount <= vault.balance.value(), EInsufficientBalance);

        let coin = coin::from_balance(vault.balance.split(amount), ctx);
        let receipt = FlashReceipt { amount };
        (coin, receipt)
    }

    public fun flash_repay(vault: &mut Vault, coin: Coin<SUI>, receipt: FlashReceipt) {
        let FlashReceipt { amount } = receipt;
        let fee = (((amount as u128) * (vault.fee_bps as u128) / 10000) as u64);
        assert!(coin.value() >= amount + fee, EFlashRepayInsufficient);
        vault.balance.join(coin.into_balance());
    }

    public fun set_fee(_cap: &AdminCap, vault: &mut Vault, new_fee_bps: u64) {
        assert!(new_fee_bps <= MAX_FEE_BPS, EFeeTooHigh);
        vault.fee_bps = new_fee_bps;
    }

    public fun balance(vault: &Vault): u64 {
        vault.balance.value()
    }

    public fun total_shares(vault: &Vault): u64 {
        vault.total_shares
    }

    // ---- test-only helpers ----

    #[test_only]
    public fun create_for_testing(ctx: &mut TxContext): Vault {
        Vault {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            total_shares: 0,
            fee_bps: DEFAULT_FEE_BPS,
        }
    }

    #[test_only]
    public fun destroy_for_testing(vault: Vault) {
        let Vault { id, balance, total_shares: _, fee_bps: _ } = vault;
        id.delete();
        balance.destroy_for_testing();
    }

    #[test_only]
    public fun create_admin_cap_for_testing(ctx: &mut TxContext): AdminCap {
        AdminCap { id: object::new(ctx) }
    }

    #[test_only]
    public fun destroy_admin_cap_for_testing(cap: AdminCap) {
        let AdminCap { id } = cap;
        id.delete();
    }
}
