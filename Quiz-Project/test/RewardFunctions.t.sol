pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Quiz.sol";

contract QuizTest is Test {
    Quiz public quizContract;

    event Log(string func, uint256 gas);

    function setUp() public {
        uint256 aTs = block.timestamp + 7 days;
        uint256 rTs = aTs + 2 days;
        string[] memory questions;
        questions = new string[](2);
        questions[0] = "1";
        questions[1] = "2";

        bytes32[] memory answerCommits = new bytes32[](2);
        answerCommits[0] = keccak256(abi.encodePacked("1"));
        answerCommits[1] = keccak256(abi.encodePacked("1"));

        quizContract = new Quiz(0, 0, aTs, rTs, questions, answerCommits);
    }

    function test_RevertWhen_NotWinner() public {
        vm.expectRevert("You do not qualify for a reward");
        quizContract.withdrawReward();
    }

    function testContractEthBalance() public view {
        console.log("ETH Balance", address(quizContract).balance / 1e18);
    }

    function test_RewardPayment() public {
        vm.deal(address(quizContract), 10 ether);
        hoax(address(this));
        quizContract.withdrawReward();
    }

    function test_LeftoverEthWithdraw() public {
        vm.expectRevert("Winners still have time to withdraw rewards");
        vm.deal(address(quizContract), 10 ether);
        hoax(address(this));
        quizContract.withdrawLeftoverEther();
    }

    receive() external payable {
        emit Log("receive", gasleft());
    }
}
