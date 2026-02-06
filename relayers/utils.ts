// In this file we will investigate the sui public key
import {Ed25519Keypair} from "@mysten/sui/keypairs/ed25519";

const keypair = Ed25519Keypair.fromSecretKey(process.env.SUI_PRIV_KEY || "");
console.log("Public Key:", keypair.getPublicKey().toSuiAddress());
console.log("Public Key Bytes:", keypair.getPublicKey().toRawBytes());