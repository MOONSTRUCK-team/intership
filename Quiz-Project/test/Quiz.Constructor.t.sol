pragma solidity 0.8.23;

import "./QuizBaseTest.t.sol";

contract QuizConstructorTest is QuizBaseTest {
    /**
     * TODO
     * - [ ] Test all the revert cases
     */
    function test_constructor_revertsWhen_requiredScoreBiggerThanQuestionsLength() public {
        vm.expectRevert();

        new Quiz(
            address(this),            
            ENTRY_FEE,
            uint16(QUESTIONS_CIDS.length + 1),
            ANSWERING_END_TS,
            REVEAL_PERIOD_END_TS,
            QUIZ_END_TS,
            QUESTIONS_CIDS,
            ANSWER_COMMITS
        );
    }

    function test_constructor_properValuesSet() public {
        assertEq(quiz.owner(), address(this));
        assertEq(address(quiz).balance, REWARD_POOL);
        assertEq(quiz.entryFee(), ENTRY_FEE);
        assertEq(quiz.requiredScore(), REQUIRED_SCORE);
        assertEq(quiz.answeringEndTs(), ANSWERING_END_TS);
        assertEq(quiz.revealPeriodTs(), REVEAL_PERIOD_END_TS);
        assertEq(quiz.quizEndTs(), QUIZ_END_TS);

        assertEq(quiz.questionsCidsLength(), QUESTIONS_CIDS.length);
        for (uint256 i; i < QUESTIONS_CIDS.length; ++i) {
            assertEq(quiz.questionsCids(i), QUESTIONS_CIDS[i]);
        }

        assertEq(quiz.quizAnswerCommitsLength(), ANSWER_COMMITS.length);
        for (uint256 i; i < ANSWER_COMMITS.length; ++i) {
            assertEq(quiz.quizAnswerCommits(i), ANSWER_COMMITS[i]);
        }
    }
}
