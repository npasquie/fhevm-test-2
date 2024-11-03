// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";

/// @notice Yao's millionaire problem FHEVM implementation
/// finds who is the richest among Alice, Bob, and Carol
contract YaoPrivate is GatewayCaller {
    address immutable alice;
    address immutable bob;
    address immutable carol;
    euint64 highestWealth;
    address public richest;

    /// @dev this contract accepets 3 user but the same logic can be used
    /// for an arbitrary number of users.
    constructor(address _alice, address _bob, address _carol) {
        alice = _alice;
        bob = _bob;
        carol = _carol;
        highestWealth = TFHE.asEuint64(0);
        TFHE.allow(highestWealth, address(this));
    }

    /// @notice Privately evaluates the wealth of the user and asynchronoulsy
    /// updates the richest user if needed.
    /// @dev alternatlively, wealth submission could be done through an encrypted erc20.
    /// since the standard does not have a method to share encrypted balances
    /// with another contract, we would have to approve, then transfer the full
    /// wealth of the user to this contract, which would save its encrypted balance
    /// difference before and after the transfer, then transfer the full amount back
    /// to the user, then use this value to determine teh richest user.
    function submitWealth(einput _wealth, bytes calldata inputProof) external {
        require(
            msg.sender == alice || msg.sender == bob || msg.sender == carol,
            "Only Alice, Bob, and Carol can submit wealth"
        );

        euint64 wealth = TFHE.asEuint64(_wealth, inputProof);

        ebool isTheWealthiest = TFHE.gt(wealth, highestWealth);
        highestWealth = TFHE.select(isTheWealthiest, wealth, highestWealth);
        TFHE.allow(highestWealth, address(this));

        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(isTheWealthiest);
        uint256 requestID = Gateway.requestDecryption(
            cts,
            this.isTheWealthiestDecryptionCallback.selector,
            0,
            block.timestamp + 100,
            false
        );
        addParamsAddress(requestID, msg.sender);
    }

    /// @notice Callback reserved for the gateway
    function isTheWealthiestDecryptionCallback(uint256 requestID, bool decryptedIsTheWealthiest) external onlyGateway {
        address[] memory sender = new address[](1);
        sender = getParamsAddress(requestID);
        if (decryptedIsTheWealthiest) {
            richest = sender[0];
        }
    }
}
