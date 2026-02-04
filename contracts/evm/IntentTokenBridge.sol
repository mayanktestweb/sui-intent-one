// SPDX-License-Identifier: MIT
pragma solidity 0.8;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract IntentTokenBridge is Ownable, EIP712 {

    /// EVENTS
    // Dispoit Event
    event Deposit(address indexed tokenAddress, address indexed depositor, bytes32 indexed reciever, uint256 amount, uint256 depositNonce, uint256 chainId);

    // Withdraw Event
    event Withdraw(address indexed tokenAddress, address indexed executor, uint256 amount, uint256 burnNonce, address receiver);

    // token burn verifier address
    address public burnVerifier;
    // list to of qualified tokens
    mapping (address => bool) public qualifiedTokens;

    struct DepositRecord {
        address token; // address(0) for native token
        address depositor;
        bytes32 reciever;
        uint256 amount;
        uint256 depositNonce;
        uint256 chainId;
    }

    // deposit nonce
    uint256 depositNonce;
    // desposit records mapped deposit nonce
    mapping (uint256 => DepositRecord) public depositRecords ;
    // used deposit nonces
    mapping (uint256 => bool) usedDepositNonces;
    
    // withdraw record
    struct WithdrawRecord {
        address token; // address(0) for native token
        uint256 amount;
        uint256 burnNonce;
        address receiver;
        uint256 chainId;
    }
    bytes32 private constant TYPED_WITHDRAW_RECORD = keccak256("WithdrawRecord(address token,uint256 amount,uint256 burnNonce,address receiver,uint256 chainId)");

    // used burn nonces
    mapping (uint256 => bool) usedBurnNonces;
    // withdraw records mapped burn nonce
    mapping (uint256 => WithdrawRecord) public withdrawRecords;

    receive() external payable { }

    // constructor with Ownable
    constructor(address _burnVerifier) Ownable(msg.sender) EIP712("WithdrawRegistery", "1") {
        burnVerifier = _burnVerifier;
    }


    /**
    * @dev functiont to change owner
    * @param newOwner The address of the new owner.
    */
    function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }


    /**
    * @dev Add a token to the qualified tokens list.
     * @param tokenAddress The address of the token to be added.
    */
    function addQualifiedToken(address tokenAddress) external onlyOwner {
        qualifiedTokens[tokenAddress] = true;
    }

    /**
    * @dev Change the burn verifier address.
    * @param _burnVerifier The address of the new burn verifier.
    */
    function changeBurnVerifier(address _burnVerifier) external onlyOwner {
        burnVerifier = _burnVerifier;
    }

    /**
     * @dev function to deposit native token mints bridge token on intent chain Sui
     * @param reciever reciever address on Sui Chain
    */
    function depositNativeToken(bytes32 reciever) external payable {
        require(msg.value > 0, "Error: Amount should be greater than 0");
        uint256 amount = msg.value;

        // increment nonce
        depositNonce++;

        // record deposit
        DepositRecord memory depositRecord = DepositRecord({
            depositor: msg.sender,
            amount: amount,
            token: address(0),
            reciever: reciever,
            depositNonce: depositNonce,
            chainId: block.chainid
        });
        // store deposit record
        depositRecords[depositNonce] = depositRecord;
        usedDepositNonces[depositNonce] = true;
        // emit deposit event
        emit Deposit(msg.sender, address(0), reciever, amount, depositNonce, block.chainid);
    }

    // function to deposit ERC20 token
    function deposit(address token, uint256 amount, bytes32 reciever) external {
        // check if token is valid
        if (token == address(0) || qualifiedTokens[token] == false) {
            revert("Invalid token address");
        }
        // check if amount is valid
        if (amount == 0) {
            revert("Invalid amount");
        }
        // check if reciever is valid
        if (reciever.length == 0) {
            revert("Invalid reciever");
        }

        IERC20(token).transfer(address(this), amount);
        
        depositNonce++;

        // record deposit
        DepositRecord memory depositRecord = DepositRecord({
            depositor: msg.sender,
            amount: amount,
            token: address(0),
            reciever: reciever,
            depositNonce: depositNonce,
            chainId: block.chainid
        });
        depositRecords[depositNonce] = depositRecord;
        usedDepositNonces[depositNonce] = true;
        
        // emit deposit event
        emit Deposit(msg.sender, token, reciever, amount, depositNonce, block.chainid);
    }

    /**
     * @dev function to withdraw ERC20 token
     * @param token address of the token to withdraw
     * @param amount amount of token to withdraw
     * @param burnNonce nonce of the burn transaction on bridge chain
     * @param receiver address of the reciever of the token
     * @param signature signature of the burn verifier
    */
    function withdraw(address token, uint256 amount, uint256 burnNonce, address receiver, bytes memory signature) external {
        // check if burnNonce is used
        require(!usedBurnNonces[burnNonce], "Withdrawal for nonce already used");
        usedBurnNonces[burnNonce] = true;

        // create withdraw record
        WithdrawRecord memory withdrawRecord = WithdrawRecord ({
            token: token,
            amount: amount,
            burnNonce: burnNonce,
            receiver: receiver,
            chainId: block.chainid
        });

        // verify withdraw by burn verifier
        bytes32 digest = _hashWithdrawRecord(withdrawRecord);
        address signer = ECDSA.recover(digest, signature);

        require(signer == burnVerifier, "Error: Invalid Signature!");

        if (token == address(0)) {
            (bool success, ) = payable(receiver).call{value: amount}("");
            require(success, "Failed to payout!");
        } else {
            IERC20(token).transfer(receiver, amount);
        }

        // record withdraw event
        withdrawRecords[burnNonce] = withdrawRecord;

        // emit withdraw event
        emit Withdraw(
            token,
            address(msg.sender),
            amount,
            burnNonce,
            receiver
        );
    }

    function _hashWithdrawRecord(WithdrawRecord memory _withdrawRecord) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    TYPED_WITHDRAW_RECORD,
                    _withdrawRecord.token,
                    _withdrawRecord.amount,
                    _withdrawRecord.burnNonce,
                    _withdrawRecord.receiver,
                    _withdrawRecord.chainId
                )
            )
        );
    }
}
