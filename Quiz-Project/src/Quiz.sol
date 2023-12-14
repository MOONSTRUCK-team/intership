pragma solidity 0.8.23;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol"
contract Quiz {

    /// Data structures

    struct Player {
        mapping (bytes32 => uint) commitedAnswers;
        uint256 score = 0;
    }

    bytes32[] public questions;

    mapping(address => Player) public players;
    mapping(address => bool) public winners;
    
    
    bool quizActive;

    uint256 entryFee;

    constructor(bytes32[] memory _questions, uint256 _entryFee) Ownable(msg.sender) {
        questions = _questions;
        entryFee = _entryFee;
        quizActive = true;
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
}