pragma solidity 0.8.23;

import "./QuizBaseTest.t.sol";

contract QuizTest is QuizBaseTest {
    // TODO Test cases where constructor should revert
    function test_constructor_revertsWhen_requiredScoreBiggerThanQuestionsLength() public {
        vm.expectRevert();
        new Quiz(
            ENTRY_FEE, uint16(QUESTIONS.length + 1), END_TIMESTAMP, REVEAL_PERIOD_TIMESTAMP, QUESTIONS, ANSWER_COMMITS
        );
    }

    function test_constructor_setProperValues() public {
        assertEq(quiz.owner(), msg.sender);
        assertEq(quiz.entryFee(), ENTRY_FEE);
        assertEq(quiz.requiredScore(), REQUIRED_SCORE);
    }

    function testConstructorSetsOwner() public {
        assertEq(quiz.owner(), msg.sender);
    }

    function testConstructorSetsEntryFee() public {
        assertEq(quiz.entryFee(), ENTRY_FEE);
    }

    function testConstructorSetsRequiredScore() public {
        assertEq(quiz.requiredScore(), REQUIRED_SCORE);
    }

    function testConstructorSetsEndTimestamp() public {
        assertEq(quiz.endTs(), END_TIMESTAMP);
    }

    function testConstructorSetsRevealPeriodTimestamp() public {
        assertEq(quiz.revealPeriodTs(), block.timestamp + 7 days);
    }

    function testConstructorSetsQuestions() public {
        for (uint256 i = 0; i < QUESTIONS.length; i++) {
            assertEq(quiz.questions(i), QUESTIONS[i]);
        }
    }

    function testConstructorSetsAnswerCommits() public {
        for (uint256 i = 0; i < ANSWER_COMMITS.length; i++) {
            assertEq(quiz.quizAnswerCommits(i), ANSWER_COMMITS[i]);
        }
    }

    function testConstructorDepositsOwnerFunds() public {
        assertEq(quiz.ownerDeposit(), 100 ether);
    }
}
