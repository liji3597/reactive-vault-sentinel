'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Bell, Search, Settings } from 'lucide-react';
import { appMode } from '@/lib/contracts';

export default function TopBar() {
  const statusLabel = appMode === 'demo' ? 'Sentinel Demo Mode' : 'Sentinel Online';
  const dotColor = appMode === 'demo' ? 'bg-amber-400' : 'bg-emerald-400';

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
          <button className="hover:text-white transition-colors relative">
            <Bell size={20} />
            <span className="absolute top-0 right-0 w-2 h-2 bg-rose-500 rounded-full border border-slate-950" />
          </button>
          <button className="hover:text-white transition-colors">
            <Settings size={20} />
          </button>
        </div>

        <div className="h-8 w-px bg-slate-800" />

        <ConnectButton showBalance={false} chainStatus="icon" accountStatus="full" />
      </div>
    </header>
  );
}
