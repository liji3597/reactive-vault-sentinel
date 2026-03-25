'use client';

import { motion } from 'framer-motion';
import { Shield, TrendingUp, AlertTriangle, Clock, ArrowRight } from 'lucide-react';
import PositionCard from '@/components/dashboard/PositionCard';
import RulesSummary from '@/components/dashboard/RulesSummary';
import EventFeed from '@/components/dashboard/EventFeed';

export default function Dashboard() {
  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Hero Section */}
      <section className="relative overflow-hidden rounded-3xl bg-slate-900 border border-slate-800 p-8 md:p-12">
        <div className="relative z-10">
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-400/10 border border-cyan-400/20 text-cyan-400 text-xs font-mono mb-6"
          >
            <Shield size={14} />
            CROSS-CHAIN SENTINEL ACTIVE
          </motion.div>
          <motion.h1 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-4xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-white to-slate-400 bg-clip-text text-transparent"
          >
            Reactive Vault Sentinel
          </motion.h1>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="text-lg text-slate-400 max-w-2xl mb-8"
          >
            Autonomous cross-chain risk management. Protecting your assets with event-driven logic executed by the Reactive Network.
          </motion.p>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center gap-3 px-6 py-3 rounded-xl bg-cyan-400 text-black font-semibold hover:bg-cyan-300 transition-colors cursor-pointer group">
              Configure New Rule
              <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
            </div>
            <div className="flex items-center gap-3 px-6 py-3 rounded-xl bg-slate-800 text-white font-semibold hover:bg-slate-700 transition-colors cursor-pointer">
              View Live Trace
            </div>
          </div>
        </div>

        {/* Animated Background Elements */}
        <div className="absolute right-0 top-0 w-1/3 h-full overflow-hidden pointer-events-none opacity-20">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 border border-cyan-400 rounded-full animate-ping opacity-20" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 border border-cyan-400 rounded-full animate-pulse opacity-40" />
          <Shield className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-cyan-400 w-32 h-32" />
        </div>
      </section>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard label="Total Rules" value="12" icon={Shield} color="cyan" />
        <StatCard label="Active Status" value="Online" icon={TrendingUp} color="emerald" pulse />
        <StatCard label="Triggered Today" value="3" icon={AlertTriangle} color="amber" />
        <StatCard label="Last Action" value="4m ago" icon={Clock} color="slate" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Content Area */}
        <div className="lg:col-span-2 space-y-8">
          <section>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Positions Overview</h2>
              <button className="text-cyan-400 text-sm hover:underline">Manage All</button>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <PositionCard chain="Sepolia" balance="12.45 ETH" value="$45,210" health={98} />
              <PositionCard chain="Base Sepolia" balance="8,540 USDC" value="$8,540" health={100} />
            </div>
          </section>

          <section>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Active Sentinel Rules</h2>
              <button className="text-cyan-400 text-sm hover:underline">Configure</button>
            </div>
            <RulesSummary />
          </section>
        </div>

        {/* Sidebar Area */}
        <div className="space-y-8">
          <section>
            <h2 className="text-2xl font-bold mb-6">Live Event Feed</h2>
            <EventFeed />
          </section>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon: Icon, color, pulse }: any) {
  const colors: any = {
    cyan: "text-cyan-400 bg-cyan-400/10 border-cyan-400/20",
    emerald: "text-emerald-400 bg-emerald-400/10 border-emerald-400/20",
    amber: "text-amber-400 bg-amber-400/10 border-amber-400/20",
    slate: "text-slate-400 bg-slate-400/10 border-slate-400/20",
  };

  return (
    <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800">
      <div className="flex items-center gap-4 mb-3">
        <div className={`p-2 rounded-lg ${colors[color]}`}>
          <Icon size={20} />
        </div>
        <span className="text-slate-500 text-sm font-medium">{label}</span>
      </div>
      <div className="flex items-baseline gap-2">
        <span className="text-3xl font-bold">{value}</span>
        {pulse && <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />}
      </div>
    </div>
  );
}
