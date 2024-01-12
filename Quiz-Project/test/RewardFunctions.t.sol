pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Quiz.sol";

contract QuizTest is Test {
    Quiz public quizContract;
    string[] public questions;
    bytes32[] public answerCommits;
    uint256 public aTs;
    uint256 public rTs;
    bool isOwnerLate;
    uint8[] public correctAnswers;

    event Log(string func, uint256 gas);

    function setUp() public {
        aTs = block.timestamp + 7 days;
        rTs = aTs + 2 days;
        questions = new string[](2);
        questions[0] = "1";
        questions[1] = "2";

        answerCommits = new bytes32[](2);
        answerCommits[0] = keccak256(abi.encodePacked("1"));
        answerCommits[1] = keccak256(abi.encodePacked("1"));

        quizContract = new Quiz(0, 0, aTs, rTs, questions, answerCommits);
    }

    function test_Revert_WhenOwner_Answers() public {
        vm.expectRevert("Owner cannot participate");
        quizContract.provideAnswerCommits(answerCommits);
    }

    //--------------------
    // `ownerRevealsAnswers` tests
    //---------------------

    function test_ownerRevealsAnwers_revertsWhen_invalidTimeForReveal(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.warp(rTs + 7 days);
        
        vm.expectRevert("Invalid time for revaling answers");
        quizContract.ownerRevealsAnswers(answers, userSalts);
    }

    function test_ownerRevealsAnwers_revertsWhen_invalidNumberOfAnswers(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.assume(answers.length != userSalts.length);

        vm.expectRevert("Invalid number of answers");
        quizContract.ownerRevealsAnswers(answers, userSalts);
    }

    //--------------------
    // `finishWithQuiz` tests
    //---------------------

    function test_FinishWithQuiz_Prematurely(uint8 x) public {
        vm.assume(x > 0);
        vm.warp(rTs + x);
        quizContract.finishWithQuiz();
    }

    function test_Revert_revealUserAnswer(uint8[] calldata answers, bytes32[] calldata userSalts) public {
        vm.expectRevert("Quiz answers are not revealed yet");
        quizContract.revealUserAnswer(answers, userSalts);
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

    function test_RewardPayment() public {
        stdstore.target(address(quizContract)).sig("winners(address)").with_key(address(this)).checked_write(true);

        // stdstore.
        //     target(address(quizContract))
        //     .sig("winnersCount()")
        //     .checked_write(1);

        // // contract - slot - value
        // vm.store(address(quizContract), 10, bytes32(uint256(10)));

        vm.deal(address(quizContract), 10 ether);
        hoax(address(this));
        quizContract.withdrawReward();
    }

    receive() external payable {
        emit Log("receive", gasleft());
    }
}
