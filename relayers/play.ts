import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider("https://polygon-amoy.drpc.org")
const balance = await provider.getBalance("0x2A8cCEb16123F6e852ad37a156e4BB1e2fa44c46")
console.log(balance)