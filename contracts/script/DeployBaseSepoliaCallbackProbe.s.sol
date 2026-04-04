// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/probes/CallbackProbe.sol";

contract DeployBaseSepoliaCallbackProbe is Script {
    address internal constant DEFAULT_BASE_CALLBACK_PROXY = 0xa6eA49Ed671B8a4dfCDd34E36b7a75Ac79B8A5a6;

    function _startBroadcastWithOptionalKey(string memory privateKeyEnv) internal {
        string memory keystore = vm.envOr("BASE_KEYSTORE", string(""));
        if (bytes(keystore).length != 0) {
            vm.startBroadcast();
            return;
        }

        string memory keystoreAccount = vm.envOr("BASE_KEYSTORE_ACCOUNT", string(""));
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
        address callbackProxy = vm.envOr("BASE_CALLBACK_PROXY", DEFAULT_BASE_CALLBACK_PROXY);
        address expectedRvmId = address(0);

        string memory rawExpectedRvmId = vm.envOr("VAULT_EXECUTION_EXPECTED_RVM_ID", string(""));
        if (bytes(rawExpectedRvmId).length != 0) {
            expectedRvmId = vm.parseAddress(rawExpectedRvmId);
        }

        _startBroadcastWithOptionalKey("BASE_PRIVATE_KEY");
        CallbackProbe probe = new CallbackProbe(callbackProxy, expectedRvmId);
        vm.stopBroadcast();

        console2.log("=== Base Sepolia Callback Probe ===");
        console2.log("CallbackProbe:", address(probe));
        console2.log("Callback proxy:", callbackProxy);
        console2.log("Expected RVM ID:", expectedRvmId);
    }
}
