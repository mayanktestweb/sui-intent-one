/// Module: birdge_core
module bridge::bridge;

use sui::dynamic_object_field as dof;
use std::type_name;

use bridge::vault::TokenVault;
use std::type_name::TypeName;
use sui::coin;
use sui::coin::Coin;
use sui::table;
use std::string::String;
use sui::event;
use sui::bcs;
use sui::ed25519;

use bridge::admin::AdminCap;
use sui::event::emit;

// Errors
const ENONCE_USED: u64 = 0;
const EINVALID_SIGNATURE: u64 = 1;

public struct TokenData has copy, drop, store {
    chain_id: String,
    token_address: String
}

public struct BridgeState has key, store {
    id: UID,
    token_data: table::Table<TypeName, TokenData>,
    relayer_public_key: vector<u8>,
    used_nonces: table::Table<vector<u8>, bool>,
    burn_nonce: u256
}

public struct DepsitData has copy, drop {
    token_address: String,
    amount: u256,
    chain_id: String,
    receiver: address,
    deposit_nonce: vector<u8>
}


// burn event
public struct BurnEvent has copy, drop {
    token_address: String,
    amount: u256,
    chain_id: String,
    receiver: String,
    burn_nonce: u256
}

// mint event
public struct MintEvent has copy, drop {
    token_type: TypeName,
    amount: u64,
    receiver: address,
    deposit_nonce: vector<u8>
}

fun init(ctx: &mut TxContext) {

    let state = BridgeState {
        id: object::new(ctx),
        token_data: table::new(ctx),
        relayer_public_key: vector[], // should be set immediatly after init
        used_nonces: table::new(ctx),
        burn_nonce: 0
    };

    transfer::share_object(state);
}


// set relayer public key right after init (only admin)
public fun set_relayer_public_key(
    _: &AdminCap,
    state: &mut BridgeState,
    relayer_pubkey: vector<u8>
) {
    state.relayer_public_key = relayer_pubkey;
}


/// TODO: make it admin only
public fun register_token<T>(
    _: &mut AdminCap,
    state: &mut BridgeState,
    vault: TokenVault,
    chain_id: String,
    token_address: String
) {
    let key = type_name::with_defining_ids<T>();
    dof::add(&mut state.id, key, vault);
    state.token_data.add(key, TokenData {chain_id, token_address});
}


/// TODO: unregister token (migration / shutdown)
public fun unregister_token<T>(
    _: &mut AdminCap,
    state: &mut BridgeState
): TokenVault {
    let key = type_name::with_defining_ids<T>();
    let vault = dof::remove<TypeName, TokenVault>(&mut state.id, key);
    state.token_data.remove(key);
    vault
}

/**
* @dev function to mint bridged token
* @param amount amount of token to mint
* @param receiver
* @param deposit_nonce it's unique id keccak256("chai_id--token_id--deposit_nonce")
*/
public fun mint<T> (
    state: &mut BridgeState,
    amount: u64,
    receiver: address,
    deposit_nonce: vector<u8>,
    signature: &vector<u8>,
    ctx: &mut TxContext
) {
    // Replay protection
    assert!(
        !table::contains(&state.used_nonces, deposit_nonce),
        ENONCE_USED
    );

    let key = type_name::with_defining_ids<T>();
    let token_data = state.token_data.borrow(key);

    // Build deposit data
    let deposit_data = DepsitData {
        token_address: token_data.token_address,
        amount: amount as u256,
        chain_id: token_data.chain_id,
        receiver: receiver,
        deposit_nonce: deposit_nonce
    };

    // use bcs to serialize the deposit data
    let msg = bcs::to_bytes(&deposit_data); 

    // Verify relayer signature
    assert!(
        ed25519::ed25519_verify(signature, &state.relayer_public_key, &msg),
        EINVALID_SIGNATURE
    );

    // Mark nonce as used
    table::add(&mut state.used_nonces, deposit_nonce, true);

    // first get the mut ref of vault
    let vault = dof::borrow_mut<TypeName, TokenVault>(&mut state.id, key);
    
    // get the mut ref of treasury cap
    let cap = vault.borrow_cap_mut<T>();

    // then mint token to receiver
    let tokens = coin::mint(cap, amount, ctx);
    transfer::public_transfer(tokens, receiver);

    emit(MintEvent {
        token_type: key,
        amount: amount,
        receiver: receiver,
        deposit_nonce: deposit_nonce
    });
}


#[allow(lint(self_transfer))]
public fun burn<T> (
    state: &mut BridgeState,
    coin: Coin<T>,
    receiver: String // receiver on other chain
) {
    // first get the mut ref of vault
    let key = type_name::with_defining_ids<T>();
    let token_data = state.token_data.borrow(key);
    let vault = dof::borrow_mut<TypeName, TokenVault>(&mut state.id, key);

    // get the mut ref of treasury cap
    let cap = vault.borrow_cap_mut<T>();
    let amount = coin.value() as u256;
    coin::burn(cap, coin);

    state.burn_nonce = state.burn_nonce + 1;

    let burn_nonce = state.burn_nonce;

    event::emit(BurnEvent {
        token_address: token_data.token_address,
        amount,
        chain_id: token_data.chain_id,
        receiver: receiver,
        burn_nonce
    });
}