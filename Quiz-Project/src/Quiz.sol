pragma solidity 0.8.23;

contract Quiz {





    /// Reward Pool

    function isWinner(address _userAddress) public view returns (bool, uint16) {
        uint16 winnersLen = winners.length;
        for (uint16 i = 0; i < winnersLen; i++) {
            if (winners[i] == _userAddress) {
                return (true, i);
            }
        }
            return (false, 0);
    }


    function distributeRewards(uint16 _totalReward) internal view returns (uint16) {
        require(winners.length > 0, "This quiz has no winners");
        reutrn (totalReward / winners.length);
    }


    function withdrawReward(uint16 _prizePool) external payable {
        (bool winnerStatus, uint16 index) = isWinner(msg.sender);
        require(winnerStatus, "You do not qualify for a reward");

        delete winners[index];

        uint16 reward = distributeRewards(_prizePool);

        payable(msg.sender).transfer(reward);
    }
}