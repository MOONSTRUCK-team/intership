// BadPracticeSmartContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract BadPracticeSmartContract {
    address public owner;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = tx.origin;
    }

    function transfer(address to, uint256 value) external {
        // Ne koristi se msg.sender 
        // Nema validacije unosa
        balances[tx.origin] -= value;
        balances[to] += value;
        emit Transfer(tx.origin, to, value);
    }
}