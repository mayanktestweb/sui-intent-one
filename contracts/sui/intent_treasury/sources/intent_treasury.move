/// Module: intent_treasury
module intent_treasury::intent_treasury;

use std::string::String;
use sui::coin::Coin;
use std::type_name::TypeName;

use sui::event::emit;
use std::type_name;
use sui::clock::Clock;
use sui::dynamic_object_field as dof;

public struct IntentTreasuryAdmin has key, store {
    id: UID
}

public struct Relayer has key, store {
    id: UID
}

// this will be created as shared object in init function
// it will hold all the intents created by users in dof
// with intent_id as key and IntentData as value
public struct IntentTreasuryState has key, store {
    id: UID
}


public struct IntentCreatedEvent has copy, drop {
    id: vector<u8>,
    user: address,
    deposited_token: TypeName,
    deposited_amount: u64,
    exact_in: bool,
    slippage_tolerance: u8,
    out_token: String,
    out_chain_id: String,
    expected_out_amount: u256,
    min_out_amount: u256
}

public struct IntentExecutedEvent has copy, drop {
    id: vector<u8>,
    user: address,
    deposited_token: TypeName,
    deposited_amount: u64,
    out_token: String,
    out_chain_id: String,
    out_amount: u256,
}

// This struct holds the intent data for each intent created by users
// It will hold user's provided coin in its dof
public struct IntentData has key, store {
    id: UID,
    expiry: u64,
    exact_in: bool,
    slippage_tolerance: u8,
    out_token: String,
    out_chain_id: String,
    expected_out_amount: u256,
    min_out_amount: u256,
    user: address
}

// Errors
const EINSUFFICIENT_DEPOSIT: u64 = 100; // Error code for insufficient deposit
const EINTENT_EXPIRED: u64 = 101; // Error code for expired intent
const EUNAUTHORIZED_CANCELLATION: u64 = 102; // Error code for unauthorized cancellation
const EINTENT_NOT_EXPIRED: u64 = 103; // Error code for intent not expired

fun init(ctx: &mut TxContext) {
    // Create an admin object and store it in the global state
    let admin = IntentTreasuryAdmin { id: object::new(ctx) };

    // Create a relayer object and store it in the global state
    let relayer = Relayer { id: object::new(ctx) };

    // Create the treasury state object and store it in the global state
    let treasury_state = IntentTreasuryState { id: object::new(ctx) };  
    
    transfer::transfer(admin, ctx.sender());
    transfer::public_transfer(relayer, ctx.sender());
    transfer::share_object(treasury_state);
}


// function to create intent and emit event (relayer only)
public fun create_intent<T>(
    treasury_state: &mut IntentTreasuryState,
    intent_id: vector<u8>,
    exact_in: bool,
    slippage_tolerance: u8,
    out_token: String,
    out_chain_id: String,
    expected_out_amount: u256,
    min_out_amount: u256,
    user: address,
    coin: Coin<T>,
    clock: &Clock,
    _: &Relayer,
    ctx: &mut TxContext
) {
    // assert coin amount is greater than 0    
    let deposited_amount = coin.value();
    assert!(deposited_amount > 0, EINSUFFICIENT_DEPOSIT);

    // expiry time is two hours from now
    let current_time: u64 = clock.timestamp_ms();
    let expiry_time = current_time + 7200000u64; //

    // Create intent data
    let mut intent_data = IntentData {
        id: object::new(ctx),
        expiry: expiry_time,
        exact_in,
        slippage_tolerance,
        out_token,
        out_chain_id,
        expected_out_amount,
        min_out_amount,
        user
    };   

    let deposit_amount = coin.value();
    // Store the coin in intent data's dof
    dof::add(&mut intent_data.id, b"coin", coin);

    // Store the intent data in treasury state's dof with intent_id as key
    dof::add(&mut treasury_state.id, intent_id, intent_data);

    // Emit IntentCreatedEvent
    emit(IntentCreatedEvent {
        id: intent_id,
        user: user,
        deposited_token: type_name::with_defining_ids<T>(),
        deposited_amount: deposit_amount,
        exact_in: exact_in,
        slippage_tolerance: slippage_tolerance,
        out_token: out_token,
        out_chain_id: out_chain_id,
        expected_out_amount: expected_out_amount,
        min_out_amount: min_out_amount
    });
}


// function to execute intent and emit event (relayer only)
public fun execute_intent<T>(
    treasury_state: &mut IntentTreasuryState,
    intent_id: vector<u8>,
    resolver: address,
    outAmount: u256,
    _: &Relayer,
    clock: &Clock, // always 0x6
) {
    let intent_data = dof::borrow_mut<vector<u8>, IntentData>(&mut treasury_state.id, intent_id);

    // assert intent is not expired
    let current_time: u64 = clock.timestamp_ms();
    assert!(current_time <= intent_data.expiry, EINTENT_EXPIRED); // Error code 1

    let coin = dof::remove<vector<u8>, Coin<T>>(&mut intent_data.id, b"coin");
    let deposited_amount = coin.value();
    transfer::public_transfer(coin, resolver);

    // delete the intent data from treasury state's dof
    let intent_data = dof::remove<vector<u8>, IntentData>(&mut treasury_state.id, intent_id);
    let IntentData {
        id,
        expiry: _,
        exact_in: _,
        slippage_tolerance: _,
        out_token,
        out_chain_id,
        expected_out_amount: _,
        min_out_amount: _,
        user
    } = intent_data;
    id.delete();

    emit(IntentExecutedEvent {
        id: intent_id,
        user: user,
        deposited_token: type_name::with_defining_ids<T>(),
        deposited_amount: deposited_amount,
        out_token: out_token,
        out_chain_id: out_chain_id,
        out_amount: outAmount,
    });
}


// function to withdraw funds after intent is expired (user only)
public fun withdraw<T>(
    treasury_state: &mut IntentTreasuryState,
    intent_id: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let intent_data = dof::borrow_mut<vector<u8>, IntentData>(&mut treasury_state.id, intent_id);
    let user = intent_data.user;
    assert!(user == ctx.sender(), EUNAUTHORIZED_CANCELLATION); // Error code 102 for unauthorized cancellation

    // assert intent is expired
    let current_time: u64 = clock.timestamp_ms();
    assert!(current_time > intent_data.expiry, EINTENT_NOT_EXPIRED); // Error code 103 for intent not expired

    let coin = dof::remove<vector<u8>, Coin<T>>(&mut intent_data.id, b"coin");
    transfer::public_transfer(coin, user);

    // delete the intent data from treasury state's dof
    let intent_data = dof::remove<vector<u8>, IntentData>(&mut treasury_state.id, intent_id);
    let IntentData {
        id,
        expiry: _,
        exact_in: _,
        slippage_tolerance: _,
        out_token: _,
        out_chain_id: _,
        expected_out_amount: _,
        min_out_amount: _,
        user: _
    } = intent_data;
    id.delete();
}