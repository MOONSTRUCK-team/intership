pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Quiz is Ownable {
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
    uint256 public endTs;
    /// @dev Timestamp until users can reveal their answers. Refer to the diagram shared in a Slack group
    uint256 public revealPeriodTs;
    /// @dev Value of entry fee needed for user to participate in the quiz
    uint256 public entryFee;
    /// @dev Timestamp after quiz for winners to withdraw their rewards
    uint256 quizEndTs;
    /// @dev Number of quiz winners
    uint256 winnersCount;
    ///@dev Deposit made by the owner for the slashing mechanism
    uint256 public ownerDeposit;
    /// @dev Slashing period duration (1 day)
    uint256 public constant SLASHING_PERIOD = 1 days;
    /// @dev number of players who provided commit
    uint256 public numberOfPlayers;
    /// @dev flag if owner was late with revealing answers)
    bool public isOwnerLate;

    /// @param _entryFee Entry fee for the quiz participants
    /// @param _requiredScore Required score to win
    /// @param _endTs End timestamp
    /// @param _revealPeriodTs Timestamp until users can reveal their answers
    /// @param _questions CIDs to the questions on IPFS
    /// @param _answerCommits Hashes of the answers to the questions (commits)
    constructor(
        uint256 _entryFee,
        uint16 _requiredScore,
        uint256 _endTs,
        uint256 _revealPeriodTs,
        string[] memory _questions,
        bytes32[] memory _answerCommits
    ) payable Ownable(msg.sender) {
        require(_requiredScore <= _questions.length);
        require(_answerCommits.length == _questions.length);
        require(_endTs >= block.timestamp + 2 days && _endTs <= block.timestamp + 7 days);
        require(_revealPeriodTs >= _endTs + 2 days && _revealPeriodTs <= _endTs + 7 days);
        require(msg.value >= _entryFee * 100, "Insufficient deposit");

        entryFee = _entryFee;
        requiredScore = _requiredScore;
        endTs = _endTs;
        revealPeriodTs = _revealPeriodTs;
        questions = _questions;
        quizAnswerCommits = _answerCommits;
    }

    event UserProvidedCommits(address user, bytes32[] commits);

    /**
     * 1. User creates a commit for each answer off-chain
     *    - keccak256(abi.encodePacked(selectedAnswers[i], userSalts[i], msg.sender))
     *    - If its created on-chain, anyone can see the answers
     */
    /// @dev User provides the commits for their answers to the qiuz questions
    ///      This method is `payable`
    ///      Emits {UserProvidedCommits} event
    /// @param answerCommits Hashes of the answers to the questions (commits)
    function provideAnswerCommits(bytes32[] calldata answerCommits) external payable {
        require(block.timestamp < endTs, "Quiz is not active");
        require(msg.value == entryFee, "Incorrect entry fee");
        require(owner() != msg.sender, "Owner cannot participate");
        require(answerCommits.length == questions.length, "Invalid number of answers");

        userAnswerCommits[msg.sender] = answerCommits;
        numberOfPlayers++;

        emit UserProvidedCommits(msg.sender, answerCommits);
    }

    event OwnerRevealedAnswers(address owner, uint8[] answers, bool isLate);

    /// @dev Reveals the answers to the quiz questions
    ///      Callable only by the onwer
    ///      Emits {OwnerRevealedAnswers} event
    /// @param answers Correct answers to the questions
    /// @param userSalts Salts used for creating the commits
    function ownerRevealsAnswers(uint8[] calldata answers, bytes32[] calldata userSalts) external onlyOwner {
        require(block.timestamp > endTs, "Quiz is still active");
        _checkIfValidReveal(quizAnswerCommits, answers, userSalts);

        bool isOwnerLate_;
        if (block.timestamp <= endTs + SLASHING_PERIOD) isOwnerLate_ = true;

        // If owner provided the answers on time, he gets a refund of the deposit
        // Equal to the reward pool
        if (!isOwnerLate_) {
            payable(owner()).transfer(address(this).balance / 2);
        }

        correctAnwers = answers;
        isOwnerLate = isOwnerLate_;

        emit OwnerRevealedAnswers(msg.sender, answers, isOwnerLate_);
    }

    event QuizEndedPrematurely();

    /// @dev Marks the quiz as late in case the owner did not reveal the answers on time
    ///      This will allow anyone who provided the answer commits to withdraw their
    ///      entry fee + part of the reward pool
    function finishWithQuiz() external {
        require(block.timestamp > revealPeriodTs && correctAnwers.length == 0, "Quiz creator revealed answers on time");

        isOwnerLate = true;
        // If owner did not reveal answers on time, everyone providing the answer commits is a winner
        winnersCount = numberOfPlayers;

        emit QuizEndedPrematurely();
    }

    event UserRevealedAnswers(address user, uint8[] answers, bool isWinner);

    /// @dev User reveals the answers to the quiz questions
    ///      Emits {UserRevealedAnswers} event
    /// @param answers Answers to the questions
    /// @param userSalts Salts used for creating the commits
    function revealUserAnswer(uint8[] calldata answers, bytes32[] calldata userSalts) external {
        require(correctAnwers.length == questions.length, "Quiz answers are not revealed yet");
        _checkIfValidReveal(userAnswerCommits[msg.sender], answers, userSalts);

        uint256 score;
        for (uint256 i; i < answers.length; i++) {
            if (answers[i] == correctAnwers[i]) {
                score++;
            }
        }

        bool isWinner;
        if (score >= requiredScore) {
            isWinner = true;
            winners[msg.sender] = isWinner;
        }

        emit UserRevealedAnswers(msg.sender, answers, isWinner);
    }

    /// Reward Pool

    event RewardPayed(address receiver, uint256 prize);
    event LeftoverEthWithdrawed(address receiver, uint256 etherReturned);

    function distributeRewards() internal view returns (uint256) {
        return rewardPool() / winnersCount;
    }

    function rewardPool() public view returns (uint256 rewardPool_) {
        if (isOwnerLate) rewardPool_ = address(this).balance;
        else rewardPool_ = address(this).balance / 2;
    }

    function withdrawReward() external {
        require(block.timestamp > quizEndTs, "Period to withdraw reward ended");
        // If owner revealed answers late and user did not provide any answers
        // he is not eligible for a reward, revert in that case
        if (isOwnerLate && userAnswerCommits[msg.sender].length == 0) {
            require(block.timestamp > revealPeriodTs, "Period to withdraw reward ended");
            // Else, check if user is a winner, as owner revealed answers on time.
            // Revert if not a winner
        } else {
            require(winners[msg.sender], "You do not qualify for a reward");
        }

        winners[msg.sender] = false;
        --winnersCount;
        uint256 reward = distributeRewards();
        payable(msg.sender).transfer(reward);

        emit RewardPayed(msg.sender, reward);
    }

    function withdrawLeftoverEther() external onlyOwner {
        require(block.timestamp < quizEndTs, "Winners still have time to withdraw rewards");

        uint256 leftoverBal = address(this).balance;
        payable(msg.sender).transfer(leftoverBal);

        emit LeftoverEthWithdrawed(msg.sender, leftoverBal);
    }

    function _checkIfValidReveal(bytes32[] memory commits, uint8[] calldata answers, bytes32[] calldata userSalts)
        private
        view
    {
        require(block.timestamp > endTs && block.timestamp < revealPeriodTs, "Invalid time for revaling answers");
        require(answers.length == questions.length, "Invalid number of answers");
        require(answers.length == userSalts.length, "Invalid number of salts");

        uint256 questionsLength = questions.length;
        for (uint256 i; i < questionsLength; i++) {
            bytes32 commitment = keccak256(abi.encodePacked(answers[i], userSalts[i], msg.sender));
            require(commits[i] == commitment, "Invalid commitment");
        }
    }
}
