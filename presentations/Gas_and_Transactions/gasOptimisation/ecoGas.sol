// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasOptimizationExample {
    ///Koriscenje immutable variable
    address public immutable MY_ADDRESS;
    uint public immutable MY_UINT;
    /// Koriscenje constant variable
    address public constant BURN_ADDRESS = "0x000000..";
    
    /// Pakiranje varijabli
    uint128 c; 
    uint128 b; 
    uint256 a;
    
    constructor(uint _myUint) {
        MY_ADDRESS = msg.sender;
        MY_UINT = _myUint;
    }

    function deposit(uint256 _amount) external payable {
        ///  lokalne promenljive za privremene podatke jer kostaju manje gasa
        uint256 amountToDeposit = _amount;

        ///koristiti evente umesto da cuvate nepotrebne podatke on-chain.
        emit Deposit(msg.sender, amountToDeposit);


    }
	///koriscenje view funkcija kosta manje gasa
    function getTotalBalance() external view returns (uint256) {
        return totalBalance;
    }
	/// koriscenje pure fukncije kosta manje gasa i koriscenje calldata
    function processArray(uint256[] calldata data) external pure returns (uint256) {
        uint256 total;
	uint256 counter;
	uint256 nonZero = 1;  /// non zero to non zero je jeftinije nego zero to non zero value	
	string storage cacheRead = "read me as a cache"; ///storage var
	uint256 length = data.length /// Kesiranje duzine za itrerianje kroz array

        for (uint256 i = 0; i < length; i++){
            uint256 currentValue = data[i];
	    string memory readAsCache = cacheRead; /// Koriscenje memorije da citamo kesirane storage var sto je jeftinije od citanja storage var direktno
            
	    /// Logicke operacije su jeftinije od artimetickih
            if (currentValue % 2 == 0) {
                total += currentValue;
		unchecked {
		  /// Cuva 14% gasa nego inace kada bi koristili increment za var
		  /// Unchecked ne koristi over/underflow cekiranje 
		  ++counter; /// umesto counter++
		}
            }
        }

        return total;
    

   
}

