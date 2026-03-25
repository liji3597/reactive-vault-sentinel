'use client';

import { Play, Pause, Trash2, Settings2 } from 'lucide-react';

const mockRules = [
  { id: 1, name: 'ETH Depeg Guardian', type: 'PriceBelow', threshold: '3400 USD', status: 'Active', color: 'emerald' },
  { id: 2, name: 'Balance Refill', type: 'TransferOutflow', threshold: '2.5 ETH', status: 'Active', color: 'emerald' },
  { id: 3, name: 'Stop Loss - WBTC', type: 'PriceBelow', threshold: '62000 USD', status: 'Paused', color: 'slate' },
];

export default function RulesSummary() {
  return (
    <div className="space-y-4">
      {mockRules.map((rule) => (
        <div 
          key={rule.id}
          className="p-5 rounded-xl bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all flex items-center justify-between"
        >
          <div className="flex items-center gap-4">
            <div className={`w-3 h-3 rounded-full bg-${rule.color}-400 ${rule.status === 'Active' ? 'animate-pulse' : ''}`} />
            <div>
              <div className="font-semibold">{rule.name}</div>
              <div className="text-xs text-slate-500 font-mono">
                {rule.type} | Threshold: {rule.threshold}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-all">
              <Settings2 size={18} />
            </button>
            <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-all">
              {rule.status === 'Active' ? <Pause size={18} /> : <Play size={18} />}
            </button>
            <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-rose-500 hover:bg-rose-500/10 transition-all">
              <Trash2 size={18} />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
