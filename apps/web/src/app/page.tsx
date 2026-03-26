'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Shield, TrendingUp, AlertTriangle, Clock, ArrowRight } from 'lucide-react';
import PositionCard from '@/components/dashboard/PositionCard';
import RulesSummary from '@/components/dashboard/RulesSummary';
import EventFeed from '@/components/dashboard/EventFeed';
import StatCard from '@/components/dashboard/StatCard';
import { useRules } from '@/hooks/useRules';
import { useReactiveTrace } from '@/hooks/useReactiveTrace';

export default function Dashboard() {
  const { mode, rules } = useRules();
  const { events } = useReactiveTrace();

  const activeRules = rules.filter((rule) => rule.status === 'Active').length;
  const triggeredToday = events.filter((event) => event.type === 'Triggered').length;
  const lastAction = events[0]?.time ?? 'No events';
  const statusLabel = mode === 'demo' ? 'Demo' : 'Online';
  const statusColor = mode === 'demo' ? 'amber' : 'emerald';

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <section className="relative overflow-hidden rounded-3xl bg-slate-900 border border-slate-800 p-8 md:p-12 shadow-2xl group">
        {/* Animated Background Scan Line */}
        <div className="absolute inset-0 pointer-events-none z-0">
          <div className="w-full h-[2px] bg-cyan-400/20 absolute top-0 animate-scan shadow-[0_0_20px_#22d3ee] opacity-30" />
        </div>
        
        <div className="relative z-10">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-400/10 border border-cyan-400/20 text-cyan-400 text-[10px] font-mono mb-6 tracking-widest uppercase"
          >
            <div className="w-1.5 h-1.5 rounded-full bg-cyan-400 animate-pulse shadow-[0_0_8px_#22d3ee]" />
            {mode === 'demo' ? 'SAFE DEMO MODE' : 'CROSS-CHAIN SENTINEL ACTIVE'}
          </motion.div>
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-6xl font-bold mb-4 bg-gradient-to-r from-white via-slate-100 to-slate-500 bg-clip-text text-transparent tracking-tight"
          >
            Vault Sentinel
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-lg md:text-xl text-slate-400 max-w-2xl mb-10 leading-relaxed font-light"
          >
            Autonomous cross-chain risk management. Protecting your assets with event-driven logic executed by the <span className="text-cyan-400 font-medium">Reactive Network</span>.
          </motion.p>
          <div className="flex flex-wrap gap-4">
            <Link
              href="/rules"
              className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-cyan-400 text-black font-bold hover:bg-cyan-300 transition-all group shadow-cyan-glow hover:scale-105 active:scale-95"
            >
              Configure Sentinel
              <ArrowRight size={20} className="group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link
              href="/trace"
              className="flex items-center gap-3 px-8 py-4 rounded-2xl bg-slate-800 text-white font-bold hover:bg-slate-700 transition-all border border-slate-700 hover:border-slate-600"
            >
              View Live Trace
            </Link>
          </div>
        </div>

        <div className="absolute right-0 top-0 w-1/3 h-full overflow-hidden pointer-events-none opacity-20 group-hover:opacity-30 transition-opacity">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-80 h-80 border-2 border-cyan-400/20 rounded-full animate-ping opacity-20" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 border border-cyan-400/30 rounded-full animate-pulse opacity-40" />
          <Shield className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-cyan-400 w-48 h-48 drop-shadow-[0_0_20px_rgba(34,211,238,0.5)]" />
        </div>
        
        {/* Subtle noise/grid pattern */}
        <div className="absolute inset-0 bg-[url('/grid.svg')] bg-center opacity-[0.03] pointer-events-none" />
      </section>

      {mode === 'demo' && (
        <section className="rounded-2xl border border-amber-500/30 bg-amber-500/10 px-5 py-4 text-sm text-amber-100">
          Contracts are not configured yet. The dashboard is running in safe demo mode with simulated rules, events, and cross-chain execution traces.
        </section>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard label="Total Rules" value={String(rules.length)} icon={Shield} color="cyan" />
        <StatCard label="Active Status" value={statusLabel} icon={TrendingUp} color={statusColor} pulse={mode !== 'demo'} />
        <StatCard label="Triggered Today" value={String(triggeredToday)} icon={AlertTriangle} color="amber" />
        <StatCard label="Last Action" value={lastAction} icon={Clock} color="slate" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-8">
          <section>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Positions Overview</h2>
              <span className="text-cyan-400 text-sm">{activeRules} active protections</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <PositionCard chain="Sepolia" balance="12.45 ETH" value="$45,210" health={98} />
              <PositionCard chain="Base Sepolia" balance="8,540 USDC" value="$8,540" health={100} />
            </div>
          </section>

          <section>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Active Sentinel Rules</h2>
              <Link href="/rules" className="text-cyan-400 text-sm hover:underline">
                Configure
              </Link>
            </div>
            <RulesSummary rules={rules} />
          </section>
        </div>

        <div className="space-y-8">
          <section>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Live Event Feed</h2>
              <Link href="/trace" className="text-cyan-400 text-sm hover:underline">
                Open Trace
              </Link>
            </div>
            <EventFeed events={events} />
          </section>
        </div>
      </div>
    </div>
  );
}
