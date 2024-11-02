// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YaoNotPrivate {
    address immutable alice;
    address immutable bob;
    address immutable carol;
    uint256 public highestWealth;
    address public richest;

    constructor(address _alice, address _bob, address _carol) {
        alice = _alice;
        bob = _bob;
        carol = _carol;
    }

    function submitWealth(uint256 wealth) external {
        require(
            msg.sender == alice || msg.sender == bob || msg.sender == carol,
            "Only Alice, Bob, and Carol can submit wealth"
        );
        if (wealth > highestWealth) {
            highestWealth = wealth;
            richest = msg.sender;
        }
    }
}
