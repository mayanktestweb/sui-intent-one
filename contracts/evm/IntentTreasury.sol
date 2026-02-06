// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IntentTokenBridge.sol";

contract IntentTreasury is Ownable {

    event IntentCreated(
        bytes32 indexed id,
        address indexed user,
        address depositedToken,
        uint256 depositedAmount,
        bool exactIn,
        uint8 slippageTolerance,
        string outToken,
        string outChainId,
        uint256 expectedOutAmount,
        uint256 minOutAmount
    );

    event IntentExecuted(
        bytes32 indexed id,
        address indexed user,
        address depositedToken,
        uint256 depositedAmount,
        bool exactIn,
        uint8 slippageTolerance,
        string outToken,
        string outChainId,
        uint256 expectedOutAmount,
        uint256 minOutAmount
    );

    struct IntentData {
        bytes32 id;
        uint256 expiry;
        address depositedToken; // address(0) for native token
        uint256 depositedAmount;
        bool exactIn;
        uint8 slippageTolerance;
        string outToken;
        string outChainId;
        uint256 expectedOutAmount;
        uint256 minOutAmount;
        address user; // Added user address to track who created the intent
    }
    
    address public intentRelayer;
    IntentTokenBridge public intentTokenBridge;
    mapping ( bytes32 => IntentData ) public intents;

    constructor(address relayer, address payable tokenBridge) Ownable(msg.sender) {
        intentRelayer = relayer;
        intentTokenBridge = IntentTokenBridge(tokenBridge);
    }

    modifier onlyRelayer() {
        require(msg.sender == intentRelayer, "Only relayer can call this function");
        _;
    }

    // As user might pay with native tokens
    receive() external payable { }

    function setRelayer(address relayer) external onlyOwner {
        intentRelayer = relayer;
    }


    // function to create intent in native currency (only relayer)
    function createIntentNative(
        bytes32 id,
        bool exactIn,
        uint8 slippageTolerance,
        string memory outToken,
        string memory outChainId,
        uint256 expectedOutAmount,
        uint256 minOutAmount,
        address user
    ) external payable onlyRelayer {
        require(msg.value > 0, "Zero amount is not valid!");
        require(intents[id].id == bytes32(0), "Intent with this ID already exists");
        
        // expiry is set to 2 hours from now
        uint256 expiry = block.timestamp + 2 hours;
    
        // Store the intent data
        intents[id] = IntentData({
            id: id,
            expiry: expiry,
            depositedToken: address(0),
            depositedAmount: msg.value,
            exactIn: exactIn,
            slippageTolerance: slippageTolerance,
            outToken: outToken,
            outChainId: outChainId,
            expectedOutAmount: expectedOutAmount,
            minOutAmount: minOutAmount,
            user: user
        });

        emit IntentCreated(
            id,
            user,
            address(0),
            msg.value,
            exactIn,
            slippageTolerance,
            outToken,
            outChainId,
            expectedOutAmount,
            minOutAmount
        );
    }


    // function to create intent with ERC20 tokens (only relayer)
    function createIntentERC20(
        bytes32 id,
        address token,
        uint256 amount,
        bool exactIn,
        uint8 slippageTolerance,
        string memory outToken,
        string memory outChainId,
        uint256 expectedOutAmount,
        uint256 minOutAmount,
        address user
    ) external onlyRelayer {
        require(amount > 0, "Zero amount is not valid!");
        require(intents[id].id == bytes32(0), "Intent with this ID already exists");
        
        // expiry is set to 2 hours from now
        uint256 expiry = block.timestamp + 2 hours;
    
        // Store the intent data
        intents[id] = IntentData({
            id: id,
            expiry: expiry,
            depositedToken: token,
            depositedAmount: amount,
            exactIn: exactIn,
            slippageTolerance: slippageTolerance,
            outToken: outToken,
            outChainId: outChainId,
            expectedOutAmount: expectedOutAmount,
            minOutAmount: minOutAmount,
            user: user
        });
    }


    // function to execute intent (only relayer)
    function executeIntent(bytes32 id, bytes32 resolverSuiAddress) external onlyRelayer {
        IntentData memory intent = intents[id];
        require(intent.id != bytes32(0), "Intent does not exist");
        require(block.timestamp <= intent.expiry, "Intent has expired");
        
        // Call the intentTokenBridge to execute the intent
        intentTokenBridge.deposit(intent.depositedToken, intent.depositedAmount, resolverSuiAddress);
    
        emit IntentExecuted(
            id,
            intent.user,
            intent.depositedToken,
            intent.depositedAmount,
            intent.exactIn,
            intent.slippageTolerance,
            intent.outToken,
            intent.outChainId,
            intent.expectedOutAmount,
            intent.minOutAmount
        );
    }


    // function to withdraw funds after intent expiry
    function withdraw(bytes32 id) external {
        IntentData memory intent = intents[id];
        require(intent.id != bytes32(0), "Intent does not exist");
        require(block.timestamp > intent.expiry, "Intent has not expired yet");
        require(intent.user == msg.sender, "Only the user who created the intent can withdraw");

        // Delete the intent to prevent re-entrancy
        delete intents[id];

        // Withdraw the funds
        if (intent.depositedToken == address(0)) {
            // Withdraw native token
            (bool success, ) = payable(msg.sender).call{value: intent.depositedAmount}("");
            require(success, "Failed to withdraw native token");
        } else {
            // Withdraw ERC20 token
            IERC20(intent.depositedToken).transfer(msg.sender, intent.depositedAmount);
        }
    }
}