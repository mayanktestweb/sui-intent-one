// function to mimic real excnage 
// for testing now just give 90% of input amount
export async function getSwapExchange(
    intentId: string,
    inputToken: string,
    inputAmount: bigint,
    outputToken: string
) {
    return {
        intentId,
        inputToken,
        inputAmount,
        outputToken,
        outputAmount: (inputAmount * 90n) / 100n,
        minOutputAmount: (inputAmount * 80n) / 100n,
    };
}