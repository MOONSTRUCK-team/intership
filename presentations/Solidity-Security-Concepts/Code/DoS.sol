// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
///@title Auction example contract
///custom:autcionDoS Code is vulnerable to DoS attack
contract Auction {
    ///Setting gas limit per iteration 20000 is only an example
    uint256 constant gas_limit = 20000;


    ///@notice Example function that can cause DoS 
    function processTransaction(uint[] memory data) public {
      for(uint i = 0; i < data.length; i++) { ///for loop that iterates through data array
      /// Expensive work
      }
    }


    ///@notice processTransaction but with gas limit for DoS protection
    function fixedProcessTransaction(uint[] memory data) public {
        for(uint i = 0; i < data.length && gasleft() > gas_limit; i++) {
            /// Expensive work which now has a gas limit.
        }
    }


}


