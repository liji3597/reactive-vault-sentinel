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
        address expectedRvmId;
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
        cfg.expectedRvmId = vm.envAddress("VAULT_EXECUTION_EXPECTED_RVM_ID");
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
        DeployConfig memory cfg = _loadConfig();

        VaultSentinelReactive.RuleInput[] memory bootstrapRules = new VaultSentinelReactive.RuleInput[](2);
        bootstrapRules[0] = VaultSentinelReactive.RuleInput({
            ruleType: VaultSentinelReactive.RuleType.PriceBelow,
            sourceChainId: SEPOLIA_CHAIN_ID,
            sourceContract: cfg.priceFeed,
            topic0: ANSWER_UPDATED_TOPIC_0,
            adapter: cfg.priceRuleAdapter,
            callbackGasLimit: cfg.priceRuleGas,
            threshold: cfg.priceBelowThreshold,
            extraData: cfg.priceRuleAdapterData
        });
        bootstrapRules[1] = VaultSentinelReactive.RuleInput({
            ruleType: VaultSentinelReactive.RuleType.TransferOutflow,
            sourceChainId: SEPOLIA_CHAIN_ID,
            sourceContract: cfg.balanceMonitor,
            topic0: BALANCE_CHANGED_TOPIC_0,
            adapter: cfg.drainRuleAdapter,
            callbackGasLimit: cfg.drainRuleGas,
            threshold: cfg.balanceMinThreshold,
            extraData: cfg.drainRuleAdapterData
        });

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");

        // _initializeDefaultSubscriptions() is guarded by `if (!vm)` in constructor.
        // Forge simulation: vm=true → subscriptions skipped. On-chain: vm=false → subscriptions execute.
        // Use --gas-estimate-multiplier 200 or explicit --gas-limit when broadcasting.
        VaultSentinelReactive sentinel = new VaultSentinelReactive{value: 0.1 ether}(
            cfg.owner,
            cfg.vaultExecution,
            cfg.expectedRvmId,
            cfg.destinationChainId,
            cfg.priceFeed,
            cfg.balanceMonitor,
            cfg.defaultCallbackGas,
            bootstrapRules,
            true
        );

        vm.stopBroadcast();

        console2.log("=== Reactive Lasna Deployment ===");
        console2.log("VaultSentinelReactive:", address(sentinel));
        console2.log("Subscription init mode:", "constructor auto-init (on-chain when !vm)");
        console2.log("Broadcast tip:", "use --gas-estimate-multiplier 200 or set explicit --gas-limit");
    }
}
