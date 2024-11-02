// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";

import "hardhat/console.sol";

contract YaoPrivate is GatewayCaller {
    address immutable alice;
    address immutable bob;
    address immutable carol;
    euint64 highestWealth;
    address public richest;

    constructor(address _alice, address _bob, address _carol) {
        alice = _alice;
        bob = _bob;
        carol = _carol;
    }

    // alternatlively, wealth submission could be done through an encrypted erc20.
    // since the standard does not have a method to share encrypted balances
    // with another contract, we would have to approce, then transfer the full
    // wealth of the user to this contract, which would save the its encrypted balance
    // difference before and after the transfer, then transfer the full amount back
    // to the user, then using this value to determine teh richest user.
    function submitWealth(einput _wealth, bytes calldata inputProof) external {
        console.log("hey");
        require(
            msg.sender == alice || msg.sender == bob || msg.sender == carol,
            "Only Alice, Bob, and Carol can submit wealth"
        );

        euint64 wealth = TFHE.asEuint64(_wealth, inputProof);

        ebool isTheWealthiest = TFHE.gt(wealth, highestWealth);
        highestWealth = TFHE.select(isTheWealthiest, wealth, highestWealth);

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

    function isTheWealthiestDecryptionCallback(uint256 requestID, bool decryptedIsTheWealthiest) external onlyGateway {
        address[] memory sender = new address[](1);
        sender = getParamsAddress(requestID);
        if (decryptedIsTheWealthiest) {
            richest = sender[0];
        }
    }
}
