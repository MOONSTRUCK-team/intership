pragma solidity 0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Quiz {

    ///Data structures

    struct Player {
        mapping (bytes32 => uint) commitedAnswers;
        uint256 score = 0;
    }

    bytes32[] public questions;

    mapping(address => Player) public players;
    mapping(address => bool) public winners;
    
    
    bool quizActive;

    uint256 entryFee;

    constructor(bytes32[] memory _questions, uint256 _entryFee, uint16 _prizePool) Ownable(msg.sender) {
        questions = _questions;
        entryFee = _entryFee;
        quizActive = true;
        prizePool = _prizePool;
    }
    //answer questions and reveal them
    event QuestionAnswered(address player, bytes32 question, bytes32 answerHash);
    event AnswerRevealed(address player, bytes32 question, bytes32 answer, bytes32 salt);


    function answerQuestion(bytes32 question, bytes32 answerHash) external payable {
        require(quizActive, "Quiz is not active");
        require(msg.value == entryFee, "Incorrect entry fee");
        require(owner() != msg.sender, "Owner cannot participate");
        players[msg.sender].committedAnswers[question] = answerHash;

        emit QuestionAnswered(msg.sender, question, answerHash);
    }

    function revealAnswer(bytes32 question, bytes32 answer, bytes32 salt) external {
        require(!quizActive, "Quiz is still active");

        bytes32 commitment = keccak256(abi.encodePacked(answer, salt));
        require(players[msg.sender].committedAnswers[question] == commitment, "Invalid commitment");
        bytes32 correctAnswerHash = keccak256(abi.encodePacked("CorrectAnswer", salt));//radi primera
        if (commitment == correctAnswerHash) {
            players[msg.sender].score += 1;
        }

        emit AnswerRevealed(msg.sender, question, answer, salt);

    require(!isWinner(players[msg.sender]));
        if (players[msg.sender].score >= requiredScore) {
            winners.push(msg.sender);
            emit WinnerSet(msg.sender);
        }
    }

    event WinnerSet(address winner);

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