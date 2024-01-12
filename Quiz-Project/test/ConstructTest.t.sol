pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/Quiz.sol";

contract QuizTest is Test {
    Quiz quiz;

    function setUp() public {
        // Replace with your actual planned values for deployment
        quiz = new Quiz(
            1 ether,  // Entry fee
            5,        // Required score
            block.timestamp + 5 days,  // End timestamp
            block.timestamp + 7 days,  // Reveal period timestamp
            ["Question 1", "Question 2"],  // Questions
            [keccak256("Answer 1"), keccak256("Answer 2")]  // Answer commits
        );
    }

    function testConstructorSetsOwner() public {
        assertEq(quiz.owner(), msg.sender);
    }

    function testConstructorSetsEntryFee() public {
        assertEq(quiz.entryFee(), 100 wei);
    }

    function testConstructorSetsRequiredScore() public {
        assertEq(quiz.requiredScore(), 5);
    }

    function testConstructorSetsEndTimestamp() public {
        assertEq(quiz.endTs(), block.timestamp + 5 days);
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