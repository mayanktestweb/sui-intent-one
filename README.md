# Sui Intent - Cross-Chain Digital Asset Exchange

## What is Sui Intent?

Sui Intent is a decentralized intent-based digital asset exchange protocol that enables seamless cross-chain asset swaps between Sui and EVM networks. Users express their trading intentions specifying the asset they want to exchange, the desired output token, and acceptable price parameters. The protocol's solvers and relayers execute these intents efficiently across blockchain boundaries, abstracting away complex multi-chain interactions while maintaining security through cryptographic verification and escrow mechanisms.

## How It's Built

Sui Intent combines Move smart contracts on Sui with Solidity contracts on EVM chains, connected by a TypeScript relayer network. The architecture features bridge contracts for cross-chain token transfers, an intent escrow system for secure transaction settlement, and a treasury for managing locked assets. Relayers monitor the network, match intents with available liquidity, verify transactions through ed25519 signatures, and execute swaps atomically across chains while handling quote routing and settlement validation.

---

## Project Structure

### **Contracts** (`/contracts`)

#### Sui Contracts (`/contracts/sui`)
- **bridge**: Cross-chain token bridge with vault management and signature verification
- **intent_escrow**: Core intent matching and settlement engine
- **intent_treasury**: Asset treasury for managing deposits and withdrawals
- **tokens/polygon_usdc**: Custom token implementation for wrapped USDC

#### EVM Contracts (`/contracts/evm`)
- **IntentTokenBridge.sol**: EVM-side bridge contract for token transfers
- **IntentTreasury.sol**: Treasury management on EVM networks

### **Relayers** (`/relayers`)
TypeScript services orchestrating cross-chain operations:
- **bridgeRelayer_Sui.ts**: Sui blockchain monitoring and relaying
- **bridgeRelayer_Evm.ts**: EVM network monitoring and relaying
- **depositEventListener_EVM.ts**: Monitors deposit events on EVM chains
- **routes/**: API endpoints for quotes and token information
- **services/**: Business logic for Amoy, EVM, and solver services

### **Scripts** (`/scripts`)
Utility scripts for local testing and demo data generation

---

## Key Features

- **Intent-Based Architecture**: Users specify what they want, not how to execute it
- **Cross-Chain Settlement**: Seamless asset exchange between Sui and EVM networks
- **Cryptographic Verification**: Ed25519 signatures ensure transaction authenticity
- **Escrow Protection**: Secure settlement with timeout mechanisms
- **Multi-Token Support**: Extensible token bridge supporting various assets
- **Solver Network**: Decentralized execution through multiple solvers

---

## Getting Started

### Prerequisites
- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install)
- [Move](https://move-language.github.io/)
- Node.js 18+ with Bun or npm
- Solidity compiler for EVM contracts

### Installation

#### Setting up Sui Contracts
```bash
cd contracts/sui/bridge
sui move build
sui move test
```

#### Setting up Relayers
```bash
cd relayers
bun install
# or npm install
```

#### Setting up Scripts
```bash
cd scripts
npm install
```

---

## Development Status

This project is actively under development as part of the ETHGlobal MoneyHack hackathon. Core functionality for intent creation, escrow management, and cross-chain bridging is implemented, with ongoing optimization and testing.

---

## License

[Add your license information here]

---

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
