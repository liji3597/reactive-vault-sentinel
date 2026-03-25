// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/mocks/MockPriceFeed.sol";

contract MockPriceFeedTest is Test {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    MockPriceFeed internal feed;

    address internal owner = address(this);
    address internal nonOwner = address(0xBEEF);
    int256 internal constant INITIAL_ANSWER = 2000e8;
    uint8 internal constant DECIMALS = 8;

    function setUp() external {
        vm.warp(1_700_000_000);
        feed = new MockPriceFeed(owner, INITIAL_ANSWER, DECIMALS);
    }

    function test_ConstructorSetsInitialAnswer() external view {
        assertEq(uint256(feed.latestRoundId()), 1);
        assertEq(feed.latestAnswer(), INITIAL_ANSWER);

        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        assertEq(uint256(roundId), 1);
        assertEq(answer, INITIAL_ANSWER);
        assertEq(updatedAt, 1_700_000_000);
        assertEq(uint256(answeredInRound), 1);
    }

    function test_SetAnswerEmitsAnswerUpdated() external {
        int256 nextAnswer = 1900e8;
        vm.warp(1_700_000_123);

        vm.expectEmit(true, true, false, true, address(feed));
        emit AnswerUpdated(nextAnswer, 2, 1_700_000_123);

        feed.setAnswer(nextAnswer);
        assertEq(uint256(feed.latestRoundId()), 2);
    }

    function test_LatestRoundDataReturnsCurrentValues() external {
        vm.warp(1_700_000_321);
        feed.setAnswer(1800e8);

        vm.warp(1_700_000_456);
        feed.setAnswer(1700e8);

        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        assertEq(uint256(roundId), 3);
        assertEq(answer, 1700e8);
        assertEq(updatedAt, 1_700_000_456);
        assertEq(uint256(answeredInRound), 3);
    }

    function test_GetRoundDataReturnsPreviousRounds() external {
        vm.warp(1_700_000_111);
        feed.setAnswer(1950e8);

        vm.warp(1_700_000_222);
        feed.setAnswer(1800e8);

        (uint80 roundId1, int256 answer1,, uint256 updatedAt1, uint80 answeredInRound1) = feed.getRoundData(1);
        assertEq(uint256(roundId1), 1);
        assertEq(answer1, INITIAL_ANSWER);
        assertEq(updatedAt1, 1_700_000_000);
        assertEq(uint256(answeredInRound1), 1);

        (uint80 roundId2, int256 answer2,, uint256 updatedAt2, uint80 answeredInRound2) = feed.getRoundData(2);
        assertEq(uint256(roundId2), 2);
        assertEq(answer2, 1950e8);
        assertEq(updatedAt2, 1_700_000_111);
        assertEq(uint256(answeredInRound2), 2);
    }

    function test_SetAnswerOnlyOwner() external {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        feed.setAnswer(1500e8);
    }
}
