'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http } from 'viem';
import { createConfig, WagmiProvider } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { sepolia, baseSepolia, reactiveLasna } from '@/lib/chains';

const chains = [sepolia, baseSepolia, reactiveLasna] as const;
const queryClient = new QueryClient();

const config = createConfig({
  chains,
  ssr: true,
  connectors: [injected()],
  transports: {
    [sepolia.id]: http(),
    [baseSepolia.id]: http(),
    [reactiveLasna.id]: http(),
  },
});

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}
