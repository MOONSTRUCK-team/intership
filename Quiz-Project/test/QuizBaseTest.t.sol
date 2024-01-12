pragma solidity 0.8.22;

import "../src/Quiz.sol";
import "forge-std/Test.sol";

abstract contract QuizBaseTest is Test {
    uint256 public constant ENTRY_FEE = 1 ether;
    uint256 public constant REQUIRED_SCORE = 5;
    uint256 public immutable END_TIMESTAMP;
    uint256 public immutable REVEAL_PERIOD_TIMESTAMP;
    string[] public constant QUESTIONS = ["Question 1", "Question 2"];
    bytes32[] public constant ANSWER_COMMITS = [keccak256("Answer 1"), keccak256("Answer 2")];

    Quiz quiz;

    function setUp() public {
        END_TIMESTAMP = block.timestamp + 5 days;
        REVEAL_PERIOD_TIMESTAMP = block.timestamp + 7 days;

        quiz = new Quiz(
            ENTRY_FEE, // Entry fee
            REQUIRED_SCORE, // Required score
            END_TIMESTAMP, // End timestamp
            REVEAL_PERIOD_TIMESTAMP, // Reveal period timestamp
            QUESTIONS, // Questions
            ANSWER_COMMITS // Answer commits
        );
    }
}