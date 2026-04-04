// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@reactive/abstract-base/AbstractPausableReactive.sol";
import "../execution/VaultExecution.sol";

contract VaultSentinelReactive is AbstractPausableReactive {
    enum RuleType {
        PriceBelow,
        PriceAbove,
        TransferOutflow
    }

    struct Rule {
        uint256 id;
        RuleType ruleType;
        bool paused;
        uint256 sourceChainId;
        address sourceContract;
        uint256 topic0;
        address adapter;
        uint64 callbackGasLimit;
        uint256 threshold;
        bytes extraData;
    }

    struct RuleInput {
        RuleType ruleType;
        uint256 sourceChainId;
        address sourceContract;
        uint256 topic0;
        address adapter;
        uint64 callbackGasLimit;
        uint256 threshold;
        bytes extraData;
    }

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint64 public constant MIN_CALLBACK_GAS = 100000;
    uint64 public constant MAX_CALLBACK_GAS = 900000;

    uint256 public constant ANSWER_UPDATED_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint256 public constant BALANCE_CHANGED_TOPIC_0 =
        uint256(keccak256("BalanceChanged(address,address,uint256,uint256)"));

    address public vaultExecution;
    address public immutable expectedRvmId;
    uint256 public destinationChainId;
    address public priceFeed;
    address public balanceMonitor;
    uint64 public defaultCallbackGas;
    bool public defaultSubscriptionsInitialized;

    uint256 public nextRuleId;
    mapping(uint256 => Rule) public rules;
    uint256[] private ruleIds;

    event RuleAdded(uint256 indexed ruleId, RuleType indexed ruleType, address indexed adapter);
    event RulePaused(uint256 indexed ruleId);
    event RuleResumed(uint256 indexed ruleId);
    event RuleTriggered(uint256 indexed ruleId, uint256 txHash, uint256 logIndex);
    event DefaultSubscriptionsInitialized(address indexed priceFeed, address indexed balanceMonitor);

    error InvalidAddress();
    error InvalidRuleId(uint256 ruleId);
    error InvalidGasLimit(uint64 gasLimit);
    error InvalidThreshold(uint256 threshold);

    constructor(
        address _owner,
        address _vaultExecution,
        address _expectedRvmId,
        uint256 _destinationChainId,
        address _priceFeed,
        address _balanceMonitor,
        uint64 _defaultCallbackGas,
        RuleInput[] memory bootstrapRules,
        bool _autoInitializeDefaultSubscriptions
    ) payable {
        if (
            _owner == address(0) || _vaultExecution == address(0) || _expectedRvmId == address(0)
                || _priceFeed == address(0) || _balanceMonitor == address(0)
        ) {
            revert InvalidAddress();
        }

        owner = _owner;
        vaultExecution = _vaultExecution;
        expectedRvmId = _expectedRvmId;
        destinationChainId = _destinationChainId;
        priceFeed = _priceFeed;
        balanceMonitor = _balanceMonitor;
        defaultCallbackGas = _validateGasLimit(_defaultCallbackGas);

        uint256 bootstrapLen = bootstrapRules.length;
        for (uint256 i = 0; i < bootstrapLen; ++i) {
            RuleInput memory rule = bootstrapRules[i];
            _addRule(
                rule.ruleType,
                rule.sourceChainId,
                rule.sourceContract,
                rule.topic0,
                rule.adapter,
                rule.callbackGasLimit,
                rule.threshold,
                rule.extraData
            );
        }

        if (!vm && _autoInitializeDefaultSubscriptions) {
            _initializeDefaultSubscriptions();
        }
    }

    function initializeDefaultSubscriptions() external rnOnly onlyOwner {
        _initializeDefaultSubscriptions();
    }

    function isSentinelPaused() external view returns (bool) {
        return paused;
    }

    function _initializeDefaultSubscriptions() internal {
        if (defaultSubscriptionsInitialized) {
            return;
        }
        service.subscribe(
            SEPOLIA_CHAIN_ID, priceFeed, ANSWER_UPDATED_TOPIC_0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        );
        service.subscribe(
            SEPOLIA_CHAIN_ID, balanceMonitor, BALANCE_CHANGED_TOPIC_0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
        );

        defaultSubscriptionsInitialized = true;
        emit DefaultSubscriptionsInitialized(priceFeed, balanceMonitor);
    }

    function addRule(
        RuleType ruleType,
        uint256 sourceChainId,
        address sourceContract,
        uint256 topic0,
        address adapter,
        uint64 callbackGasLimit,
        uint256 threshold,
        bytes calldata extraData
    ) external rnOnly onlyOwner returns (uint256) {
        return _addRule(ruleType, sourceChainId, sourceContract, topic0, adapter, callbackGasLimit, threshold, extraData);
    }

    function _addRule(
        RuleType ruleType,
        uint256 sourceChainId,
        address sourceContract,
        uint256 topic0,
        address adapter,
        uint64 callbackGasLimit,
        uint256 threshold,
        bytes memory extraData
    ) internal returns (uint256) {
        if (sourceContract == address(0) || adapter == address(0)) {
            revert InvalidAddress();
        }
        if (
            (ruleType == RuleType.PriceBelow || ruleType == RuleType.PriceAbove)
                && threshold > uint256(type(int256).max)
        ) {
            revert InvalidThreshold(threshold);
        }

        uint256 ruleId = nextRuleId;
        uint64 gasLimit = callbackGasLimit == 0 ? defaultCallbackGas : _validateGasLimit(callbackGasLimit);

        rules[ruleId] = Rule({
            id: ruleId,
            ruleType: ruleType,
            paused: false,
            sourceChainId: sourceChainId,
            sourceContract: sourceContract,
            topic0: topic0,
            adapter: adapter,
            callbackGasLimit: gasLimit,
            threshold: threshold,
            extraData: extraData
        });
        ruleIds.push(ruleId);
        nextRuleId = ruleId + 1;

        emit RuleAdded(ruleId, ruleType, adapter);
        return ruleId;
    }

    function pauseRule(uint256 ruleId) external rnOnly onlyOwner {
        if (ruleId >= nextRuleId) {
            revert InvalidRuleId(ruleId);
        }
        rules[ruleId].paused = true;
        emit RulePaused(ruleId);
    }

    function resumeRule(uint256 ruleId) external rnOnly onlyOwner {
        if (ruleId >= nextRuleId) {
            revert InvalidRuleId(ruleId);
        }
        rules[ruleId].paused = false;
        emit RuleResumed(ruleId);
    }

    function react(LogRecord calldata log) external vmOnly {
        uint256 len = ruleIds.length;
        for (uint256 i = 0; i < len; ++i) {
            Rule storage rule = rules[ruleIds[i]];
            if (rule.paused) {
                continue;
            }
            if (rule.sourceChainId != log.chain_id || rule.sourceContract != log._contract || rule.topic0 != log.topic_0) {
                continue;
            }

            if (!_isTriggered(rule, log)) {
                continue;
            }

            bytes memory payload = abi.encodeWithSelector(
                VaultExecution.executeFromReactive.selector, expectedRvmId, rule.id, rule.adapter, rule.extraData
            );

            emit Callback(destinationChainId, vaultExecution, rule.callbackGasLimit, payload);
            emit RuleTriggered(rule.id, log.tx_hash, log.log_index);
        }
    }

    function getPausableSubscriptions() internal view override returns (Subscription[] memory) {
        Subscription[] memory subscriptions = new Subscription[](2);
        subscriptions[0] = Subscription({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: priceFeed,
            topic_0: ANSWER_UPDATED_TOPIC_0,
            topic_1: REACTIVE_IGNORE,
            topic_2: REACTIVE_IGNORE,
            topic_3: REACTIVE_IGNORE
        });
        subscriptions[1] = Subscription({
            chain_id: SEPOLIA_CHAIN_ID,
            _contract: balanceMonitor,
            topic_0: BALANCE_CHANGED_TOPIC_0,
            topic_1: REACTIVE_IGNORE,
            topic_2: REACTIVE_IGNORE,
            topic_3: REACTIVE_IGNORE
        });
        return subscriptions;
    }

    function getRuleIds() external view returns (uint256[] memory) {
        return ruleIds;
    }

    function _validateGasLimit(uint64 gasLimit) internal pure returns (uint64) {
        if (gasLimit < MIN_CALLBACK_GAS || gasLimit > MAX_CALLBACK_GAS) {
            revert InvalidGasLimit(gasLimit);
        }
        return gasLimit;
    }

    function _isTriggered(Rule storage rule, LogRecord calldata log) internal view returns (bool) {
        if (rule.ruleType == RuleType.PriceBelow) {
            int256 current = int256(log.topic_1);
            int256 threshold = int256(rule.threshold);
            return current < threshold;
        }

        if (rule.ruleType == RuleType.PriceAbove) {
            int256 current = int256(log.topic_1);
            int256 threshold = int256(rule.threshold);
            return current > threshold;
        }

        if (rule.ruleType == RuleType.TransferOutflow) {
            (, uint256 newBalance) = abi.decode(log.data, (uint256, uint256));
            return newBalance < rule.threshold;
        }

        return false;
    }
}
