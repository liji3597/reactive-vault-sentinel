'use client';

import { motion } from 'framer-motion';
import { Wallet, ExternalLink, Activity } from 'lucide-react';
import Card from '@/components/ui/Card';

interface PositionCardProps {
  chain: string;
  balance: string;
  value: string;
  health: number;
}

export default function PositionCard({ chain, balance, value, health }: PositionCardProps) {
  const isHealthy = health > 95;
  const variant = health < 90 ? 'amber' : isHealthy ? 'emerald' : 'default';

  return (
    <Card 
      variant={variant}
      withScan={!isHealthy}
      className="group"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg transition-colors ${
            isHealthy ? 'bg-emerald-400/10 text-emerald-400' : 'bg-slate-800 text-slate-400'
          }`}>
            <Wallet size={20} />
          </div>
          <div>
            <div className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">{chain}</div>
            <div className="font-bold text-lg">{balance}</div>
          </div>
        </div>
        <button className="p-2 text-slate-500 hover:text-white transition-colors">
          <ExternalLink size={18} />
        </button>
      </div>

      <div className="space-y-4">
        <div className="flex items-center justify-between text-sm">
          <span className="text-slate-500">Portfolio Value</span>
          <span className="font-mono font-semibold">{value}</span>
        </div>
        
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-500">Protection Health</span>
            <div className="flex items-center gap-2">
              {isHealthy && <Activity size={14} className="text-emerald-400 animate-pulse" />}
              <span className={health < 90 ? 'text-amber-400' : 'text-emerald-400'}>{health}%</span>
            </div>
          </div>
          <div className="h-2 w-full bg-slate-800 rounded-full overflow-hidden p-0.5">
            <motion.div 
              initial={{ width: 0 }}
              animate={{ width: `${health}%` }}
              transition={{ duration: 1.5, ease: "easeOut" }}
              className={`h-full rounded-full ${
                health < 90 ? 'bg-amber-400 shadow-[0_0_10px_rgba(251,191,36,0.5)]' : 'bg-emerald-400 shadow-[0_0_10px_rgba(52,211,153,0.5)]'
              }`}
            />
          </div>
        </div>
      </div>

      {/* Decorative pulse when healthy */}
      {isHealthy && (
        <div className="absolute -right-4 -top-4 w-24 h-24 bg-emerald-400/5 blur-3xl rounded-full animate-pulse-slow" />
      )}
    </Card>
  );
}
