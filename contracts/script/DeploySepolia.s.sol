// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/mocks/MockPriceFeed.sol";
import "../src/monitors/BalanceMonitor.sol";

contract DeploySepolia is Script {
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

        _startBroadcastWithOptionalKey("SEPOLIA_PRIVATE_KEY");
        MockPriceFeed mockPriceFeed = new MockPriceFeed(owner, 2000e8, 8);
        BalanceMonitor balanceMonitor = new BalanceMonitor(owner);
        vm.stopBroadcast();

        console2.log("=== Sepolia Deployments ===");
        console2.log("MockPriceFeed:", address(mockPriceFeed));
        console2.log("BalanceMonitor:", address(balanceMonitor));
    }
}
