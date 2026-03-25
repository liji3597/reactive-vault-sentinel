// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@reactive/interfaces/IReactive.sol";
import "../src/execution/VaultExecution.sol";
import "../src/sentinel/VaultSentinelReactive.sol";
import "../src/adapters/interfaces/IVaultActionAdapter.sol";

contract FlowAdapter is IVaultActionAdapter {
    bool public called;
    uint256 public lastRuleId;
    bytes public lastData;

    function execute(uint256 ruleId, bytes calldata data) external returns (bytes memory) {
        called = true;
        lastRuleId = ruleId;
        lastData = data;
        return abi.encode("flow-ok");
    }
}

contract ReactiveVaultFlowTest is Test {
    address internal constant SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;
    bytes32 internal constant CALLBACK_TOPIC_0 = keccak256("Callback(uint256,address,uint64,bytes)");

    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;
    uint64 internal constant CALLBACK_GAS = 300000;

    address internal owner = address(this);
    address internal callbackProxy = address(0xC0FFEE);
    address internal priceFeed = address(0x1001);
    address internal balanceMonitor = address(0x1002);

    VaultExecution internal execution;
    VaultSentinelReactive internal sentinel;
    FlowAdapter internal adapter;

    function setUp() external {
        execution = new VaultExecution(owner, callbackProxy);
        adapter = new FlowAdapter();
        execution.setAdapterAllowed(address(adapter), true);

        vm.etch(SYSTEM_CONTRACT, hex"00");
        sentinel = new VaultSentinelReactive(
            owner,
            address(execution),
            BASE_SEPOLIA_CHAIN_ID,
            priceFeed,
            balanceMonitor,
            CALLBACK_GAS
        );
    }

    function test_FullReactiveVaultFlow() external {
        bytes memory adapterData = abi.encode(address(0xDEAD), uint256(55));
        uint256 ruleId = sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            priceFeed,
            sentinel.ANSWER_UPDATED_TOPIC_0(),
            address(adapter),
            CALLBACK_GAS,
            uint256(1000e8),
            adapterData
        );

        _flipVmToTrue(sentinel);

        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: priceFeed,
            topic_0: sentinel.ANSWER_UPDATED_TOPIC_0(),
            topic_1: uint256(uint160(uint256(int256(900e8)))),
            topic_2: 1,
            topic_3: 0,
            data: abi.encode(uint256(block.timestamp)),
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: uint256(keccak256("flow-tx")),
            log_index: 9
        });

        vm.recordLogs();
        sentinel.react(log);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        (uint256 chainIdFromEvent, address targetFromEvent, uint64 gasFromEvent, bytes memory payload) =
            _extractCallback(logs);
        assertEq(chainIdFromEvent, BASE_SEPOLIA_CHAIN_ID);
        assertEq(targetFromEvent, address(execution));
        assertEq(gasFromEvent, CALLBACK_GAS);

        (bytes4 selector, address payloadRvmId, uint256 payloadRuleId, address payloadAdapter, bytes memory payloadData) =
            _decodeExecutePayload(payload);

        assertEq(selector, VaultExecution.executeFromReactive.selector);
        assertEq(payloadRvmId, address(0));
        assertEq(payloadRuleId, ruleId);
        assertEq(payloadAdapter, address(adapter));
        assertEq(payloadData, adapterData);

        vm.prank(callbackProxy);
        execution.executeFromReactive(address(this), payloadRuleId, payloadAdapter, payloadData);

        assertTrue(adapter.called());
        assertEq(adapter.lastRuleId(), ruleId);
        assertEq(adapter.lastData(), adapterData);
    }

    function _extractCallback(Vm.Log[] memory logs)
        internal
        view
        returns (uint256 chainId, address target, uint64 gasLimit, bytes memory payload)
    {
        uint256 len = logs.length;
        for (uint256 i = 0; i < len; ++i) {
            if (logs[i].emitter == address(sentinel) && logs[i].topics.length > 0 && logs[i].topics[0] == CALLBACK_TOPIC_0) {
                chainId = uint256(logs[i].topics[1]);
                target = address(uint160(uint256(logs[i].topics[2])));
                gasLimit = uint64(uint256(logs[i].topics[3]));
                payload = abi.decode(logs[i].data, (bytes));
                return (chainId, target, gasLimit, payload);
            }
        }
        revert("Callback event not found");
    }

    function _decodeExecutePayload(bytes memory payload)
        internal
        pure
        returns (bytes4 selector, address rvmId, uint256 ruleId, address adapterAddr, bytes memory adapterData)
    {
        require(payload.length >= 4, "payload-too-short");

        bytes32 word0;
        assembly {
            word0 := mload(add(payload, 32))
        }
        selector = bytes4(word0);

        bytes memory args = new bytes(payload.length - 4);
        for (uint256 i = 0; i < args.length; ++i) {
            args[i] = payload[i + 4];
        }

        (rvmId, ruleId, adapterAddr, adapterData) = abi.decode(args, (address, uint256, address, bytes));
    }

    function _flipVmToTrue(VaultSentinelReactive target) internal {
        bytes32 slot2 = vm.load(address(target), bytes32(uint256(2)));
        vm.store(address(target), bytes32(uint256(2)), bytes32(uint256(slot2) | uint256(1)));
    }
}
