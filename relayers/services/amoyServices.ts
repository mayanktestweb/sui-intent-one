import * as evmServices from "./evmServices";

const rpcUrl = process.env.AMOY_RPC_URL || "https://polygon-amoy.drpc.org"
const intentTreasuryAddress = process.env.AMOY_INTENT_TREASURY || ""

export async function verifyDeposit(
    depositAddress: string,
    tokenAddress: string,
    inputAmount: bigint
) {
    return evmServices.verifyDeposit(depositAddress, tokenAddress, inputAmount, rpcUrl)
}

export async function depositUserFunds(){
    
}