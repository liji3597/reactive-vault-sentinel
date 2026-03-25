import { type Chain } from 'viem'

export const sepolia = {
  id: 11155111,
  name: 'Sepolia',
  nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc.ankr.com/eth_sepolia'] },
  },
  blockExplorers: {
    default: { name: 'Etherscan', url: 'https://sepolia.etherscan.io' },
  },
} as const satisfies Chain

export const baseSepolia = {
  id: 84532,
  name: 'Base Sepolia',
  nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://sepolia.base.org'] },
  },
  blockExplorers: {
    default: { name: 'Basescan', url: 'https://sepolia.basescan.org' },
  },
} as const satisfies Chain

export const reactiveLasna = {
  id: 5318007,
  name: 'Reactive Lasna',
  nativeCurrency: { name: 'Reactive', symbol: 'REACT', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://lasna-rpc.rnk.dev/'] },
  },
  blockExplorers: {
    default: { name: 'Reactscan', url: 'https://kopli.reactscan.net' },
  },
} as const satisfies Chain

export const chains = {
  sepolia: { id: 11155111, name: "Sepolia", color: "#627EEA" },
  baseSepolia: { id: 84532, name: "Base Sepolia", color: "#0052FF" },
  reactiveLasna: { id: 5318007, name: "Reactive Lasna", color: "#22d3ee" }
}
