import { ethers, keccak256, toUtf8Bytes } from "ethers";
import supportedChains from "../res/supportedChains.json"
import type { IntentData, RandomSignerData } from "../types"

export function generateDepositAddress(chainId: string): RandomSignerData | null {
    const chain = supportedChains.find(chain => chain.chainId == chainId)

    if (chain?.chainType == "evm") {

        const randomSigner = ethers.Wallet.createRandom()
        const address = randomSigner.address.toString();
        const pubkey = randomSigner.address.toString();
        const privkey = randomSigner.privateKey;
        
        // intent id is keccek256 of string representing hex value of address
        const intentId = keccak256(toUtf8Bytes(address));

        return {
                address,
                pubkey,
                privkey,
                chainId,
                intentId
            }

    } else {
        return null
    }
}

export function stringifyIntentData(intentData: IntentData): string {
    /**
     * intentId: string;
    inputTokenId: string;
    inputTokenAddress: string;
    inputAmount: bigint;
    inputChainId: string;
    outputTokenId: string;
    outputTokenAddress: string;
    outputAmount: bigint;
    minOutputAmount: bigint;
    outputChainId: string,
    receiverAddress: string,
    depositAddress: string,
    privKey: string
     */
    let sIntentData = {
        ...intentData, 
        inputAmount: intentData.inputAmount.toString(),
        outputAmount: intentData.outputAmount.toString(),
        minOutputAmount: intentData.minOutputAmount.toString()
    };   

    return JSON.stringify(sIntentData)
}


export function parseIntentData(
    // intentDataObj: {
    //     intentId: string;
    // inputTokenId: string;
    // inputTokenAddress: string;
    // inputAmount: string;
    // inputChainId: string;
    // outputTokenId: string;
    // outputTokenAddress: string;
    // outputAmount: string;
    // minOutputAmount: string;
    // outputChainId: string,
    // receiverAddress: string,
    // depositAddress: string,
    // privKey: string
    // }
    intentDataObj: string
): IntentData {
    const idata = JSON.parse(intentDataObj)
    console.log(idata)
    const newIntentData = {
        ...idata,
        inputAmount: ethers.parseUnits(idata.inputAmount, 0),
        outputAmount: ethers.parseUnits(idata.outputAmount, 0),
        minOutputAmount: ethers.parseUnits(idata.minOutputAmount, 0)
    }

    return newIntentData
}