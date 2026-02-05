module bridge::vault {

    use sui::dynamic_object_field as dof;
    use sui::coin::TreasuryCap;

    use bridge::admin::AdminCap;

    /// Holds mint authority for exactly one token type
    public struct TokenVault has key, store {
        id: UID
    }

    /// Create a new vault (only admin)
    /// newly built vault will be owned by admin
    #[allow(lint(self_transfer))]
    public fun new(
       _: &AdminCap, 
        ctx: &mut TxContext
    ) {
        let vault = TokenVault {
            id: object::new(ctx)
        };

        transfer::public_transfer(vault, ctx.sender());
    }

    /// Deposit TreasuryCap<T> into the vault
    public fun deposit_cap<T>(
        vault: &mut TokenVault,
        cap: TreasuryCap<T>
    ) {
        // Each vault holds exactly one cap under a fixed key
        dof::add(&mut vault.id, b"cap", cap);
    }

    /// Borrow mutable access to the TreasuryCap<T>
    public fun borrow_cap_mut<T>(
        vault: &mut TokenVault
    ): &mut TreasuryCap<T> {
        dof::borrow_mut(&mut vault.id, b"cap")
    }

    /// Optional: remove cap (migration / shutdown)
    /// admin only
    public fun withdraw_cap<T>(
       _: &AdminCap,
        vault: &mut TokenVault
    ): TreasuryCap<T> {
        dof::remove(&mut vault.id, b"cap")
    }

    /// function to destroy vault
    /// admin only
    public fun destory(
       _: &AdminCap, 
        vault: TokenVault
    ) {
        let TokenVault {id} = vault;
        id.delete();
    }
}
