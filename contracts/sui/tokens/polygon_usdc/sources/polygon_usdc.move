/// Module: polygon_usdc
module polygon_usdc::polygon_usdc;

use sui::coin;
use sui::url;

public struct POLYGON_USDC has drop {}

#[allow(deprecated_usage)]
fun init(witness: POLYGON_USDC, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency(
        witness, 
        6, 
        b"bPolyUSDC", 
        b"bridge Polygon USDC", 
        b"its a USDC bridge token of Polygon chain", 
        option::some(url::new_unsafe_from_bytes(b"")), 
        ctx
    );

    transfer::public_transfer(treasury_cap, ctx.sender());
    transfer::public_transfer(metadata, ctx.sender());
}