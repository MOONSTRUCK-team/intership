pragma solidity 0.8.23;

import "../src/Quiz.sol";
import "forge-std/Test.sol";

abstract contract QuizBaseTest is Test {
    address public OWNER = makeAddr("owner");
    uint256 public constant ENTRY_FEE = 1 ether;
    uint256 public REQUIRED_SCORE;
    uint256 public ANSWERING_END_TS;
    uint256 public REVEAL_PERIOD_END_TS;
    uint256 public QUIZ_END_TS;
    string[] public QUESTIONS_CIDS = ["Question 1"];
    bytes32[] public ANSWER_COMMITS = [keccak256("Answer 1")];
    uint256 public constant REWARD_POOL = 100 ether;
    uint8[] public CORRECT_ANSWERS;


    Quiz public quiz;

    function setUp() public {
        REQUIRED_SCORE = QUESTIONS_CIDS.length;
        ANSWERING_END_TS = uint48(block.timestamp) + 5 days;
        REVEAL_PERIOD_END_TS = ANSWERING_END_TS + 7 days;
        QUIZ_END_TS = REVEAL_PERIOD_END_TS + 3 days;

        vm.deal(OWNER, REWARD_POOL);
        quiz = new Quiz{value: REWARD_POOL}(
            OWNER, // Quiz owner
            ENTRY_FEE, // Entry fee
            REQUIRED_SCORE, // Required score
            ANSWERING_END_TS, // Answering end timestamp
            REVEAL_PERIOD_END_TS, // Reveal period timestamp
            QUIZ_END_TS, // Quiz end timestamp
            QUESTIONS_CIDS, // Questions
            ANSWER_COMMITS // Answer commits
        );
    }
}
