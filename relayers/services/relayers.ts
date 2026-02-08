import * as amoyService from "../services/amoyServices"
import type { IntentData } from "../types";

export async function verifyDeposit(intentData: IntentData): Promise<boolean> {
    let {
        inputChainId, 
        depositAddress, 
        inputTokenAddress, 
        inputAmount
    } = intentData;
    
    if (inputChainId == "80002") {
        return amoyService.verifyDeposit(
            depositAddress, 
            inputTokenAddress,
            inputAmount
        );
    } 

    return false;
}

export async function depositUserFunds(intentData: IntentData) {
    let {
        inputChainId
    } = intentData;

    if(inputChainId == "80002") {
        
    }

    
}