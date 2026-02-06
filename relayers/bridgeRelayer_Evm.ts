// This relayer for EVM-based chains will listen to events on the source chain (e.g., Ethereum, Binance Smart Chain, etc.)
// and relay them to the destination chain (e.g., Sui, Solana, etc.) using the appropriate bridge protocol.
// It will also handle generating signatures for verification on other chains.

// function to generate deposit signature for SUI Smart Contract
// bridge of sui will verify deposit on evm chain by this signature

import {Ed25519Keypair} from "@mysten/sui/keypairs/ed25519"; 
import {bcs} from "@mysten/sui/bcs";
import { SerialTransactionExecutor, Transaction } from "@mysten/sui/transactions";
import { SuiGrpcClient } from "@mysten/sui/grpc";
import { ethers } from "ethers";


// function to generate transaction executor for SUI smart contract
export function generateTransactionExecutor(): SerialTransactionExecutor {
    const keypair = Ed25519Keypair.deriveKeypair(process.env.EXECUTOR_RECOVERY_PHRASE || "");

    const grpcClient = new SuiGrpcClient({
        network: 'testnet',
        baseUrl: 'https://fullnode.testnet.sui.io:443',
    });

    const executor = new SerialTransactionExecutor({
        client: grpcClient, 
        signer: keypair
    });
    return executor;
}


export async function generateEvmDepositSignature({
    tokenAddress,
    amount,
    recipientSuiAddress,
    depositNonce,
    chainId,
}: {
    tokenAddress: string; // EVM token address in hex format
    amount: bigint; // amount to deposit
    recipientSuiAddress: string; // Sui address in hex format
    depositNonce: number; // unique nonce for the deposit
    chainId: string; // chain ID of the EVM chain
}): Promise<Uint8Array> {
    const secretKey = process.env.SUI_PRIV_KEY || "";
    const keypair = Ed25519Keypair.fromSecretKey(secretKey);

    // Prepare the message to be signed
    const data_bytes = bcs.struct("DepsitData", {
        token_address: bcs.String,
        amount: bcs.U256,
        chain_id: bcs.String,
        receiver: bcs.Address,
        deposit_nonce: bcs.vector(bcs.U8)
    }).serialize({
        token_address: tokenAddress,
        amount: amount,
        chain_id: chainId,
        receiver: recipientSuiAddress,
        deposit_nonce: Uint8Array.from(depositNonce.toString().split(",").map(Number))
    }).toBytes();

    return await keypair.sign(data_bytes);
}


// function to send deposit data along with signature to SUI smart contract
export async function callMintOnSui({
    amount,
    recipientSuiAddress,
    depositNonce,
    signature,
    bridgeTokenType
}: {
    amount: bigint; // amount to deposit
    recipientSuiAddress: string; // Sui address in hex format
    depositNonce: number; // unique nonce for the deposit
    signature: Uint8Array; // signature generated for the deposit
    bridgeTokenType: string; // bridge token type
}) {
    const executor = generateTransactionExecutor();

    const tx = new Transaction();
    /**
     * public fun mint<T> (
        state: &mut BridgeState,
        amount: u64,
        receiver: address,
        deposit_nonce: vector<u8>,
        signature: &vector<u8>,
        ctx: &mut TxContext
    )
     */
    const suiBridgeModule = process.env.SUI_BRIDGE_MODULE || "";
    const suiBridgeState = process.env.SUI_BRIDGE_STATE || "";
    tx.moveCall({
        target: `${suiBridgeModule}::bridge::mint`, // target function
        arguments: [
            tx.object(suiBridgeState),
            tx.pure.u64(amount),
            tx.pure.address(recipientSuiAddress),
            bcs.byteVector().serialize(Uint8Array.from(depositNonce.toString().split(",").map(Number))),
            bcs.byteVector().serialize(signature)
        ],
        typeArguments: [bridgeTokenType]
    });

    const result = await executor.executeTransaction(tx);
    console.log("Mint transaction result:", result);
}