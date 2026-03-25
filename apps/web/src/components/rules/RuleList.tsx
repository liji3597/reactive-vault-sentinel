'use client';

import { motion } from 'framer-motion';
import { Power, Settings, ExternalLink, Activity, Info } from 'lucide-react';

const mockRules = [
  { id: 1, name: 'ETH Depeg Guardian', type: 'PriceBelow', threshold: '3400 USD', status: 'Active', chain: 'Sepolia', target: 'Base Sepolia', health: 'Healthy' },
  { id: 2, name: 'Balance Refill', type: 'TransferOutflow', threshold: '2.5 ETH', status: 'Active', chain: 'Sepolia', target: 'Base Sepolia', health: 'Healthy' },
  { id: 3, name: 'Stop Loss - WBTC', type: 'PriceBelow', threshold: '62000 USD', status: 'Paused', chain: 'Sepolia', target: 'Base Sepolia', health: 'Idle' },
];

export default function RuleList() {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        <thead>
          <tr className="border-b border-slate-800 text-slate-500 text-sm font-medium">
            <th className="text-left py-4 px-6">Rule Name</th>
            <th className="text-left py-4 px-6">Type / Threshold</th>
            <th className="text-left py-4 px-6">Routing</th>
            <th className="text-left py-4 px-6">Health</th>
            <th className="text-right py-4 px-6">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {mockRules.map((rule) => (
            <motion.tr 
              key={rule.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="hover:bg-slate-900/50 transition-colors group"
            >
              <td className="py-6 px-6">
                <div className="flex items-center gap-3">
                  <div className={`w-2 h-2 rounded-full ${rule.status === 'Active' ? 'bg-emerald-400 shadow-[0_0_8px_rgba(52,211,153,0.5)]' : 'bg-slate-600'}`} />
                  <div>
                    <div className="font-bold text-white">{rule.name}</div>
                    <div className="text-[10px] text-slate-500 font-mono">ID: SENTINEL-{rule.id}</div>
                  </div>
                </div>
              </td>
              <td className="py-6 px-6">
                <div>
                  <div className="text-sm font-semibold">{rule.type}</div>
                  <div className="text-xs text-slate-400 font-mono">{rule.threshold}</div>
                </div>
              </td>
              <td className="py-6 px-6">
                <div className="flex items-center gap-2">
                  <span className="text-xs px-2 py-0.5 rounded bg-slate-800 border border-slate-700 text-slate-400">{rule.chain}</span>
                  <ChevronRight size={12} className="text-slate-600" />
                  <span className="text-xs px-2 py-0.5 rounded bg-cyan-400/10 border border-cyan-400/20 text-cyan-400">{rule.target}</span>
                </div>
              </td>
              <td className="py-6 px-6">
                <div className="flex items-center gap-2 text-xs">
                  <Activity size={14} className={rule.status === 'Active' ? 'text-emerald-400' : 'text-slate-600'} />
                  <span className={rule.status === 'Active' ? 'text-emerald-400' : 'text-slate-500'}>{rule.health}</span>
                </div>
              </td>
              <td className="py-6 px-6">
                <div className="flex items-center justify-end gap-3 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white transition-all"><Settings size={18} /></button>
                  <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-emerald-400 transition-all"><Power size={18} /></button>
                  <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-cyan-400 transition-all"><ExternalLink size={18} /></button>
                </div>
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ChevronRight({ size, className }: any) {
  return (
    <svg 
      width={size} 
      height={size} 
      viewBox="0 0 24 24" 
      fill="none" 
      stroke="currentColor" 
      strokeWidth="2" 
      strokeLinecap="round" 
      strokeLinejoin="round" 
      className={className}
    >
      <path d="m9 18 6-6-6-6"/>
    </svg>
  );
}
