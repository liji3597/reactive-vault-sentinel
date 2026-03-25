'use client';

import * as React from 'react';
import {
  RainbowKitProvider,
  getDefaultConfig,
  darkTheme,
} from '@rainbow-me/rainbowkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { http } from 'viem';
import { createConfig, WagmiProvider } from 'wagmi';
import { sepolia, baseSepolia, reactiveLasna } from '@/lib/chains';
import '@rainbow-me/rainbowkit/styles.css';

const chains = [sepolia, baseSepolia, reactiveLasna] as const;
const walletConnectProjectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID;

const config =
  typeof window === 'undefined' || !walletConnectProjectId
    ? createConfig({
        chains,
        ssr: true,
        connectors: [],
        transports: {
          [sepolia.id]: http(),
          [baseSepolia.id]: http(),
          [reactiveLasna.id]: http(),
        },
      })
    : getDefaultConfig({
        appName: 'Reactive Vault Sentinel',
        projectId: walletConnectProjectId,
        chains,
        ssr: true,
      });

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: '#22d3ee',
            accentColorForeground: 'black',
            borderRadius: 'medium',
            overlayBlur: 'small',
          })}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
