// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/monitors/BalanceMonitor.sol";

contract TestERC20 is ERC20 {
    constructor() ERC20("Test ERC20", "TST") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BalanceMonitorTest is Test {
    event BalanceChanged(address indexed account, address indexed token, uint256 oldBalance, uint256 newBalance);

    BalanceMonitor internal monitor;
    TestERC20 internal token;

    address internal owner = address(this);
    address internal account = address(0xABCD);

    function setUp() external {
        monitor = new BalanceMonitor(owner);
        token = new TestERC20();
    }

    function test_CheckpointDetectsEthBalanceChange() external {
        vm.deal(account, 1 ether);

        vm.expectEmit(true, true, false, true, address(monitor));
        emit BalanceChanged(account, address(0), 0, 1 ether);
        monitor.checkpoint(account, address(0));
        assertEq(monitor.lastKnownBalance(account, address(0)), 1 ether);

        vm.deal(account, 2 ether);
        vm.expectEmit(true, true, false, true, address(monitor));
        emit BalanceChanged(account, address(0), 1 ether, 2 ether);
        monitor.checkpoint(account, address(0));
        assertEq(monitor.lastKnownBalance(account, address(0)), 2 ether);
    }

    function test_CheckpointDetectsErc20BalanceChange() external {
        token.mint(account, 500e18);

        vm.expectEmit(true, true, false, true, address(monitor));
        emit BalanceChanged(account, address(token), 0, 500e18);
        monitor.checkpoint(account, address(token));
        assertEq(monitor.lastKnownBalance(account, address(token)), 500e18);

        token.mint(account, 125e18);
        vm.expectEmit(true, true, false, true, address(monitor));
        emit BalanceChanged(account, address(token), 500e18, 625e18);
        monitor.checkpoint(account, address(token));
        assertEq(monitor.lastKnownBalance(account, address(token)), 625e18);
    }

    function test_CheckpointDoesNotEmitWhenBalanceUnchanged() external {
        token.mint(account, 100e18);
        monitor.checkpoint(account, address(token));

        vm.recordLogs();
        monitor.checkpoint(account, address(token));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 0);
    }

    function test_LastKnownBalanceUpdates() external {
        vm.deal(account, 3 ether);
        monitor.checkpoint(account, address(0));
        assertEq(monitor.lastKnownBalance(account, address(0)), 3 ether);

        token.mint(account, 42e18);
        monitor.checkpoint(account, address(token));
        assertEq(monitor.lastKnownBalance(account, address(token)), 42e18);
    }
}
