pragma solidity 0.8.23;

import "../src/Quiz.sol";
import {QuizBaseTest} from "./QuizBaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

/**
 * TODO
 * - [ ] Update all the tests
 */

contract QuizAnswersRewardsTest is QuizBaseTest {
    using stdStorage for StdStorage;

    //--------------------
    // `provideAnswerCommits` tests
    //---------------------

    function test_provideAnswerCommits_revertsWhen_senderOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__OwnerCannotParticipate.selector));

        quiz.provideAnswerCommits(ANSWER_COMMITS);
    }

    //--------------------
    // `ownerRevealsAnswers` tests
    //---------------------

    function test_ownerRevealsAnwers_revertsWhen_invalidTimeForReveal(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.warp(REVEAL_PERIOD_END_TS + 7 days);

        vm.expectRevert("Invalid time for revaling answers");
        quiz.ownerRevealsAnswers(answers, userSalts);
    }

    function test_ownerRevealsAnwers_revertsWhen_invalidNumberOfAnswers(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.warp(REVEAL_PERIOD_END_TS + 1 days);
        vm.assume(answers.length != userSalts.length);

        vm.expectRevert("Invalid number of answers");
        quiz.ownerRevealsAnswers(answers, userSalts);
    }

    //--------------------
    // `forceFinishQuiz` tests
    //---------------------

    function test_forceFinishQuiz_Prematurely(uint8 x) public {
        vm.assume(x > 0);
        vm.warp(REVEAL_PERIOD_END_TS + x);
        quiz.forceFinishQuiz();
    }

    function test_Revert_revealUserAnswer(uint8[] calldata answers, bytes32[] calldata userSalts) public {
        vm.expectRevert("Quiz answers are not revealed yet");
        quiz.revealUserAnswer(answers, userSalts);
    }

    function test_RevertWhen_NotWinner() public {
        vm.expectRevert("You do not qualify for a reward");
        quiz.withdrawReward();
    }

    function testContractEthBalance() public view {
        // @audit fix this
        // console.log("ETH Balance", address(quiz).balance / 1e18);
    }

    function test_LeftoverEthWithdraw() public {
        vm.expectRevert("Winners still have time to withdraw rewards");
        vm.deal(address(quiz), 10 ether);

        hoax(address(this));
        quiz.withdrawLeftoverEther();
    }

    function test_RewardPayment() public {
        stdstore.target(address(quiz)).sig("winners(address)").with_key(address(this)).checked_write(true);

        stdstore.target(address(quiz)).sig("winnersCount()").checked_write(1);

        vm.deal(address(quiz), 10 ether);
        hoax(address(this));
        quiz.withdrawReward();
    }
}