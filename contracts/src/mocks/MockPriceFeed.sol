// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockPriceFeed is Ownable2Step {
    struct RoundData {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    uint8 public immutable decimals;
    string public description;
    uint256 public constant version = 1;

    uint80 public latestRoundId;
    mapping(uint80 => RoundData) private rounds;

    error InvalidAnswer();
    error RoundNotFound(uint80 roundId);

    constructor(address initialOwner, int256 initialAnswer, uint8 feedDecimals) Ownable(initialOwner) {
        if (initialAnswer <= 0) {
            revert InvalidAnswer();
        }
        decimals = feedDecimals;
        description = "Reactive Vault Sentinel Mock Feed";
        _setAnswer(initialAnswer);
    }

    function setAnswer(int256 _answer) external onlyOwner {
        if (_answer <= 0) {
            revert InvalidAnswer();
        }
        _setAnswer(_answer);
    }

    function latestAnswer() external view returns (int256) {
        return rounds[latestRoundId].answer;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData memory data = rounds[latestRoundId];
        return (latestRoundId, data.answer, data.startedAt, data.updatedAt, data.answeredInRound);
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData memory data = rounds[_roundId];
        if (data.updatedAt == 0) {
            revert RoundNotFound(_roundId);
        }
        return (_roundId, data.answer, data.startedAt, data.updatedAt, data.answeredInRound);
    }

    function _setAnswer(int256 _answer) internal {
        unchecked {
            latestRoundId += 1;
        }
        uint80 currentRoundId = latestRoundId;
        rounds[currentRoundId] = RoundData({
            answer: _answer,
            startedAt: block.timestamp,
            updatedAt: block.timestamp,
            answeredInRound: currentRoundId
        });
        emit AnswerUpdated(_answer, currentRoundId, block.timestamp);
    }
}
