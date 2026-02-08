import express from "express";

import quotesRouter from "./routes/quotes";
import tokensRouter from "./routes/tokens";
import fs from "fs";
import path from "path";

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));


app.get("/", (req, res) => {
  res.send("Hello, this is the SUI-EVM bridge relayer!");
});

// ensure `res` directory and `res/depositAddresses.json` exist to store deposit addresses
const resDir = path.resolve(process.cwd(), "res");
const depositAddressesPath = path.join(resDir, "depositAddresses.json");
if (!fs.existsSync(resDir)) {
  fs.mkdirSync(resDir, { recursive: true });
}
if (!fs.existsSync(depositAddressesPath)) {
  fs.writeFileSync(depositAddressesPath, JSON.stringify([]));
}

app.use("/quotes", quotesRouter);

app.use("/tokens", tokensRouter);

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});