'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { Bell, Search, Settings } from 'lucide-react';

export default function TopBar() {
  const { isConnected, address } = useAccount();

  return (
    <header className="h-20 border-b border-slate-800 bg-slate-950/80 backdrop-blur-md flex items-center justify-between px-8 sticky top-0 z-10">
      <div className="flex items-center gap-4 flex-1">
        <div className="relative max-w-md w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 w-4 h-4" />
          <input 
            type="text" 
            placeholder="Search rules, assets, or transactions..." 
            className="w-full bg-slate-900 border border-slate-800 rounded-full py-2 pl-10 pr-4 text-sm focus:outline-none focus:ring-1 focus:ring-cyan-400/50 transition-all"
          />
        </div>
      </div>

      <div className="flex items-center gap-6">
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-900 border border-slate-800">
          <div className="w-2 h-2 rounded-full bg-emerald-400" />
          <span className="text-xs font-medium text-slate-300">Sentinel Online</span>
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

        <ConnectButton 
          showBalance={false}
          chainStatus="icon"
          accountStatus="full"
        />
      </div>
    </header>
  );
}
