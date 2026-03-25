'use client';

import { motion } from 'framer-motion';
import { Zap, CheckCircle2, AlertCircle } from 'lucide-react';

const mockEvents = [
  { id: 1, type: 'Triggered', rule: 'ETH Depeg Guardian', time: '2m ago', status: 'Processing', tx: '0x4a...c23e' },
  { id: 2, type: 'Executed', rule: 'Balance Refill', time: '14m ago', status: 'Success', tx: '0x8b...f912' },
  { id: 3, type: 'Warning', rule: 'Stop Loss WBTC', time: '1h ago', status: 'Approaching', tx: '0x12...a34d' },
  { id: 4, type: 'Executed', rule: 'ETH Depeg Guardian', time: '4h ago', status: 'Success', tx: '0x9d...e56c' },
];

export default function EventFeed() {
  return (
    <div className="space-y-4">
      {mockEvents.map((event, idx) => (
        <motion.div 
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: idx * 0.1 }}
          key={event.id}
          className="p-4 rounded-xl bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all group"
        >
          <div className="flex items-start gap-4">
            <div className="mt-1">
              {event.type === 'Triggered' && <Zap size={18} className="text-amber-400" />}
              {event.type === 'Executed' && <CheckCircle2 size={18} className="text-emerald-400" />}
              {event.type === 'Warning' && <AlertCircle size={18} className="text-rose-500" />}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between mb-1">
                <span className="font-semibold text-sm truncate pr-2">{event.rule}</span>
                <span className="text-[10px] text-slate-500 whitespace-nowrap">{event.time}</span>
              </div>
              <div className="flex items-center justify-between">
                <div className="text-xs text-slate-400 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-cyan-400" />
                  {event.status}
                </div>
                <div className="text-[10px] font-mono text-slate-500 group-hover:text-cyan-400 transition-colors cursor-pointer">
                  {event.tx}
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      ))}
      
      <button className="w-full py-3 rounded-xl border border-dashed border-slate-800 text-slate-500 text-xs hover:text-slate-400 hover:border-slate-700 transition-all">
        View All History
      </button>
    </div>
  );
}
