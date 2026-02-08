/**
 * Global types for the SUI-EVM Bridge Relayer application
 */

export interface RandomSignerData {
    address: string;
    pubkey: string;
    privkey: string;
    chainId: string;
    intentId: string;
}

export interface IntentData {
    intentId: string;
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
}

/**
 * Supported token information
 */
export interface SupportedToken {
  coinId: string;
  name: string;
  symbol: string;
  decimals: number;
  address: string; // EVM token address in hex format
  bridgeWrapedId: string; // Sui bridge token type
  chainId: string; // Chain ID of the EVM chain
}

/**
 * Deposit event from EVM chain
 */
export interface DepositEvent {
  tokenAddress: string;
  amount: bigint;
  recipientSuiAddress: string;
  depositNonce: number;
  chainId: string;
  txHash?: string;
  blockNumber?: number;
  timestamp?: number;
}

/**
 * Mint request parameters for Sui chain
 */
export interface MintRequest {
  amount: bigint;
  recipientSuiAddress: string;
  depositNonce: number;
  signature: Uint8Array;
  bridgeTokenType: string;
  txHash?: string;
}

/**
 * Quote response for token swap or transfer
 */
export interface QuoteResponse {
  fromToken: string;
  toToken: string;
  fromAmount: string;
  toAmount: string;
  rate: number;
  slippage?: number;
  estimatedGas?: string;
  expiresAt?: number;
}

/**
 * Deposit signature parameters
 */
export interface DepositSignatureParams {
  tokenAddress: string;
  amount: bigint;
  recipientSuiAddress: string;
  depositNonce: number;
  chainId: string;
}

/**
 * User deposit address record
 */
export interface DepositAddressRecord {
  userId: string;
  evmAddress: string;
  suiAddress: string;
  createdAt: number;
  lastUsed?: number;
}

/**
 * Bridge transaction status
 */
export enum TransactionStatus {
  PENDING = "pending",
  CONFIRMED = "confirmed",
  FAILED = "failed",
  COMPLETED = "completed",
}

/**
 * Bridge transaction record
 */
export interface BridgeTransaction {
  id: string;
  sourceChain: "evm" | "sui";
  destinationChain: "evm" | "sui";
  status: TransactionStatus;
  sourceToken: string;
  amount: bigint;
  recipientAddress: string;
  senderAddress: string;
  sourceChainTxHash?: string;
  destinationChainTxHash?: string;
  createdAt: number;
  updatedAt: number;
  errorMessage?: string;
}

/**
 * API Response wrapper
 */
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  code?: number;
}

/**
 * Environment configuration
 */
export interface EnvironmentConfig {
  port: number;
  suiPrivateKey: string;
  executorRecoveryPhrase: string;
  suiBridgeModule: string;
  suiBridgeState: string;
  evmRpcUrl?: string;
  suiRpcUrl?: string;
}
