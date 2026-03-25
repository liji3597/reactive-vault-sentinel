export const CONTRACT_ADDRESSES = {
  vaultSentinel: "0x0000000000000000000000000000000000000000",
  vaultExecution: "0x0000000000000000000000000000000000000000",
  priceFeed: "0x0000000000000000000000000000000000000000",
  balanceMonitor: "0x0000000000000000000000000000000000000000",
};

export const VAULT_SENTINEL_ABI = [
  "function addRule(uint8 ruleType, uint256 sourceChainId, address sourceContract, uint256 topic0, address adapter, uint64 callbackGasLimit, uint256 threshold, bytes extraData) external returns (uint256)",
  "function pauseRule(uint256 ruleId) external",
  "function resumeRule(uint256 ruleId) external",
  "function getRuleIds() external view returns (uint256[])",
  "function rules(uint256) external view returns (uint256 id, uint8 ruleType, bool paused, uint256 sourceChainId, address sourceContract, uint256 topic0, address adapter, uint64 callbackGasLimit, uint256 threshold, bytes extraData)",
  "event RuleAdded(uint256 indexed ruleId, uint8 indexed ruleType, address indexed adapter)",
  "event RulePaused(uint256 indexed ruleId)",
  "event RuleResumed(uint256 indexed ruleId)",
  "event RuleTriggered(uint256 indexed ruleId, uint256 txHash, uint256 logIndex)",
] as const;

export const VAULT_EXECUTION_ABI = [
  "function executeFromReactive(address rvmId, uint256 ruleId, address adapter, bytes calldata adapterData) external",
  "event ExecutionSucceeded(uint256 indexed ruleId, address indexed adapter, bytes returnData)",
  "event ExecutionFailed(uint256 indexed ruleId, address indexed adapter, bytes reason)",
] as const;

export const PRICE_FEED_ABI = [
  "function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)",
  "function latestAnswer() external view returns (int256)",
] as const;

export const BALANCE_MONITOR_ABI = [
  "function checkpoint(address account, address token) external",
  "function lastKnownBalance(address account, address token) external view returns (uint256)",
  "event BalanceChanged(address indexed account, address indexed token, uint256 oldBalance, uint256 newBalance)",
] as const;
