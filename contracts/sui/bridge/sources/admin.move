module bridge::admin;

public struct AdminCap has key {
    id: UID
}

// deployer is the first admin
#[allow(lint(self_transfer))]
fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap { 
        id: object::new(ctx) 
    };

    transfer::transfer(admin_cap, ctx.sender());
}

// only existing admin can call
public fun add_new(
    _: &AdminCap,
    new_admin: address,
    ctx: &mut TxContext
) {
    let new = AdminCap { id: object::new(ctx) };
    transfer::transfer(new, new_admin);
}