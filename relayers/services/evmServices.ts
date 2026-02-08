import { Contract } from "ethers";
import { ethers } from "ethers"
import type { IntentData } from "../types";
import evmIntentTreasury from "../res/evmIntentTreasury.json"

export async function verifyDeposit(
    depositAddress: string,
    tokenAddress: string,
    inputAmount: bigint,
    rpcUrl: string
) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);

    if (tokenAddress = "0x0000000000000000000000000000000000000000") {
        const balance = await provider.getBalance(depositAddress);
        console.log(inputAmount, balance);
        return balance >= inputAmount
    } 

    const minABI = [
        "function balanceOf(address owner) view returns (uint256)",
        "function decimals() view returns (uint8)",
        "function symbol() view returns (string)"
    ]; 

    const tokenContract = new Contract(tokenAddress, minABI, provider);
    if(!tokenContract.balanceOf) {
        console.log("ERROR: Token Contract not working")
        return false
    };
    const balance = await tokenContract.balanceOf(depositAddress)

    return balance >= inputAmount
}


export function depositUserFunds(
    intentTreasury: string,
    intentData: IntentData,
    rpcUrl: string
) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);

    const contract = new Contract(intentTreasury, evmIntentTreasury, provider);
    // contract.
}