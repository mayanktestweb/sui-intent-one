import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);

const monitoredAddresses = new Set([
  "0xfaf3bfF7EC03F8D7244B8c684BF2D9C1405d60E2".toLowerCase(),
]);

provider.getBalance("0xA623c6877c318e14ed50459aE26d87572721EC8d").then((bal) => {
  console.log("Initial Balance:", ethers.formatEther(bal));
  return bal;
});