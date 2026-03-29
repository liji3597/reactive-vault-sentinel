'use client';

import { RefreshCw, Play, Square, History } from 'lucide-react';
import CrossChainMap from '@/components/trace/CrossChainMap';
import { useReactiveTrace } from '@/hooks/useReactiveTrace';
import type { TraceLog } from '@/lib/demoData';

export default function TracePage() {
  const { mode, activePhase, isLive, setIsLive, lastUpdate, logs } = useReactiveTrace();

  return (
    <div className="space-y-8 max-w-[1600px] mx-auto">
      {mode === 'demo' && (
        <section className="rounded-2xl border border-amber-500/30 bg-amber-500/10 px-5 py-4 text-sm text-amber-100">
          Showing a simulated cross-chain execution trace. No on-chain polling runs until real contract addresses are configured.
        </section>
      )}

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold mb-2 flex items-center gap-3">
            Sentinel Live Trace
            {isLive && (
              <span className="flex h-3 w-3 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-3 w-3 bg-cyan-500" />
              </span>
            )}
          </h1>
          <p className="text-slate-400">
            {mode === 'demo'
              ? 'Demo replay of the full Sepolia → ReactVM → Base Sepolia lifecycle.'
              : 'Real-time visualization of cross-chain reactive execution.'}
          </p>
        </div>

        <div className="flex items-center gap-3 flex-wrap">
          <div className="flex items-center gap-2 px-4 py-2 rounded-xl bg-slate-900 border border-slate-800 text-xs font-mono text-slate-500">
            <RefreshCw size={14} className={isLive ? 'animate-spin' : ''} />
            Last Updated: {lastUpdate.toLocaleTimeString()}
          </div>
          <div className="h-10 w-px bg-slate-800 mx-2 hidden md:block" />
          <button
            onClick={() => setIsLive(!isLive)}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl font-bold transition-all ${
              isLive
                ? 'bg-rose-500/10 text-rose-500 hover:bg-rose-500/20'
                : 'bg-emerald-500/10 text-emerald-500 hover:bg-emerald-500/20'
            }`}
          >
            {isLive ? <Square size={18} /> : <Play size={18} />}
            {isLive ? 'Stop Replay' : 'Resume Replay'}
          </button>
          <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-slate-800 text-white font-bold hover:bg-slate-700 transition-all">
            <History size={18} />
            History
          </button>
        </div>
      </div>

      <div className="bg-slate-900/50 border border-slate-800 rounded-3xl p-8 min-h-[600px] relative overflow-hidden">
        <div
          className="absolute inset-0 opacity-10 pointer-events-none"
          style={{
            backgroundImage: 'radial-gradient(#22d3ee 1px, transparent 1px)',
            backgroundSize: '40px 40px',
          }}
        />

        <CrossChainMap activePhase={activePhase} />
      </div>

      <section className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex items-center justify-between bg-slate-900/50">
          <h2 className="font-bold text-lg">Execution Logs</h2>
          <div className="text-xs text-slate-500 uppercase font-mono tracking-widest">
            {mode === 'demo' ? 'Simulated Stream' : 'Real-time Stream'}
          </div>
        </div>
        <div className="p-6 font-mono text-xs space-y-3 max-h-64 overflow-y-auto">
          {logs.map((entry, index) => (
            <LogEntry key={`${entry.time}-${index}`} {...entry} />
          ))}
        </div>
      </section>
    </div>
  );
}

function LogEntry({ time, chain, msg, type }: TraceLog) {
  const colors: Record<TraceLog['type'], string> = {
    info: 'text-slate-400',
    warning: 'text-amber-400',
    process: 'text-cyan-400',
    success: 'text-emerald-400',
  };

  const bgColors: Record<TraceLog['type'], string> = {
    info: 'bg-slate-400/5',
    warning: 'bg-amber-400/5',
    process: 'bg-cyan-400/5',
    success: 'bg-emerald-400/5',
  };

  const borderColors: Record<TraceLog['type'], string> = {
    info: 'border-slate-800',
    warning: 'border-amber-400/10',
    process: 'border-cyan-400/10',
    success: 'border-emerald-400/10',
  };

  return (
    <div className={`flex items-start gap-4 p-3 rounded-lg border group transition-all hover:translate-x-1 ${bgColors[type]} ${borderColors[type]}`}>
      <span className="text-[10px] text-slate-600 shrink-0 font-mono mt-0.5">{time}</span>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className="text-[10px] uppercase font-bold text-slate-500 tracking-wider">
            {chain}
          </span>
          <div className={`w-1 h-1 rounded-full ${colors[type].replace('text-', 'bg-')}`} />
        </div>
        <div className={`text-xs leading-relaxed ${colors[type]}`}>
          {msg}
        </div>
      </div>
      <button 
        className="opacity-0 group-hover:opacity-100 transition-opacity p-1.5 rounded-md hover:bg-slate-800 text-slate-500 hover:text-cyan-400"
        title="Copy transaction hash"
        onClick={() => {
          // In a real app, this would copy to clipboard
          console.log('Copying TX from chain:', chain);
        }}
      >
        <History size={14} />
      </button>
    </div>
  );
}
