// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/probes/ReactiveCallbackProbe.sol";

contract DeployLasnaReactiveCallbackProbe is Script {
    uint256 internal constant DEFAULT_SOURCE_CHAIN_ID = 11155111;
    uint256 internal constant DEFAULT_DESTINATION_CHAIN_ID = 84532;
    uint256 internal constant DEFAULT_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint64 internal constant DEFAULT_CALLBACK_GAS_LIMIT = 200000;
    uint256 internal constant DEFAULT_DEPLOY_VALUE = 0;

    address internal constant DEFAULT_SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;
    address internal constant DEFAULT_SOURCE_CONTRACT = 0xBc3e0eEb32d174f0a2DE9cbF7d2bae5259B7A8E1;
    address internal constant DEFAULT_CALLBACK_TARGET = 0xbC0271b8DAD9fD558aaD191024D4Bd5C115586B4;

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
        address systemContract = vm.envOr("VALIDATION_SYSTEM_CONTRACT", DEFAULT_SYSTEM_CONTRACT);
        uint256 sourceChainId = vm.envOr("VALIDATION_SOURCE_CHAIN_ID", DEFAULT_SOURCE_CHAIN_ID);
        uint256 destinationChainId = vm.envOr("VALIDATION_DESTINATION_CHAIN_ID", DEFAULT_DESTINATION_CHAIN_ID);
        address sourceContract = vm.envOr("VALIDATION_SOURCE_CONTRACT", DEFAULT_SOURCE_CONTRACT);
        address callbackContract = vm.envOr("VALIDATION_CALLBACK_CONTRACT", DEFAULT_CALLBACK_TARGET);
        uint256 topic0 = vm.envOr("VALIDATION_TOPIC0", DEFAULT_TOPIC_0);
        uint64 callbackGasLimit = uint64(vm.envOr("VALIDATION_CALLBACK_GAS_LIMIT", uint256(DEFAULT_CALLBACK_GAS_LIMIT)));
        uint256 deployValue = vm.envOr("VALIDATION_DEPLOY_VALUE_WEI", DEFAULT_DEPLOY_VALUE);

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");
        ReactiveCallbackProbe probe = new ReactiveCallbackProbe{value: deployValue}(
            systemContract, sourceChainId, destinationChainId, sourceContract, callbackContract, topic0, callbackGasLimit
        );
        vm.stopBroadcast();

        console2.log("=== Lasna Reactive Callback Probe ===");
        console2.log("ReactiveCallbackProbe:", address(probe));
        console2.log("vm:", probe.vm());
        console2.log("systemContract:", systemContract);
        console2.log("sourceChainId:", sourceChainId);
        console2.log("destinationChainId:", destinationChainId);
        console2.log("sourceContract:", sourceContract);
        console2.log("callbackContract:", callbackContract);
        console2.log("topic0:", topic0);
        console2.log("callbackGasLimit:", callbackGasLimit);
    }
}
