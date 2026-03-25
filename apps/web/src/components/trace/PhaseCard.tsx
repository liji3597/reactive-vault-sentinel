'use client';

import { motion } from 'framer-motion';
import { Shield, Zap, Database, CheckCircle2, Loader2, Link2 } from 'lucide-react';
import { clsx } from 'clsx';

interface PhaseCardProps {
  phase: 1 | 2 | 3;
  title: string;
  status: 'idle' | 'triggering' | 'processing' | 'executing' | 'completed';
  details: string;
  txHash: string;
  isActive: boolean;
}

export default function PhaseCard({ phase, title, status, details, txHash, isActive }: PhaseCardProps) {
  const getIcon = () => {
    if (status === 'completed') return <CheckCircle2 className="text-emerald-400" />;
    if (status === 'idle') {
      if (phase === 1) return <Shield className="text-slate-600" />;
      if (phase === 2) return <Zap className="text-slate-600" />;
      return <Database className="text-slate-600" />;
    }
    return <Loader2 className="animate-spin text-cyan-400" />;
  };

  return (
    <motion.div 
      animate={{ 
        scale: isActive ? 1.05 : 1,
        borderColor: isActive ? 'rgba(34, 211, 238, 0.5)' : 'rgba(30, 41, 59, 1)'
      }}
      className={clsx(
        "w-full max-w-[280px] p-6 rounded-3xl bg-slate-900 border-2 transition-all relative",
        isActive ? "shadow-cyan-glow z-20" : "z-10"
      )}
    >
      <div className="flex items-center gap-4 mb-6">
        <div className={clsx(
          "w-12 h-12 rounded-2xl flex items-center justify-center transition-colors",
          isActive ? "bg-cyan-400/20" : "bg-slate-800"
        )}>
          {getIcon()}
        </div>
        <div>
          <div className="font-bold text-lg">{title}</div>
          <div className={clsx(
            "text-[10px] font-mono uppercase tracking-widest",
            isActive ? "text-cyan-400" : "text-slate-500"
          )}>
            Phase 0{phase}
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <div className="p-3 rounded-xl bg-slate-950/50 border border-slate-800">
          <div className="text-[10px] text-slate-500 uppercase mb-1">Status</div>
          <div className="text-sm font-medium">{details}</div>
        </div>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-[10px] font-mono text-slate-500">
            <Link2 size={12} />
            {txHash}
          </div>
          <button className="text-[10px] text-cyan-400 hover:underline">View</button>
        </div>
      </div>

      {isActive && (
        <motion.div 
          layoutId="glow-ring"
          className="absolute inset-0 rounded-3xl border border-cyan-400/30 -m-[1px]"
          animate={{ opacity: [0.3, 0.6, 0.3] }}
          transition={{ repeat: Infinity, duration: 2 }}
        />
      )}
    </motion.div>
  );
}
