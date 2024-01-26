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

        vm.prank(OWNER);
        quiz.provideAnswerCommits(ANSWER_COMMITS);
    }

    function test_provideAnswerCommits_revertsWhen_answersProvidedBeforeAnsweringEndTs(address nonOwner) public {
        vm.assume(nonOwner != OWNER);

        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__QuizNotActive.selector));

        vm.warp(ANSWERING_END_TS + 1 seconds);
        quiz.provideAnswerCommits(ANSWER_COMMITS);
    }

    function test_provideAnswerCommits_revertsWhen_invalidEntryFee(address nonOwner) public {
        vm.assume(nonOwner != OWNER);
        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__InvalidEntryFee.selector));

        uint256 validTs = ANSWERING_END_TS - 1 seconds;
        uint256 invalidEntryFee = ENTRY_FEE - 1 wei;

        vm.warp(validTs);
        vm.deal(nonOwner, invalidEntryFee);
        vm.prank(nonOwner);
        quiz.provideAnswerCommits{value: invalidEntryFee}(ANSWER_COMMITS);
    }

    function test_provideAnswerCommits_revertsWhen_answerCommitsArrayLenNotEqWithQuestionsCidsLen(
        address nonOwner,
        bytes32 answerCommit
    ) public {
        vm.assume(nonOwner != OWNER);
        bytes32[] memory answerCommits = new bytes32[](2);
        answerCommits[0] = answerCommit;

        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__ArraysLengthMismatch.selector));

        uint256 validTs = ANSWERING_END_TS - 1 seconds;

        vm.warp(validTs);
        vm.deal(nonOwner, ENTRY_FEE);
        vm.prank(nonOwner);
        quiz.provideAnswerCommits{value: ENTRY_FEE}(answerCommits);
    }

    function test_provideAnswerCommits_setAnswerCommits_increasesNumOfPlayers(address nonOwner, bytes32 answerCommit)
        public
    {
        vm.assume(nonOwner != OWNER);

        bytes32[] memory answerCommits = new bytes32[](1);
        answerCommits[0] = answerCommit;
        uint256 validTs = ANSWERING_END_TS - 1 seconds;

        vm.warp(validTs);
        vm.deal(nonOwner, ENTRY_FEE);
        vm.prank(nonOwner);
        quiz.provideAnswerCommits{value: ENTRY_FEE}(answerCommits);

        assertEq(quiz.numberOfPlayers(), 1);

        bytes32[] memory userAnswerCommits = quiz.answerCommits(nonOwner);
        for (uint256 i; i < userAnswerCommits.length; ++i) {
            assertEq(userAnswerCommits[i], answerCommits[i]);
        }
    }

    //--------------------
    // `ownerRevealsAnswers` tests
    //---------------------

    function test_ownerRevealsAnwers_revertsWhen_invalidTimeForReveal(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.warp(REVEAL_PERIOD_END_TS + 7 days);
        vm.prank(OWNER);

        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__CannotRevealTheAnswersYet.selector));
        
        quiz.ownerRevealsAnswers(answers, userSalts);
    }

    function test_ownerRevealsAnwers_revertsWhen_invalidNumberOfAnswers(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {
        vm.prank(OWNER);
        vm.warp(REVEAL_PERIOD_END_TS - 2 days);
        vm.assume(answers.length != userSalts.length);
        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__ArraysLengthMismatch.selector));
       
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

    //--------------------
    // `revealUserAnswer` tests
    //---------------------

    function test_Revert_revealUserAnswer(uint8[] calldata answers, bytes32[] calldata userSalts) public {
        vm.assume(QUESTIONS_CIDS.length!=CORRECT_ANSWERS.length);
        vm.expectRevert(abi.encodeWithSelector(Quiz.Quiz__AnswersNotYetProvided.selector));
        quiz.revealUserAnswer(answers,userSalts);
    }


    //--------------------
    // `withdrawReward` tests
    //---------------------

    function test_RevertWhen_NotWinner() public {
        vm.expectRevert("You do not qualify for a reward");
        quiz.withdrawReward();
    }

    function test_RewardPayment() public {
        stdstore.target(address(quiz)).sig("winners(address)").with_key(address(this)).checked_write(true);

        stdstore.target(address(quiz)).sig("winnersCount()").checked_write(1);

        vm.deal(address(quiz), 10 ether);
        hoax(address(this));
        quiz.withdrawReward();
    }

    function testContractEthBalance() public view {
        // @audit fix this
        // console.log("ETH Balance", address(quiz).balance / 1e18);
    }

    //--------------------
    // `withdrawLeftoverEther` tests
    //---------------------

    function test_LeftoverEthWithdraw() public {
        vm.expectRevert("Winners still have time to withdraw rewards");
        vm.deal(address(quiz), 10 ether);

        hoax(address(this));
        quiz.withdrawLeftoverEther();
    }

    //--------------------
    // `rewardAmount` tests
    //---------------------

    //--------------------
    // `rewardPoolAmount` tests
    //---------------------
}
