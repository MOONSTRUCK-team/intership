pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Quiz contract
 * @author Moonstruck interns
 */
contract Quiz is Ownable {
    /// @dev Maximum value that quiz answer can have
    uint256 public constant MAX_ANSWER_VALUE = 4;
    /// @dev The amount of times the reward pool must be bigger than entry fee
    uint256 public constant REWARD_POOL_MULTIPLIER = 10;
    /// @dev Slashing period duration (1 day)
    uint256 public constant SLASHING_PERIOD = 1 days;
    /// @dev Minimum period duration
    uint256 public constant MIN_PERIOD_DURATION = 2 days;
    /// @dev Maximum period duration
    uint256 public constant MAX_PERIOD_DURATION = 7 days;

    /// @dev Value of entry fee needed for user to participate in the quiz
    uint256 public immutable entryFee;
    //// @dev The score threshold that a user needs to reach to win the quiz
    uint256 public immutable requiredScore;
    /// @dev End timestamp. Refer to the diagram shared in a Slack group
    uint256 public immutable answeringEndTs;
    /// @dev Timestamp until users can reveal their answers. Refer to the diagram shared in a Slack group
    uint256 public immutable revealPeriodTs;
    /// @dev Timestamp after quiz for winners to withdraw their rewards
    uint256 public immutable quizEndTs;

    /// @dev Mapping from user to commits of his answers
    mapping(address user => bytes32[] answerCommits) public userAnswerCommits;
    /// @dev Mapping from user to the flag if he is a winner
    mapping(address user => bool isWinner) public winners;
    /// @dev CIDs to the questions on IPFS
    string[] public questionsCids;
    /// @dev Hashes of the answers to the questions (commits)
    bytes32[] public quizAnswerCommits;
    /// @dev Correct answers to the questions
    uint8[] public correctAnwers;
    /// @dev flag if owner was late with revealing answers)
    bool public isOwnerLate;
    /// @dev Number of quiz winners
    uint128 public winnersCount;
    /// @dev number of players who provided commit
    uint128 public numberOfPlayers;

    event UserProvidedCommits(address user, bytes32[] commits);
    event QuizAnswersRevealed(address owner, uint8[] answers, bool isLate);
    event UserAnswersRevealed(address user, uint8[] answers, bool isWinner);
    event QuizEndedPrematurely();
    event RewardPayed(address receiver, uint256 prize);
    event LeftoverEthWithdrawed(address receiver, uint256 etherReturned);

    error Quiz__QuizNotActive();
    error Quiz__InvalidEntryFee();
    error Quiz__OwnerCannotParticipate();
    error Quiz__ArraysLengthMismatch();
    error Quiz__InvalidCommit();
    error Quiz__AnswersRevealedOnTime();
    error Quiz__AnswersNotYetProvided();
    error Quiz__CannotRevealTheAnswersYet();
    error Quiz__CannotWithdrwaRewardYet();
    error Quiz__UserNotEligableForReward();
    error Quiz__QuizNotEnded();

    /// @param entryFee_ Entry fee for the quiz participants
    /// @param requiredScore_ Required score to win
    /// @param answeringEndTs_ Timestamp until users can provide their answers
    /// @param revealPeriodTs_ Timestamp until users can reveal their answers
    /// @param quizEndTs_ Timestamp which marks the end of the quiz. Users can claim their rewards until this timestamp
    /// @param questionCids_ CIDs to the questions on IPFS
    /// @param answerCommits_ Hashes of the answers to the questions (commits)
    constructor(
        uint256 entryFee_,
        uint256 requiredScore_,
        uint256 answeringEndTs_,
        uint256 revealPeriodTs_,
        uint256 quizEndTs_,
        string[] memory questionCids_,
        bytes32[] memory answerCommits_
    ) payable Ownable(msg.sender) {
        require(msg.value >= entryFee_ * REWARD_POOL_MULTIPLIER);
        require(requiredScore_ <= questionCids_.length);
        require(
            answeringEndTs_ >= block.timestamp + MIN_PERIOD_DURATION
                && answeringEndTs_ <= block.timestamp + MAX_PERIOD_DURATION
        );
        require(
            revealPeriodTs_ >= answeringEndTs_ + MIN_PERIOD_DURATION
                && revealPeriodTs_ <= answeringEndTs_ + MAX_PERIOD_DURATION
        );
        require(quizEndTs_ >= revealPeriodTs_ + MIN_PERIOD_DURATION);
        require(questionCids_.length == answerCommits_.length);

        entryFee = entryFee_;
        requiredScore = requiredScore_;
        answeringEndTs = answeringEndTs_;
        revealPeriodTs = revealPeriodTs_;
        questionsCids = questionCids_;
        quizAnswerCommits = answerCommits_;
        quizEndTs = quizEndTs_;
    }

    /// @dev User provides the commits for their answers to the quiz questions
    ///      This method is `payable`
    ///      Emits {UserProvidedCommits} event
    /// @param answerCommits Commits of the answers to the questions
    function provideAnswerCommits(bytes32[] calldata answerCommits) external payable {
        if (block.timestamp <= answeringEndTs) revert Quiz__QuizNotActive();
        if (msg.value != entryFee) revert Quiz__InvalidEntryFee();
        if (owner() == msg.sender) revert Quiz__OwnerCannotParticipate();
        if (answerCommits.length != questionsCids.length) revert Quiz__ArraysLengthMismatch();

        userAnswerCommits[msg.sender] = answerCommits;
        ++numberOfPlayers;

        emit UserProvidedCommits(msg.sender, answerCommits);
    }

    /// @dev Reveals the answers to the quiz questions
    ///      Callable only by the onwer
    ///      Emits {QuizAnswersRevealed} event
    /// @param answers Correct answers to the questions
    /// @param salts Salts used for creating the commits
    function ownerRevealsAnswers(uint8[] calldata answers, bytes32[] calldata salts) external onlyOwner {
        _checkIfValidReveal(quizAnswerCommits, answers, salts);

        // If owner provided the answers on time, he gets a refund of half of the reward pool
        // Otherwise, the reward pool is distributed to the winners as a whole
        bool lateResponse = block.timestamp <= answeringEndTs + SLASHING_PERIOD;
        if (!lateResponse) {
            payable(owner()).transfer(address(this).balance / 2);
        }

        isOwnerLate = lateResponse;
        correctAnwers = answers;

        emit QuizAnswersRevealed(msg.sender, answers, lateResponse);
    }

    /// @dev Marks the quiz as late in case the owner did not reveal the answers on time
    ///      This will allow anyone who provided the answer commits to withdraw their
    ///      entry fee + part of the reward pool
    function forceFinishQuiz() external {
        if (block.timestamp <= revealPeriodTs || correctAnwers.length != 0) revert Quiz__AnswersRevealedOnTime();

        // If owner did not reveal answers on time, everyone providing the answer commits is a winner and can withdraw the reward
        winnersCount = numberOfPlayers;
        isOwnerLate = true;

        emit QuizEndedPrematurely();
    }

    /// @dev User reveals the answers to the quiz questions
    ///      Emits {UserAnswersRevealed} event
    /// @param answers Answers to the questions
    /// @param salts Salts used for creating the commits
    function revealUserAnswer(uint8[] calldata answers, bytes32[] calldata salts) external {
        if (correctAnwers.length != questionsCids.length) revert Quiz__AnswersNotYetProvided();
        _checkIfValidReveal(userAnswerCommits[msg.sender], answers, salts);

        uint256 score;
        for (uint256 i; i < answers.length; ++i) {
            if (answers[i] == correctAnwers[i]) {
                ++score;
            }
        }

        bool isWinner = score >= requiredScore;
        if (isWinner) {
            ++winnersCount;
            winners[msg.sender] = isWinner;
        }

        emit UserAnswersRevealed(msg.sender, answers, isWinner);
    }

    /// @dev User withdraws the reward if eligable
    ///      Emits {RewardPayed} event
    function withdrawReward() external {
        if (block.timestamp < revealPeriodTs || block.timestamp > quizEndTs) revert Quiz__CannotWithdrwaRewardYet();
        // If owner revealed answers late and user did not provide any answers
        // he is not eligible for a reward, revert in that case
        if (isOwnerLate) {
            if (userAnswerCommits[msg.sender].length == 0) revert Quiz__UserNotEligableForReward();
            // Else, check if user is a winner, as owner revealed answers on time.
            // Revert if not a winner
        } else {
            if (!winners[msg.sender]) revert Quiz__UserNotEligableForReward();
        }

        --winnersCount;
        winners[msg.sender] = false;
        uint256 reward = rewardAmount();
        payable(msg.sender).transfer(reward);

        emit RewardPayed(msg.sender, reward);
    }

    /// @dev Owner withdraws leftover ether
    ///      Emits {LeftoverEthWithdrawed} event
    function withdrawLeftoverEther() external onlyOwner {
        if (block.timestamp < quizEndTs) revert Quiz__QuizNotEnded();

        uint256 leftover = address(this).balance;
        payable(msg.sender).transfer(leftover);

        emit LeftoverEthWithdrawed(msg.sender, leftover);
    }

    /// @dev Checks if the reveal is valid
    /// @param commits Commits of the answers to the questions
    /// @param answers Answers to the questions
    /// @param salts Salts used for creating the commits
    function _checkIfValidReveal(bytes32[] memory commits, uint8[] calldata answers, bytes32[] calldata salts)
        private
        view
    {
        if (block.timestamp < answeringEndTs || block.timestamp > revealPeriodTs) {
            revert Quiz__CannotRevealTheAnswersYet();
        }
        if (answers.length != questionsCids.length) revert Quiz__ArraysLengthMismatch();
        if (answers.length != salts.length) revert Quiz__ArraysLengthMismatch();

        uint256 questionsCidsLength_ = questionsCids.length;
        for (uint256 i; i < questionsCidsLength_; ++i) {
            bytes32 calculatedCommit = keccak256(abi.encodePacked(answers[i], salts[i], msg.sender));
            if (commits[i] != calculatedCommit) revert Quiz__InvalidCommit();
        }
    }

    /// @dev Returns the length of the `questionsCids` array
    /// @return Length of the `questionsCids` array
    function questionsCidsLength() external view returns (uint256) {
        return questionsCids.length;
    }

    /// @dev Returns the length of the `quizAnswerCommits` array
    /// @return Length of the `quizAnswerCommits` array
    function quizAnswerCommitsLength() external view returns (uint256) {
        return quizAnswerCommits.length;
    }

    /// @dev Returns the amount of reward that each winner gets
    /// @return Amount of reward that each winner gets
    function rewardAmount() internal view returns (uint256) {
        return rewardPoolAmount() / winnersCount;
    }

    /// @dev Returns the amount of reward pool
    /// @return amount Amount of reward pool
    function rewardPoolAmount() public view returns (uint256 amount) {
        if (isOwnerLate) amount = address(this).balance;
        else amount = address(this).balance / 2;
    }
}
