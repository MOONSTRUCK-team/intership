// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title contract for withdrawing balance
///@custom:broken-ac withdraw function is vulnerable to Broken Access Control
contract TransactionsAC {
    mapping(address => string) private roles;///user's roles mapping
    address private owner;/// storing a address of the contracts owner

    constructor() {
        owner = msg.sender; /// setting the address of the owner to a msg.sender
    }


    ///@notice Function for setting users role
    ///@dev Function has a Broken Access Control vulnerability
    ///@param user is an address of the desired user
    function setAdmin(address user) public {
        roles[user] = "admin"; /// Sets the users role to admin

    }


    ///@notice Function for setting users role
    ///@custom:fixed-ac this function has fixed the Broken AC vulnerabilty
    function fixedSetAdmin(address user) external {
      require(msg.sender == owner,"Unauthorized access"); ///Checks if a person who is calling this function has an Authorization to do so
      require(keccak256(abi.encodePacked(roles[user])) != keccak256(abi.encodePacked("admin")) , "User is already an Admin");///checks if the user is already an admin

      roles[user] = "admin";///Sets the users role to admin
    }

    ///Openzepplin Ownable, Access contracts
}
