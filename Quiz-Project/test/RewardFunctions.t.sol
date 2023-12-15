pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Quiz.sol";

contract QuizTest is Test {
    Quiz public quizContract;
    event Log(string func, uint gas);

    function setUp() public {
        quizContract = new Quiz();
    }

    

    function test_RevertWhen_NotWinner() public {
        vm.expectRevert("You do not qualify for a reward");
        quizContract.withdrawReward();
    }


    function testContractEthBalance() public {
        console.log("ETH Balance", address(quizContract).balance / 1e18);
    }


    function test_RewardPayment() public {
        vm.deal(address(quizContract), 10 ether);
        hoax(address(this));
        quizContract.withdrawReward();
    }


    receive() external payable {
        emit Log("receive", gasleft());
    }

    

}