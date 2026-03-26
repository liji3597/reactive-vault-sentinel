// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "@reactive/interfaces/IReactive.sol";
import "../src/sentinel/VaultSentinelReactive.sol";
import "../src/execution/VaultExecution.sol";

contract VaultSentinelReactiveTest is Test {
    event Callback(uint256 indexed chain_id, address indexed _contract, uint64 indexed gas_limit, bytes payload);

    address internal constant SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;
    bytes32 internal constant CALLBACK_TOPIC_0 = keccak256("Callback(uint256,address,uint64,bytes)");

    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant DESTINATION_CHAIN_ID = 84532;
    uint64 internal constant CALLBACK_GAS = 300000;
    uint256 internal constant ANSWER_UPDATED_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));

    address internal owner = address(this);
    address internal vaultExecution = address(0xE1);
    address internal priceFeed = address(0xF1);
    address internal balanceMonitor = address(0xF2);
    address internal adapter = address(0xA1);

    VaultSentinelReactive internal sentinel;

    function setUp() external {
        sentinel = _deployRnSentinel();
    }

    function test_AddRule() external {
        bytes memory extraData = abi.encode(address(0xAA), uint256(123));

        uint256 ruleId = sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            priceFeed,
            sentinel.ANSWER_UPDATED_TOPIC_0(),
            adapter,
            CALLBACK_GAS,
            uint256(1800e8),
            extraData
        );

        assertEq(ruleId, 0);
        assertEq(sentinel.nextRuleId(), 1);

        (
            uint256 id,
            VaultSentinelReactive.RuleType ruleType,
            bool paused,
            uint256 sourceChainId,
            address sourceContract,
            uint256 topic0,
            address adapterAddr,
            uint64 callbackGasLimit,
            uint256 threshold,
            bytes memory storedExtraData
        ) = sentinel.rules(ruleId);

        assertEq(id, 0);
        assertEq(uint8(ruleType), uint8(VaultSentinelReactive.RuleType.PriceBelow));
        assertFalse(paused);
        assertEq(sourceChainId, SEPOLIA_CHAIN_ID);
        assertEq(sourceContract, priceFeed);
        assertEq(topic0, sentinel.ANSWER_UPDATED_TOPIC_0());
        assertEq(adapterAddr, adapter);
        assertEq(callbackGasLimit, CALLBACK_GAS);
        assertEq(threshold, uint256(1800e8));
        assertEq(storedExtraData, extraData);
    }

    function test_PauseResumeRule() external {
        uint256 ruleId = sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            priceFeed,
            sentinel.ANSWER_UPDATED_TOPIC_0(),
            adapter,
            CALLBACK_GAS,
            uint256(1500e8),
            ""
        );

        sentinel.pauseRule(ruleId);
        (, , bool paused,,,,,,,) = sentinel.rules(ruleId);
        assertTrue(paused);

        sentinel.resumeRule(ruleId);
        (, , paused,,,,,,,) = sentinel.rules(ruleId);
        assertFalse(paused);
    }

    function test_ReactTriggersCallbackWhenPriceBelowThreshold() external {
        bytes memory extraData = abi.encode(address(0xB0), uint256(77));
        uint256 ruleId = sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            priceFeed,
            sentinel.ANSWER_UPDATED_TOPIC_0(),
            adapter,
            CALLBACK_GAS,
            uint256(1000e8),
            extraData
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
            tx_hash: uint256(keccak256("tx_price_below")),
            log_index: 1
        });

        bytes memory payload =
            abi.encodeWithSelector(VaultExecution.executeFromReactive.selector, owner, ruleId, adapter, extraData);

        vm.expectEmit(true, true, true, true, address(sentinel));
        emit Callback(DESTINATION_CHAIN_ID, vaultExecution, CALLBACK_GAS, payload);

        sentinel.react(log);
    }

    function test_ReactDoesNotTriggerWhenPriceAboveThreshold() external {
        sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            priceFeed,
            sentinel.ANSWER_UPDATED_TOPIC_0(),
            adapter,
            CALLBACK_GAS,
            uint256(1000e8),
            abi.encode(uint256(1))
        );

        _flipVmToTrue(sentinel);

        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: priceFeed,
            topic_0: sentinel.ANSWER_UPDATED_TOPIC_0(),
            topic_1: uint256(uint160(uint256(int256(1500e8)))),
            topic_2: 1,
            topic_3: 0,
            data: abi.encode(uint256(block.timestamp)),
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: uint256(keccak256("tx_price_above")),
            log_index: 2
        });

        vm.recordLogs();
        sentinel.react(log);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(_countTopic(logs, CALLBACK_TOPIC_0), 0);
    }

    function test_ReactTriggersTransferOutflowWhenNewBalanceBelowThreshold() external {
        bytes memory extraData = abi.encode(address(0xCAFE), uint256(1234));
        uint256 ruleId = sentinel.addRule(
            VaultSentinelReactive.RuleType.TransferOutflow,
            SEPOLIA_CHAIN_ID,
            balanceMonitor,
            sentinel.BALANCE_CHANGED_TOPIC_0(),
            adapter,
            CALLBACK_GAS,
            100 ether,
            extraData
        );

        _flipVmToTrue(sentinel);

        address monitoredAccount = address(0xACCC);
        address token = address(0);

        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: balanceMonitor,
            topic_0: sentinel.BALANCE_CHANGED_TOPIC_0(),
            topic_1: uint256(uint160(monitoredAccount)),
            topic_2: uint256(uint160(token)),
            topic_3: 0,
            data: abi.encode(uint256(120 ether), uint256(90 ether)),
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: uint256(keccak256("tx_outflow")),
            log_index: 3
        });

        bytes memory payload =
            abi.encodeWithSelector(VaultExecution.executeFromReactive.selector, owner, ruleId, adapter, extraData);
        vm.expectEmit(true, true, true, true, address(sentinel));
        emit Callback(DESTINATION_CHAIN_ID, vaultExecution, CALLBACK_GAS, payload);

        sentinel.react(log);
    }

    function test_ConstructorBootstrapsRules() external {
        bytes memory extraData = abi.encode(address(0xB0), uint256(99));
        VaultSentinelReactive.RuleInput[] memory bootstrapRules = new VaultSentinelReactive.RuleInput[](1);
        bootstrapRules[0] = VaultSentinelReactive.RuleInput({
            ruleType: VaultSentinelReactive.RuleType.PriceBelow,
            sourceChainId: SEPOLIA_CHAIN_ID,
            sourceContract: priceFeed,
            topic0: ANSWER_UPDATED_TOPIC_0,
            adapter: adapter,
            callbackGasLimit: CALLBACK_GAS,
            threshold: uint256(1000e8),
            extraData: extraData
        });

        VaultSentinelReactive bootstrapped = _deployRnSentinelWithRules(bootstrapRules);
        assertEq(bootstrapped.nextRuleId(), 1);

        _flipVmToTrue(bootstrapped);

        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: priceFeed,
            topic_0: ANSWER_UPDATED_TOPIC_0,
            topic_1: uint256(uint160(uint256(int256(900e8)))),
            topic_2: 1,
            topic_3: 0,
            data: abi.encode(uint256(block.timestamp)),
            block_number: block.number,
            op_code: 0,
            block_hash: 0,
            tx_hash: uint256(keccak256("tx_constructor_bootstrap")),
            log_index: 4
        });

        bytes memory payload =
            abi.encodeWithSelector(VaultExecution.executeFromReactive.selector, owner, uint256(0), adapter, extraData);

        vm.expectEmit(true, true, true, true, address(bootstrapped));
        emit Callback(DESTINATION_CHAIN_ID, vaultExecution, CALLBACK_GAS, payload);

        bootstrapped.react(log);
    }

    function _deployRnSentinel() internal returns (VaultSentinelReactive) {
        VaultSentinelReactive.RuleInput[] memory bootstrapRules = new VaultSentinelReactive.RuleInput[](0);
        return _deployRnSentinelWithRules(bootstrapRules);
    }

    function _deployRnSentinelWithRules(VaultSentinelReactive.RuleInput[] memory bootstrapRules)
        internal
        returns (VaultSentinelReactive)
    {
        vm.etch(SYSTEM_CONTRACT, hex"00");
        return new VaultSentinelReactive(
            owner, vaultExecution, DESTINATION_CHAIN_ID, priceFeed, balanceMonitor, CALLBACK_GAS, bootstrapRules
        );
    }

    function _flipVmToTrue(VaultSentinelReactive target) internal {
        bytes32 slot2 = vm.load(address(target), bytes32(uint256(2)));
        vm.store(address(target), bytes32(uint256(2)), bytes32(uint256(slot2) | uint256(1)));
    }

    function _countTopic(Vm.Log[] memory logs, bytes32 topic) internal pure returns (uint256 count) {
        uint256 len = logs.length;
        for (uint256 i = 0; i < len; ++i) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == topic) {
                count++;
            }
        }
    }
}
