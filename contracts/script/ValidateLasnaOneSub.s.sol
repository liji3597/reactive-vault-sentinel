// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@reactive/abstract-base/AbstractReactive.sol";

contract OneSubscriptionProbe is AbstractReactive {
    error AlreadySubscribed();

    event SubscriptionSucceeded(
        uint256 indexed sourceChainId,
        address indexed sourceContract,
        uint256 indexed topic0,
        bool viaConstructor
    );
    event ReactObserved(
        uint256 indexed sourceChainId,
        address indexed sourceContract,
        uint256 indexed topic0,
        uint256 txHash,
        uint256 logIndex
    );

    bool public subscribed;
    uint256 public configuredSourceChainId;
    address public configuredSourceContract;
    uint256 public configuredTopic0;
    bool public constructorSubscribeEnabled;
    bool public subscriptionViaConstructor;
    uint256 public reactObservationCount;
    uint256 public lastReactSourceChainId;
    address public lastReactSourceContract;
    uint256 public lastReactTopic0;
    uint256 public lastReactTxHash;
    uint256 public lastReactLogIndex;

    constructor(uint256 sourceChainId, address sourceContract, uint256 topic0, bool subscribeInConstructor) payable {
        configuredSourceChainId = sourceChainId;
        configuredSourceContract = sourceContract;
        configuredTopic0 = topic0;
        constructorSubscribeEnabled = subscribeInConstructor;
        if (subscribeInConstructor && !vm) {
            _subscribeOnce(sourceChainId, sourceContract, topic0, true);
        }
    }

    function subscribeOnce(uint256 sourceChainId, address sourceContract, uint256 topic0) external rnOnly {
        _subscribeOnce(sourceChainId, sourceContract, topic0, false);
    }

    function react(LogRecord calldata log) external vmOnly {
        reactObservationCount += 1;
        lastReactSourceChainId = log.chain_id;
        lastReactSourceContract = log._contract;
        lastReactTopic0 = log.topic_0;
        lastReactTxHash = log.tx_hash;
        lastReactLogIndex = log.log_index;

        emit ReactObserved(log.chain_id, log._contract, log.topic_0, log.tx_hash, log.log_index);
    }

    function _subscribeOnce(uint256 sourceChainId, address sourceContract, uint256 topic0, bool viaConstructor) internal {
        if (subscribed) {
            revert AlreadySubscribed();
        }
        service.subscribe(sourceChainId, sourceContract, topic0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        subscribed = true;
        subscriptionViaConstructor = viaConstructor;

        emit SubscriptionSucceeded(sourceChainId, sourceContract, topic0, viaConstructor);
    }
}

contract ValidateLasnaOneSub is Script {
    uint256 internal constant DEFAULT_SOURCE_CHAIN_ID = 11155111;
    uint256 internal constant DEFAULT_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint256 internal constant DEFAULT_VALUE = 0.1 ether;

    function _startBroadcastWithOptionalKey(string memory privateKeyEnv) internal {
        string memory keystore = vm.envOr("REACTIVE_KEYSTORE", string(""));
        if (bytes(keystore).length != 0) {
            vm.startBroadcast();
            return;
        }

        string memory keystoreAccount = vm.envOr("REACTIVE_KEYSTORE_ACCOUNT", string(""));
        if (bytes(keystoreAccount).length != 0) {
            vm.startBroadcast();
            return;
        }

        string memory privateKey = vm.envOr(privateKeyEnv, string("__SET_LOCALLY_ONLY__"));
        if (
            bytes(privateKey).length != 0
                && keccak256(bytes(privateKey)) != keccak256(bytes("__SET_LOCALLY_ONLY__"))
        ) {
            vm.startBroadcast(vm.parseUint(privateKey));
        } else {
            vm.startBroadcast();
        }
    }

    function run() external {
        uint256 sourceChainId = vm.envOr("VALIDATION_SOURCE_CHAIN_ID", DEFAULT_SOURCE_CHAIN_ID);
        address sourceContract = vm.envAddress("VALIDATION_SOURCE_CONTRACT");
        uint256 topic0 = vm.envOr("VALIDATION_TOPIC0", DEFAULT_TOPIC_0);
        uint256 deployValue = vm.envOr("VALIDATION_DEPLOY_VALUE_WEI", DEFAULT_VALUE);
        bool postDeploySubscribe = vm.envOr("VALIDATION_POST_DEPLOY_SUBSCRIBE", false);

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");
        OneSubscriptionProbe probe =
            new OneSubscriptionProbe{value: deployValue}(sourceChainId, sourceContract, topic0, !postDeploySubscribe);
        if (postDeploySubscribe) {
            probe.subscribeOnce(sourceChainId, sourceContract, topic0);
        }
        vm.stopBroadcast();

        console2.log("=== Lasna One-Subscription Validation ===");
        console2.log("OneSubscriptionProbe:", address(probe));
        console2.log("postDeploySubscribe:", postDeploySubscribe);
        console2.log("sourceChainId:", sourceChainId);
        console2.log("sourceContract:", sourceContract);
        console2.log("topic0:", topic0);
        console2.log("subscribed:", probe.subscribed());
        console2.log("subscriptionViaConstructor:", probe.subscriptionViaConstructor());
    }
}
