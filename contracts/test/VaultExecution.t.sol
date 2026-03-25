// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../src/execution/VaultExecution.sol";
import "../src/adapters/interfaces/IVaultActionAdapter.sol";

contract MockVaultAdapter is IVaultActionAdapter {
    bool public called;
    uint256 public lastRuleId;
    bytes public lastData;
    bytes public returnData;

    function setReturnData(bytes calldata data) external {
        returnData = data;
    }

    function execute(uint256 ruleId, bytes calldata data) external returns (bytes memory) {
        called = true;
        lastRuleId = ruleId;
        lastData = data;
        if (returnData.length == 0) {
            return abi.encode(ruleId, data);
        }
        return returnData;
    }
}

contract VaultExecutionTest is Test {
    event AdapterAllowed(address indexed adapter, bool allowed);

    VaultExecution internal execution;
    MockVaultAdapter internal adapter;

    address internal owner = address(this);
    address internal callbackProxy = address(0xCA11BAAC);
    address internal attacker = address(0xBAD);

    uint256 internal constant RULE_ID = 7;

    function setUp() external {
        execution = new VaultExecution(owner, callbackProxy);
        adapter = new MockVaultAdapter();
    }

    function test_SetAdapterAllowed() external {
        vm.expectEmit(true, false, false, true, address(execution));
        emit AdapterAllowed(address(adapter), true);
        execution.setAdapterAllowed(address(adapter), true);
        assertTrue(execution.allowedAdapters(address(adapter)));
    }

    function test_ExecuteFromReactiveWithValidAdapterSucceeds() external {
        bytes memory adapterData = abi.encode(address(0x1), address(0x2), uint256(123));
        bytes memory expectedReturn = abi.encode("ok");

        execution.setAdapterAllowed(address(adapter), true);
        adapter.setReturnData(expectedReturn);

        vm.prank(callbackProxy);
        execution.executeFromReactive(address(this), RULE_ID, address(adapter), adapterData);

        assertTrue(adapter.called());
        assertEq(adapter.lastRuleId(), RULE_ID);
        assertEq(adapter.lastData(), adapterData);
    }

    function test_ExecuteFromReactiveWithNonWhitelistedAdapterReverts() external {
        bytes memory adapterData = abi.encode(uint256(1));

        vm.prank(callbackProxy);
        vm.expectRevert(abi.encodeWithSelector(VaultExecution.AdapterNotAllowed.selector, address(adapter)));
        execution.executeFromReactive(address(this), RULE_ID, address(adapter), adapterData);
    }

    function test_ExecuteFromReactiveFromNonProxyReverts() external {
        execution.setAdapterAllowed(address(adapter), true);

        vm.prank(attacker);
        vm.expectRevert(bytes("Authorized sender only"));
        execution.executeFromReactive(address(this), RULE_ID, address(adapter), "");
    }

    function test_ExecuteFromReactiveWithWrongRvmIdReverts() external {
        execution.setAdapterAllowed(address(adapter), true);

        vm.prank(callbackProxy);
        vm.expectRevert(bytes("Authorized RVM ID only"));
        execution.executeFromReactive(address(0xDEAD), RULE_ID, address(adapter), "");
    }

    function test_PauseUnpause() external {
        execution.setAdapterAllowed(address(adapter), true);
        execution.pause();
        assertTrue(execution.paused());

        vm.prank(callbackProxy);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        execution.executeFromReactive(address(this), RULE_ID, address(adapter), "");

        execution.unpause();
        assertFalse(execution.paused());

        vm.prank(callbackProxy);
        execution.executeFromReactive(address(this), RULE_ID, address(adapter), "");
        assertTrue(adapter.called());
    }
}
