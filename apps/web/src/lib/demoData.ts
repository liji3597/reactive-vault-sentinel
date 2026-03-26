export type DemoRuleStatus = 'Active' | 'Paused';
export type DemoRuleType = 'PriceBelow' | 'PriceAbove' | 'TransferOutflow';

export interface DemoRule {
  id: number;
  name: string;
  type: DemoRuleType;
  threshold: string;
  status: DemoRuleStatus;
  chain: 'Sepolia' | 'Base Sepolia';
  target: 'Base Sepolia';
  health: 'Healthy' | 'Idle';
}

export interface DemoEvent {
  id: number;
  type: 'Triggered' | 'Executed' | 'Warning';
  rule: string;
  time: string;
  status: 'Processing' | 'Success' | 'Approaching';
  tx: string;
}

export interface TraceLog {
  time: string;
  chain: string;
  msg: string;
  type: 'info' | 'warning' | 'process' | 'success';
}

export const DEMO_RULES_STORAGE_KEY = 'vault-sentinel-demo-rules';

export const DEFAULT_DEMO_RULES: DemoRule[] = [
  {
    id: 1,
    name: 'ETH Depeg Guardian',
    type: 'PriceBelow',
    threshold: '3400 USD',
    status: 'Active',
    chain: 'Sepolia',
    target: 'Base Sepolia',
    health: 'Healthy',
  },
  {
    id: 2,
    name: 'Balance Refill',
    type: 'TransferOutflow',
    threshold: '2.5 ETH',
    status: 'Active',
    chain: 'Sepolia',
    target: 'Base Sepolia',
    health: 'Healthy',
  },
  {
    id: 3,
    name: 'Stop Loss - WBTC',
    type: 'PriceBelow',
    threshold: '62000 USD',
    status: 'Paused',
    chain: 'Sepolia',
    target: 'Base Sepolia',
    health: 'Idle',
  },
];

export const DEMO_EVENTS: DemoEvent[] = [
  {
    id: 1,
    type: 'Triggered',
    rule: 'ETH Depeg Guardian',
    time: '2m ago',
    status: 'Processing',
    tx: '0x4a...c23e',
  },
  {
    id: 2,
    type: 'Executed',
    rule: 'Balance Refill',
    time: '14m ago',
    status: 'Success',
    tx: '0x8b...f912',
  },
  {
    id: 3,
    type: 'Warning',
    rule: 'Stop Loss - WBTC',
    time: '1h ago',
    status: 'Approaching',
    tx: '0x12...a34d',
  },
  {
    id: 4,
    type: 'Executed',
    rule: 'ETH Depeg Guardian',
    time: '4h ago',
    status: 'Success',
    tx: '0x9d...e56c',
  },
];

export const DEMO_TRACE_LOGS: TraceLog[] = [
  {
    time: '14:22:01',
    chain: 'Sepolia',
    msg: 'Detected AnswerUpdated on PriceFeed (0x694A...)',
    type: 'info',
  },
  {
    time: '14:22:01',
    chain: 'Sepolia',
    msg: 'Price $3398.42 < Threshold $3400.00',
    type: 'warning',
  },
  {
    time: '14:22:02',
    chain: 'ReactVM',
    msg: 'Triggering Reactive logic for Rule #1',
    type: 'process',
  },
  {
    time: '14:22:05',
    chain: 'ReactVM',
    msg: 'Callback emitted for Base Sepolia (ChainID: 84532)',
    type: 'process',
  },
  {
    time: '14:22:08',
    chain: 'Base Sepolia',
    msg: 'VaultExecution.executeFromReactive started',
    type: 'info',
  },
  {
    time: '14:22:12',
    chain: 'Base Sepolia',
    msg: 'Success: ExecutionSucceeded (Rule: 1, Adapter: 0x8a...)',
    type: 'success',
  },
];
