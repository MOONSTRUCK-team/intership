pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Quiz.sol";

contract QuizTest is Test {
    Quiz public quizContract;

    function setUp() public {
        quizContract = new Quiz();
    }

    function testFail_RewardPayment() public {
        quizContract.withdrawReward();
    }

    

}