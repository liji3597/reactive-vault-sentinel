'use client';

import { Bell, Search, Settings } from 'lucide-react';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { appMode } from '@/lib/contracts';

export default function TopBar() {
  const statusLabel = appMode === 'demo' ? 'Sentinel Demo Mode' : 'Sentinel Online';
  const dotColor = appMode === 'demo' ? 'bg-amber-400' : 'bg-emerald-400';
  const { address, isConnected, chain } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  const injectedConnector = connectors.find((connector) => connector.id === 'injected') ?? connectors[0];
  const accountLabel = address ? `${address.slice(0, 6)}...${address.slice(-4)}` : 'Connect Wallet';

  return (
    <header className="h-20 border-b border-slate-800 bg-slate-950/80 backdrop-blur-md flex items-center justify-between px-8 sticky top-0 z-10">
      <div className="flex items-center gap-4 flex-1">
        <div className="relative max-w-md w-full group">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 w-4 h-4 group-focus-within:text-cyan-400 transition-colors" />
          <input
            type="text"
            placeholder="Search rules, assets, or transactions..."
            className="w-full bg-slate-900/50 border border-slate-800 rounded-xl py-2.5 pl-11 pr-4 text-sm focus:outline-none focus:ring-1 focus:ring-cyan-400/50 focus:bg-slate-900 transition-all font-mono"
          />
          <div className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1">
            <kbd className="px-1.5 py-0.5 rounded border border-slate-700 bg-slate-800 text-[10px] font-sans text-slate-500">⌘</kbd>
            <kbd className="px-1.5 py-0.5 rounded border border-slate-700 bg-slate-800 text-[10px] font-sans text-slate-500">K</kbd>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-6">
        <div className="flex items-center gap-3 px-4 py-2 rounded-xl bg-slate-900/50 border border-slate-800 shadow-inner">
          <div className={`w-2 h-2 rounded-full ${dotColor} shadow-[0_0_8px_currentColor]`} />
          <span className="text-xs font-mono uppercase tracking-widest text-slate-300">{statusLabel}</span>
        </div>

        <div className="flex items-center gap-4 text-slate-400">
          <button className="hover:text-white transition-colors relative" aria-label="Notifications">
            <Bell size={20} />
            <span className="absolute top-0 right-0 w-2 h-2 bg-rose-500 rounded-full border border-slate-950" />
          </button>
          <button className="hover:text-white transition-colors" aria-label="Settings">
            <Settings size={20} />
          </button>
        </div>

        <div className="h-8 w-px bg-slate-800" />

        {isConnected ? (
          <button
            onClick={() => disconnect()}
            className="rounded-xl border border-cyan-400/30 bg-cyan-400/10 px-4 py-2 text-sm font-semibold text-cyan-300 transition hover:bg-cyan-400/20"
          >
            <span className="mr-2 text-xs text-slate-400">{chain?.name ?? 'Unknown chain'}</span>
            {accountLabel}
          </button>
        ) : (
          <button
            onClick={() => injectedConnector && connect({ connector: injectedConnector })}
            disabled={!injectedConnector || isPending}
            className="rounded-xl bg-cyan-400 px-4 py-2 text-sm font-semibold text-black transition hover:bg-cyan-300 disabled:cursor-not-allowed disabled:bg-slate-700 disabled:text-slate-400"
          >
            {isPending ? 'Connecting...' : 'Connect Wallet'}
          </button>
        )}
      </div>
    </header>
  );
}
