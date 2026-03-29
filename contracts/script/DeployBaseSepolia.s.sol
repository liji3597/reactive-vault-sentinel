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

        _startBroadcastWithOptionalKey("BASE_PRIVATE_KEY");

        VaultExecution vaultExecution = new VaultExecution(owner, BASE_CALLBACK_PROXY);

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
        console2.log("UniswapStopOrderAdapter:", address(uniswapAdapter));
        console2.log("AaveProtectionAdapter:", address(aaveAdapter));
    }
}
