/// Module: intent_escrow
module intent_escrow::intent_escrow;

use std::type_name::TypeName;
use sui::table;
use sui::event::emit;
use sui::clock::Clock;
use std::string::String;

use bridge::bridge;
use std::type_name;

public struct IntentData has copy, drop, store {
    intent_id: vector<u8>,
    user: String,
    expiry: u64,
    deposited_token: TypeName,
    deposited_amount: u64,
    exact_in: bool,
    slippage_tolerance: u8,
    out_token: TypeName,
    out_chain_id: String,
    expected_out_amount: u64,
    min_out_amount: u64
}

// Events
public struct IntentCreatedEvent has copy, drop {
    intent_id: vector<u8>,
    user: String,
    deposited_token: TypeName,
    deposited_amount: u64,
    exact_in: bool,
    slippage_tolerance: u8,
    out_token: TypeName,
    out_chain_id: String,
    expected_out_amount: u64,
    min_out_amount: u64
}

public struct IntentFulfilledEvent has copy, drop {
    intent_id: vector<u8>,
    user: String,
    deposited_token: TypeName,
    deposited_amount: u64,
    out_token: TypeName,
    out_chain_id: String,
    out_amount: u64
}

// Error codes
const EINTENT_EXPIRED: u64 = 0;
const EINVALID_OUT_TOKEN: u64 = 1;

public struct IntentEscrow has key, store {
    id: UID,
    intents: table::Table<vector<u8>, IntentData>
}

public struct IntentEscrowAdmin has key {
    id: UID
}

public struct IntentEscrowRelayer has key, store {
    id: UID
}

#[allow(lint(self_transfer))]
fun init(ctx: &mut TxContext) {
    let escrow = IntentEscrow {
        id: object::new(ctx),
        intents: table::new(ctx)
    };

    let admin = IntentEscrowAdmin {
        id: object::new(ctx)
    };

    let relayer = IntentEscrowRelayer {
        id: object::new(ctx)
    };
    // transfer admin and relayer cap to caller
    transfer::transfer(admin, ctx.sender());
    transfer::public_transfer(relayer, ctx.sender());

    transfer::share_object(escrow);
}

// function to create intent object (relayer only)
public fun create_intent(
    _relayer: &IntentEscrowRelayer,
    escrow: &mut IntentEscrow,
    intent_data: IntentData,
) {
    table::add(&mut escrow.intents, intent_data.intent_id, intent_data);
    // emit event
    emit(IntentCreatedEvent {
        intent_id: intent_data.intent_id,
        user: intent_data.user,
        deposited_token: intent_data.deposited_token,
        deposited_amount: intent_data.deposited_amount,
        exact_in: intent_data.exact_in,
        slippage_tolerance: intent_data.slippage_tolerance,
        out_token: intent_data.out_token,
        out_chain_id: intent_data.out_chain_id,
        expected_out_amount: intent_data.expected_out_amount,
        min_out_amount: intent_data.min_out_amount,
    });
}


// function to fullfill user's before expiry intent 
// (by solvers with desired bridgedOutToken)
public fun fulfill_intent<T>(
    escrow: &mut IntentEscrow,
    intent_id: vector<u8>,
    clock: &Clock,
    coin: sui::coin::Coin<T>,
    state: &mut bridge::BridgeState,
) {
    let intent_data = table::borrow_mut(&mut escrow.intents, intent_id);
    let current_time = clock.timestamp_ms();
    assert!(current_time < intent_data.expiry, EINTENT_EXPIRED);

    assert!(intent_data.out_token == type_name::with_defining_ids<T>(), EINVALID_OUT_TOKEN);

    let out_amount = coin.value();
    // assert out amount is greater than min_out_amount
    assert!(out_amount >= intent_data.min_out_amount, EINTENT_EXPIRED);

    // transfer the coin to user via bridge
    bridge::burn(state, coin, intent_data.user);

    // emit event
    emit(IntentFulfilledEvent {
        intent_id: intent_data.intent_id,
        user: intent_data.user,
        deposited_token: intent_data.deposited_token,
        deposited_amount: intent_data.deposited_amount,
        out_token: intent_data.out_token,
        out_chain_id: intent_data.out_chain_id,
        out_amount: out_amount
    });

    // remove intent data from escrow
    table::remove(&mut escrow.intents, intent_id);
}


// function to delete expired intent (anyone can call)
public fun delete_expired_intent(
    escrow: &mut IntentEscrow,
    intent_id: vector<u8>,
    clock: &Clock
) {
    let intent_data = table::borrow(&escrow.intents, intent_id);
    let current_time = clock.timestamp_ms();
    assert!(current_time >= intent_data.expiry, EINTENT_EXPIRED);

    // remove intent data from escrow
    table::remove(&mut escrow.intents, intent_id);
}