pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
contract Quiz {
    /// @dev Maximum value that quiz answer can have
    uint256 public constant MAX_ANSWER_VALUE = 4;
    /// @dev CIDs to the questions on IPFS
    string[] public questions;
   /// @dev Hashes of the answers to the questions (commits)
    bytes32[] public quizAnswerCommits; 
    /// @dev Correct answers to the questions
    uint8[] public correctAnwers;
    /// @dev Mapping from user to commits of his answers
    mapping(address user => bytes32[] answerCommits) public userAnswerCommits;
    /// @dev Mapping from user to the flag if he is a winner
    mapping(address user => bool isWinner) public winners;
    //// @dev The score threshold that a user needs to reach to win the quiz
    uint16 public requiredScore;
    /// @dev End timestamp. Refer to the diagram shared in a Slack group
    uint48 public endTs;
    /// @dev Timestamp until users can reveal their answers. Refer to the diagram shared in a Slack group
    uint48 public revealPeriodTs;
    /// @dev Value of entry fee needed for user to participate in the quiz
    uint256 public entryFee;
    event QuestionAnswered(address player, bytes32 question, bytes32 answerHash);
    event AnswerRevealed(address player, bytes32 question, bytes32 answer, bytes32 salt);
    /// @param _entryFee Entry fee for the quiz participants
    /// @param _requiredScore Required score to win
    /// @param _endTs End timestamp
    /// @param _revealPeriodTs Timestamp until users can reveal their answers
    /// @param _questions CIDs to the questions on IPFS
    /// @param _answerCommits Hashes of the answers to the questions (commits)
    constructor(
        uint256 _entryFee,
        uint16 _requiredScore,
        uint48 _endTs,
        uint48 _revealPeriodTs,
        string[] memory _questions,
        bytes32[] memory _answerCommits
    ) payable Ownable(msg.sender) {
        require(_requiredScore <= _questions.length);
        require(_answerCommits.length == _questions.length);
        require(_endTs > block.timestamp + 2 days && _endTs < block.timestamp + 7 days);
        require(_revealPeriodTs > _endTs + 2 days && _revealPeriodTs < _endTs + 7 days);
        // TODO Dodati i ostale provere
        entryFee = _entryFee;
        requiredScore = _requiredScore;
        endTs = _endTs;
        revealPeriodTs = _revealPeriodTs;
        questions = _questions;
        quizAnswerCommits = _answerCommits;
    }


function answerQuestions(uint8[] calldata selectedAnswers, bytes32[] calldata userSalts) external payable {
    require(block.timestamp < endTs, "Quiz is not active");
    require(msg.value >= entryFee, "Incorrect entry fee");
    require(owner() != msg.sender, "Owner cannot participate");
    require(selectedAnswers.length == questions.length, "Invalid number of answers");
    require(selectedAnswers.length == userSalts.length, "Invalid number of salts");

    uint256 questionsLength = questions.length;
    for (uint256 i = 0; i < questionsLength; i++) {
        require(selectedAnswers[i] < MAX_ANSWER_VALUE, "Invalid answer index");
        bytes32 userAnswerCommit = keccak256(abi.encodePacked(selectedAnswers[i], userSalts[i], msg.sender));
        userAnswerCommits[msg.sender].push(userAnswerCommit);

        emit QuestionAnswered(msg.sender, questions[i], userAnswerCommit);
    }
}

function revealAnswer(uint8[] calldata selectedAnswers, bytes32[] calldata userSalts) external {
    require(block.timestamp >= revealPeriodTs, "Reveal period has not started");
    require(selectedAnswers.length == questions.length, "Invalid number of answers");
    require(selectedAnswers.length == userSalts.length, "Invalid number of salts");

    uint256 questionsLength = questions.length;
    for (uint256 i = 0; i < questionsLength; i++) {
        bytes32 commitment = keccak256(abi.encodePacked(selectedAnswers[i], userSalts[i], msg.sender));
        require(userAnswerCommits[msg.sender][i] == commitment, "Invalid commitment");
        bytes32 correctAnswerHash = keccak256(abi.encodePacked(correctAnwers[i],userSalts[i], msg.sender));

        emit AnswerRevealed(msg.sender, questions[i], correctAnwers[i], userSalts[i]);

        if (commitment == correctAnswerHash) {
            winners[msg.sender] = true;
            countOfWinners++;
            emit WinnerSet(msg.sender);
        }
    }
}


    /// Reward Pool
    event RewardPayed(address receiver, uint256 prize);
    function isWinner(address _userAddress) public view returns (bool, uint16) {
        uint256 winnersLen = winners.length;
        for (uint16 i = 0; i < winnersLen; i++) {
            if (winners[i] == _userAddress) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    function distributeRewards() internal view returns (uint256) {
        require(winners.length > 0, "This quiz has no winners");
        return (prizePool / winners.length);
    }
    function withdrawReward() external {
        (bool winnerStatus, uint16 index) = isWinner(msg.sender);
        require(winnerStatus, "You do not qualify for a reward");
        delete winners[index];
        uint256 reward = distributeRewards();
        payable(msg.sender).transfer(reward);
        emit RewardPayed(msg.sender, reward);
    }
    function withdrawLeftoverEther() external {}
}
