// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";

/// @notice Yao's millionaire problem FHEVM implementation, finds who is the richest participant
contract YaoPrivate is GatewayCaller {
    mapping(address => bool) isParticipating;
    mapping(address => bool) hasSubmited;
    uint256 nbOfParticipants;
    uint256 nbOfSubmissions;
    euint64 highestWealth;
    eaddress currentRichest;
    address public richest; // 0 if the session richest is not yet decided

    constructor(address[] memory participants) {
        nbOfParticipants = participants.length;
        for (uint256 i = 0; i < nbOfParticipants; i++) {
            isParticipating[participants[i]] = true;
        }
        highestWealth = TFHE.asEuint64(0);
        currentRichest = TFHE.asEaddress(address(0));
    }

    /// @notice Privately evaluates the wealth of the caller, updates richest user and highest wealth
    function submitWealth(einput _wealth, bytes calldata inputProof) external {
        require(isParticipating[msg.sender], "You are not allowed to participate in this contest");
        require(!hasSubmited[msg.sender], "You have already submitted your wealth");

        euint64 callersWealth = TFHE.asEuint64(_wealth, inputProof);

        ebool callerIsTheWealthiest = TFHE.gt(callersWealth, highestWealth);
        highestWealth = TFHE.select(callerIsTheWealthiest, callersWealth, highestWealth);
        currentRichest = TFHE.select(callerIsTheWealthiest, TFHE.asEaddress(msg.sender), currentRichest);

        nbOfSubmissions++;
        hasSubmited[msg.sender] = true;

        decryptRichestOnLastSubmission();
    }

    function decryptRichestOnLastSubmission() internal {
        if (nbOfSubmissions != nbOfParticipants) {
            return;
        }

        TFHE.allow(currentRichest, address(this));
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(currentRichest);
        Gateway.requestDecryption(cts, this.richestDecryptionCallback.selector, 0, block.timestamp + 100, false);
    }

    function richestDecryptionCallback(uint256, address decryptedRichest) external onlyGateway {
        richest = decryptedRichest;
    }
}
