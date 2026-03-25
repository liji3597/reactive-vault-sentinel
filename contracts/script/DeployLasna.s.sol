// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/sentinel/VaultSentinelReactive.sol";

contract DeployLasna is Script {
    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant ANSWER_UPDATED_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint256 internal constant BALANCE_CHANGED_TOPIC_0 =
        uint256(keccak256("BalanceChanged(address,address,uint256,uint256)"));

    struct DeployConfig {
        address owner;
        address vaultExecution;
        uint256 destinationChainId;
        address priceFeed;
        address balanceMonitor;
        uint64 defaultCallbackGas;
        address priceRuleAdapter;
        address drainRuleAdapter;
        uint64 priceRuleGas;
        uint64 drainRuleGas;
        uint256 priceBelowThreshold;
        uint256 balanceMinThreshold;
        bytes priceRuleAdapterData;
        bytes drainRuleAdapterData;
    }

    function _loadConfig() internal view returns (DeployConfig memory cfg) {
        cfg.owner = vm.envAddress("OWNER");
        cfg.vaultExecution = vm.envAddress("VAULT_EXECUTION");
        cfg.destinationChainId = vm.envUint("BASE_CHAIN_ID");
        cfg.priceFeed = vm.envAddress("MOCK_PRICE_FEED");
        cfg.balanceMonitor = vm.envAddress("BALANCE_MONITOR");
        cfg.defaultCallbackGas = uint64(vm.envUint("DEFAULT_CALLBACK_GAS"));
        cfg.priceRuleAdapter = vm.envAddress("PRICE_RULE_ADAPTER");
        cfg.drainRuleAdapter = vm.envAddress("DRAIN_RULE_ADAPTER");
        cfg.priceRuleGas = uint64(vm.envUint("PRICE_RULE_GAS"));
        cfg.drainRuleGas = uint64(vm.envUint("DRAIN_RULE_GAS"));
        cfg.priceBelowThreshold = vm.envUint("PRICE_BELOW_THRESHOLD");
        cfg.balanceMinThreshold = vm.envUint("BALANCE_MIN_THRESHOLD");
        cfg.priceRuleAdapterData = vm.envBytes("PRICE_RULE_ADAPTER_DATA");
        cfg.drainRuleAdapterData = vm.envBytes("DRAIN_RULE_ADAPTER_DATA");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("REACTIVE_PRIVATE_KEY");
        DeployConfig memory cfg = _loadConfig();

        vm.startBroadcast(deployerPrivateKey);

        VaultSentinelReactive sentinel = new VaultSentinelReactive{value: 0.1 ether}(
            cfg.owner, cfg.vaultExecution, cfg.destinationChainId, cfg.priceFeed, cfg.balanceMonitor, cfg.defaultCallbackGas
        );

        sentinel.addRule(
            VaultSentinelReactive.RuleType.PriceBelow,
            SEPOLIA_CHAIN_ID,
            cfg.priceFeed,
            ANSWER_UPDATED_TOPIC_0,
            cfg.priceRuleAdapter,
            cfg.priceRuleGas,
            cfg.priceBelowThreshold,
            cfg.priceRuleAdapterData
        );

        sentinel.addRule(
            VaultSentinelReactive.RuleType.TransferOutflow,
            SEPOLIA_CHAIN_ID,
            cfg.balanceMonitor,
            BALANCE_CHANGED_TOPIC_0,
            cfg.drainRuleAdapter,
            cfg.drainRuleGas,
            cfg.balanceMinThreshold,
            cfg.drainRuleAdapterData
        );

        vm.stopBroadcast();

        console2.log("=== Reactive Lasna Deployment ===");
        console2.log("VaultSentinelReactive:", address(sentinel));
    }
}
