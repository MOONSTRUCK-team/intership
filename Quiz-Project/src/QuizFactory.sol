// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Quiz} from "./Quiz.sol";

/**
 * @title QuizFactory
 * @author Moonstruck interns
 * @dev Factory contract for creating quizzes
 */
contract QuizFactory {
    /// @dev The number of quizzes created
    uint256 public count;

    /// @dev Mapping from quiz id to quiz contract address
    mapping (uint256 id => address quiz) public quizzes;

    /// @dev Emitted when a new quiz is created
    /// @param id The id of the quiz
    /// @param quiz The address of the quiz
    event QuizCreated(uint256 id, address quiz);


    /// @dev Creates a new quiz
    ///      This function is payable
    ///      Emits a {QuizCreated} event
    /// @param entryFee The entry fee for the quiz
    /// @param requiredScore The required score for the quiz
    /// @param answeringEndTs The timestamp when the answering period ends
    /// @param revealPeriodEndTs The timestamp when the reveal period ends
    /// @param quizEndTs The timestamp when the quiz ends
    /// @param questionsCids The questions cids
    /// @param answerCommits The answer commits
    function createQuiz(
        uint256 entryFee,
        uint256 requiredScore,
        uint256 answeringEndTs,
        uint256 revealPeriodEndTs,
        uint256 quizEndTs,
        string[] calldata questionsCids,
        bytes32[] calldata answerCommits
    ) external payable {
        address quiz = address(new Quiz(
            msg.sender,
            entryFee,
            requiredScore,
            answeringEndTs,
            revealPeriodEndTs,
            quizEndTs,
            questionsCids,
            answerCommits
        ));
        uint256 id = ++count;
        quizzes[id] = quiz;

        emit QuizCreated(id, quiz);
    }
}