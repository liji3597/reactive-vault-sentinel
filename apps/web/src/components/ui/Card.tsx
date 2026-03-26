'use client';

import { ReactNode } from 'react';
import { clsx } from 'clsx';
import { motion } from 'framer-motion';

interface CardProps {
  children: ReactNode;
  className?: string;
  variant?: 'default' | 'cyan' | 'emerald' | 'amber';
  animate?: boolean;
  withScan?: boolean;
}

export default function Card({ 
  children, 
  className, 
  variant = 'default',
  animate = true,
  withScan = false
}: CardProps) {
  const variants = {
    default: 'bg-slate-900 border-slate-800',
    cyan: 'bg-slate-900 border-cyan-400/20 shadow-cyan-glow',
    emerald: 'bg-slate-900 border-emerald-400/20 shadow-emerald-glow',
    amber: 'bg-slate-900 border-amber-400/20 shadow-amber-glow',
  };

  return (
    <motion.div
      initial={animate ? { opacity: 0, y: 10 } : false}
      animate={animate ? { opacity: 1, y: 0 } : false}
      className={clsx(
        "rounded-2xl border p-6 relative overflow-hidden transition-all",
        variants[variant],
        className
      )}
    >
      {withScan && (
        <div className="absolute inset-0 pointer-events-none z-0">
          <div className="w-full h-px bg-cyan-400/20 absolute top-0 animate-scan shadow-[0_0_10px_rgba(34,211,238,0.5)]" />
        </div>
      )}
      
      <div className="relative z-10">
        {children}
      </div>
    </motion.div>
  );
}
