// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@reactive/interfaces/ISubscriptionService.sol";

contract RawSubscriptionProbe {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    constructor() payable {}

    function subscribeRaw(uint256 sourceChainId, address sourceContract, uint256 topic0) external {
        ISubscriptionService(payable(0x0000000000000000000000000000000000fffFfF)).subscribe(
            sourceChainId,
            sourceContract,
            topic0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }
}

contract ValidateLasnaRawSub is Script {
    uint256 internal constant DEFAULT_SOURCE_CHAIN_ID = 11155111;
    uint256 internal constant DEFAULT_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint256 internal constant DEFAULT_VALUE = 0;

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

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");
        RawSubscriptionProbe probe = new RawSubscriptionProbe{value: deployValue}();

        bool attempted = true;
        bool subscribeCallSucceeded;
        try probe.subscribeRaw(sourceChainId, sourceContract, topic0) {
            subscribeCallSucceeded = true;
        } catch {
            subscribeCallSucceeded = false;
        }
        vm.stopBroadcast();

        console2.log("=== Lasna Raw Subscribe Validation ===");
        console2.log("RawSubscriptionProbe:", address(probe));
        console2.log("rawSubscribeAttempted:", attempted);
        console2.log("rawSubscribeSucceeded:", subscribeCallSucceeded);
        console2.log("sourceChainId:", sourceChainId);
        console2.log("sourceContract:", sourceContract);
        console2.log("topic0:", topic0);
    }
}
