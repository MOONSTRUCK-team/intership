pragma solidity ^0.8.23;

import "./QuizBaseTest.t.sol";

contract QuizTest is QuizBaseTest {
    // TODO Test cases where constructor should revert
    function test_constructor_revertsWhen_requiredScoreBiggerThanQuestionsLength() public {
        vm.expectRevert();
        new Quiz(ENTRY_FEE, QUESTIONS.length + 1, END_TIMESTAMP, REVEAL_PERIOD_TIMESTAMP, QUESTIONS, ANSWER_COMMITS);
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
        assertEq(quiz.questions(), ["Question 1", "Question 2"]);
    }

    function testConstructorSetsAnswerCommits() public {
        assertEq(quiz.quizAnswerCommits(), [keccak256("Answer 1"), keccak256("Answer 2")]);
    }

    function testConstructorDepositsOwnerFunds() public {
        assertEq(quiz.ownerDeposit(), 100 ether);
    }
}
