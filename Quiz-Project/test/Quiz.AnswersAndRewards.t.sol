pragma solidity 0.8.23;

import "../src/Quiz.sol";
import {QuizBaseTest} from "./QuizBaseTest.t.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

contract QuizAnswersRewardsTest is QuizBaseTest {
    using stdStorage for StdStorage;

    //--------------------
    // `provideAnswerCommits` tests
    //---------------------

    function test_provideAnswerCommits_revertsWhen_senderOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Quiz.OwnerCannotParticipate.selector));

        vm.prank(OWNER);
        quiz.provideAnswerCommits(ANSWER_COMMITS);
    }

    function test_provideAnswerCommits_revertsWhen_answersProvidedBeforeAnsweringEndTs(address nonOwner) public {
        vm.assume(nonOwner != OWNER);

        vm.expectRevert(abi.encodeWithSelector(Quiz.QuizNotActive.selector));

        vm.warp(ANSWERING_END_TS + 1 seconds);
        quiz.provideAnswerCommits(ANSWER_COMMITS);
    }

    function test_provideAnswerCommits_revertsWhen_invalidEntryFee(address nonOwner) public {
        vm.assume(nonOwner != OWNER);
        vm.expectRevert(abi.encodeWithSelector(Quiz.InvalidEntryFee.selector));

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

        vm.expectRevert(abi.encodeWithSelector(Quiz.ArraysLengthMismatch.selector));

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

        vm.expectEmit(address(quiz));
        emit Quiz.UserProvidedCommits(nonOwner, answerCommits);

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
        vm.warp(ANSWERING_END_TS - 1);

        vm.expectRevert(abi.encodeWithSelector(Quiz.CannotRevealTheAnswersYet.selector));

        vm.prank(OWNER);
        quiz.ownerRevealsAnswers(answers, userSalts);
    }

    function test_ownerRevealsAnwers_revertsWhen_invalidNumberOfAnswers(uint8[] calldata answers) public {
        bytes32[] memory salts = new bytes32[](answers.length + 1);

        vm.warp(REVEAL_PERIOD_END_TS - 1);
        vm.expectRevert(abi.encodeWithSelector(Quiz.ArraysLengthMismatch.selector));

        vm.prank(OWNER);
        quiz.ownerRevealsAnswers(answers, salts);
    }

    function test_ownerRevealsAnswers_answersRevealedOnTime() public {
        vm.warp(REVEAL_PERIOD_END_TS - quiz.SLASHING_PERIOD() - 1);

        vm.expectEmit(address(quiz));
        emit Quiz.QuizAnswersRevealed(OWNER, CORRECT_ANSWERS, false);

        vm.prank(OWNER);
        quiz.ownerRevealsAnswers(CORRECT_ANSWERS, SALTS);
    }

    function test_ownerRevealsAnswers_answersRevealedLate() public {
        vm.warp(REVEAL_PERIOD_END_TS + quiz.SLASHING_PERIOD() + 1);

        vm.expectEmit(address(quiz));
        emit Quiz.QuizAnswersRevealed(OWNER, CORRECT_ANSWERS, true);

        vm.prank(OWNER);
        quiz.ownerRevealsAnswers(CORRECT_ANSWERS, SALTS);
    }

    //--------------------
    // `forceFinishQuiz` tests
    //---------------------

    function test_forceFinishQuiz_revertsWhen_invalidTime(uint8 x) public {
        vm.assume(x > 0);

        vm.expectRevert(abi.encodeWithSelector(Quiz.CannotForceFinishQuiz.selector));
        vm.warp(REVEAL_PERIOD_END_TS - x);
        quiz.forceFinishQuiz();
    }

    function test_forceFinishQuiz_revertsWhen_noAnswersProvided(uint256 x) public {
        vm.assume(x >= 0 && x < REVEAL_PERIOD_END_TS);

        vm.expectRevert(abi.encodeWithSelector(Quiz.CannotForceFinishQuiz.selector));
        vm.warp(REVEAL_PERIOD_END_TS - x);
        quiz.forceFinishQuiz();
    }

    function test_forceFinishQuiz_quizEndedPrematurely(uint8 x) public {
        vm.assume(x > 0);
        vm.warp(REVEAL_PERIOD_END_TS + x);

        vm.expectEmit(address(quiz));
        emit Quiz.QuizEndedPrematurely();

        quiz.forceFinishQuiz();
    }

    //--------------------
    // `revealUserAnswer` tests
    //---------------------

    function test_revealUserAnswer_revertsWhen_invalidTimeForReveal(
        uint8[] calldata answers,
        bytes32[] calldata userSalts
    ) public {}

    function test_revealUserAnswer_revertsWhen_arraysLengthMismatch(uint8[] calldata answers) public {
        bytes32[] memory salts = new bytes32[](answers.length + 1);

        vm.warp(REVEAL_PERIOD_END_TS - 1);

        vm.expectRevert(abi.encodeWithSelector(Quiz.ArraysLengthMismatch.selector));
        quiz.revealUserAnswer(answers, salts);
    }

    function test_revealUserAnswers_userRevealedAnswers() public {}

    //--------------------
    // `withdrawReward` tests
    //---------------------

    function test_withdrawReward_revertsWhen_rewardNotWithdrawableYet() public {
        // vm.expectRevert("You do not qualify for a reward");
        // quiz.withdrawReward();
    }

    function test_withdrawReward_revertsWhen_lateAnswerReveal_userNotParticipated() public {
        // stdstore.target(address(quiz)).sig("winners(address)").with_key(address(this)).checked_write(true);

        // stdstore.target(address(quiz)).sig("winnersCount()").checked_write(1);

        // vm.deal(address(quiz), 10 ether);
        // hoax(address(this));
        // quiz.withdrawReward();
    }

    function test_withdrawReward_revertsWhen_answerRevealOnTime_userNotParticipated() public {}

    function test_withdraw_userReceivedProperReward() public {}

    //--------------------
    // `withdrawLeftoverEther` tests
    //---------------------

    function test_withdrawLeftoverEther_revertsWhen_quizNotEnded() public {
        // vm.expectRevert("Quiz is still active");
        // quiz.withdrawLeftoverEther();
    }

    function test_withdrawLeftoverEther_leftoverEthWithdrawn() public {
        // vm.expectRevert("Winners still have time to withdraw rewards");
        // vm.deal(address(quiz), 10 ether);

        // vm.expectEmit(address(quiz));
        // emit Quiz.LeftoverEthWithdrawed(address(this), 100 ether);

        // hoax(address(this));
        // quiz.withdrawLeftoverEther();
    }

    //--------------------
    // `rewardAmount` tests
    //---------------------

    //--------------------
    // `rewardPoolAmount` tests
    //---------------------
}
