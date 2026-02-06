import {generateEvmDepositSignature, callMintOnSui} from './bridgeRelayer_Evm';

let sig = await generateEvmDepositSignature({
    tokenAddress: "0x41E91E218d89a42f7039a038f9f4a956165b47a0",
    amount: BigInt(2000000000000000000), // 1 token with 18 decimals
    recipientSuiAddress: "0xe2229604840661668e09035a65f33cfdb62200445b1528496d0a6872b1ae89aa",
    depositNonce: 2356, // unique nonce for the deposit
    chainId: "80002", // Ethereum Mainnet
});

console.log(sig);


callMintOnSui({
    amount: BigInt(2000000000000000000), // 1 token with 18 decimals
    recipientSuiAddress: "0xe2229604840661668e09035a65f33cfdb62200445b1528496d0a6872b1ae89aa",
    depositNonce: 2356, // unique nonce for the deposit
    signature: sig,
    bridgeTokenType: "0x507dc34490d725f0113e8af1e527ac0bcb5d2d26b398f26f0b78875f08867bb::polygon_usdc::POLYGON_USDC"
});