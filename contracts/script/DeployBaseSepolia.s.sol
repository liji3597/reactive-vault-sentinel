// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/execution/VaultExecution.sol";
import "../src/adapters/basic/BasicTransferAdapter.sol";
import "../src/adapters/uniswap/UniswapStopOrderAdapter.sol";
import "../src/adapters/aave/AaveProtectionAdapter.sol";

contract DeployBaseSepolia is Script {
    address internal constant BASE_CALLBACK_PROXY = 0xa6eA49Ed671B8a4dfCDd34E36b7a75Ac79B8A5a6;

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
        address owner = vm.envAddress("OWNER");
        address uniswapRouter = vm.envAddress("UNISWAP_ROUTER");
        address aavePool = vm.envAddress("AAVE_POOL");
        address expectedRvmId = address(0);
        {
            string memory raw = vm.envOr("VAULT_EXECUTION_EXPECTED_RVM_ID", string(""));
            if (bytes(raw).length != 0) {
                expectedRvmId = vm.parseAddress(raw);
            }
        }

        _startBroadcastWithOptionalKey("BASE_PRIVATE_KEY");

        VaultExecution vaultExecution = new VaultExecution(owner, BASE_CALLBACK_PROXY, expectedRvmId);

        BasicTransferAdapter basicAdapter = new BasicTransferAdapter(owner, address(vaultExecution));
        UniswapStopOrderAdapter uniswapAdapter =
            new UniswapStopOrderAdapter(owner, address(vaultExecution), uniswapRouter);
        AaveProtectionAdapter aaveAdapter = new AaveProtectionAdapter(owner, address(vaultExecution), aavePool);

        vaultExecution.setAdapterAllowed(address(basicAdapter), true);
        vaultExecution.setAdapterAllowed(address(uniswapAdapter), true);
        vaultExecution.setAdapterAllowed(address(aaveAdapter), true);

        vm.stopBroadcast();

        console2.log("=== Base Sepolia Deployments ===");
        console2.log("VaultExecution:", address(vaultExecution));
        console2.log("BasicTransferAdapter:", address(basicAdapter));
        console2.log("Configured expected RVM ID:", expectedRvmId);
        console2.log("UniswapStopOrderAdapter:", address(uniswapAdapter));
        console2.log("AaveProtectionAdapter:", address(aaveAdapter));
        if (expectedRvmId == address(0)) {
            console2.log("WARNING: VAULT_EXECUTION_EXPECTED_RVM_ID not set. Deploying with address(0).");
            console2.log("ACTION: call VaultExecution.setExpectedRvmId(<reactive_deployer_wallet>) after Lasna deploy.");
        }
    }
}
