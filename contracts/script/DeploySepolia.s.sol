// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/mocks/MockPriceFeed.sol";
import "../src/monitors/BalanceMonitor.sol";

contract DeploySepolia is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast(deployerPrivateKey);
        MockPriceFeed mockPriceFeed = new MockPriceFeed(owner, 2000e8, 8);
        BalanceMonitor balanceMonitor = new BalanceMonitor(owner);
        vm.stopBroadcast();

        console2.log("=== Sepolia Deployments ===");
        console2.log("MockPriceFeed:", address(mockPriceFeed));
        console2.log("BalanceMonitor:", address(balanceMonitor));
    }
}
