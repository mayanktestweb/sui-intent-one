import {Router} from 'express';
import supportedTokens from "../res/supportedTokens.json";
import { ethers } from 'ethers';
import { generateDepositAddress, parseIntentData, stringifyIntentData } from '../services/utils';
import fs from 'fs/promises';
import path from 'path';
import * as solversServices from '../services/solvers';
import * as relayerServices from '../services/relayers';
import type { IntentData } from '../types';

const router = Router();

const filePath = path.join(__dirname ,"../res/depositAddresses.json")

router.get("/", async (req, res) => {
    // extract deposit token
    const {coinId, amount, outputCoinId, receiverAddress} = req.query;

    // ensure it's existence in res/supportedTokens.json
    const token = supportedTokens.find(t => t.coinId == coinId);
    const outToken = supportedTokens.find(t => t.coinId == outputCoinId);
    if (!token || !outToken) {
        return res.status(400).json({ error: "Unsupported token" });
    }

    // generate a unique deposit address for the user (can be a hash of user id + token address + timestamp)
    const signer = generateDepositAddress(token.chainId);
    if(!signer) return res.status(404).json({error: "Token not supported!"})

    // store the mapping of deposit address to user id and token 
    // address in a JSON file (e.g., ./res/depositAddresses.json)
    
    const fileDataRaw = JSON.parse((await fs.readFile(filePath)).toString())
    const fileData: Array<IntentData> = fileDataRaw.map((e: any) => parseIntentData(e));

    const inputAmount = ethers.parseUnits(amount as string, token.decimals);

    const exchange = await solversServices.getSwapExchange(
        signer.intentId || "",
        coinId as string,
        inputAmount,
        outputCoinId as string
    );
    let newIntentData: IntentData = {
        intentId: signer.intentId,
        inputTokenId: coinId as string,
        inputTokenAddress: token.address,
        inputAmount: exchange.inputAmount,
        inputChainId: token.chainId,
        outputTokenId: outToken.coinId,
        outputTokenAddress: outToken.address,
        outputAmount: exchange.outputAmount,
        minOutputAmount: exchange.minOutputAmount,
        outputChainId: outToken.chainId,
        receiverAddress: receiverAddress as string,
        depositAddress: signer.address,
        privKey: signer.privkey
    }
    fileData.push(newIntentData);
    
    try {
        let stringifiedFileData = fileData.map(e => stringifyIntentData(e))
        await fs.writeFile(filePath, JSON.stringify(stringifiedFileData))
    } catch (error) {
        console.log(error)
        return res.status(500).send("Internal Server Error!")
    }


    // return the generated deposit address to the user
    res.status(200).json({
        inputTokenId: newIntentData.inputTokenId,
        inputTokenName: token.name,
        inputTokenAddress: newIntentData.inputTokenAddress,
        inputAmount: newIntentData.inputAmount.toString(),
        outputTokenId: newIntentData.outputTokenId,
        outputTokenName: outToken.name,
        outputTokenAddress: newIntentData.outputTokenAddress,
        outputAmount: newIntentData.outputAmount.toString(),
        minOutputAmount: newIntentData.minOutputAmount.toString(),
        depositAddress: newIntentData.depositAddress, 
        intentId: newIntentData.intentId
    });
});

router.post("/deposited", async (req, res) => {
    const { intentId } = req.body

    // take the data about intent from deposited address
    //const fileDataRaw: Array<{
        // intentId: string;
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
    //}> = 
    const fileDataRaw = JSON.parse((await fs.readFile(filePath)).toString())

    const fileData: Array<IntentData> = fileDataRaw.map((e: any) => parseIntentData(e));
    
    const intentData = fileData.find(data => data.intentId == intentId as string);
    if(!intentData) return res.status(400).send("Intent Not Found!");

    // use input token chain relayer and  
    // (a) verify the token has been deposited
    const inputToken = supportedTokens.find(token => token.coinId == intentData.inputTokenId);
    if(!inputToken) return res.status(400).send("Bad Request!");
    const deposited = await relayerServices.verifyDeposit(intentData);

    if(!deposited) return res.status(400).send("Bad Request");
    res.status(200).send("Funds deposited!")
    // (b) deposit user funds in native chain's IntentTreasury
    //     create intent


    // (c) create intent object on SUI intent escrow

    // (d) notify solvers to fullfill the intent
})

export default router;