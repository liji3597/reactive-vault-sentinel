'use client';

import { motion } from 'framer-motion';
import { Wallet, ExternalLink, Activity } from 'lucide-react';

interface PositionCardProps {
  chain: string;
  balance: string;
  value: string;
  health: number;
}

export default function PositionCard({ chain, balance, value, health }: PositionCardProps) {
  return (
    <motion.div 
      whileHover={{ y: -4 }}
      className="p-6 rounded-2xl bg-slate-900 border border-slate-800 relative overflow-hidden group"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-slate-800 group-hover:bg-slate-700 transition-colors">
            <Wallet size={20} className="text-slate-400" />
          </div>
          <div>
            <div className="text-xs font-mono text-slate-500">{chain}</div>
            <div className="font-bold">{balance}</div>
          </div>
        </div>
        <button className="p-2 text-slate-500 hover:text-white transition-colors">
          <ExternalLink size={18} />
        </button>
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-500">Portfolio Value</span>
          <span className="font-mono">{value}</span>
        </div>
        
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-500">Position Health</span>
            <span className={health < 90 ? 'text-amber-400' : 'text-emerald-400'}>{health}%</span>
          </div>
          <div className="h-2 w-full bg-slate-800 rounded-full overflow-hidden">
            <motion.div 
              initial={{ width: 0 }}
              animate={{ width: `${health}%` }}
              transition={{ duration: 1, ease: "easeOut" }}
              className={`h-full rounded-full ${health < 90 ? 'bg-amber-400' : 'bg-emerald-400'}`}
            />
          </div>
        </div>
      </div>

      {/* Decorative pulse when healthy */}
      {health > 95 && (
        <div className="absolute -right-4 -top-4 w-24 h-24 bg-emerald-400/5 blur-3xl rounded-full" />
      )}
    </motion.div>
  );
}
