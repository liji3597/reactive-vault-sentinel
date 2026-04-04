'use client';

import { useState } from 'react';
import { Zap, CheckCircle2, AlertCircle, Check, Copy } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { DEMO_EVENTS, type DemoEvent } from '@/lib/demoData';

export default function EventFeed({ events = DEMO_EVENTS }: { events?: DemoEvent[] }) {
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const handleCopy = (tx: string, id: string) => {
    navigator.clipboard.writeText(tx);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  return (
    <div className="space-y-4 relative">
      <AnimatePresence>
        {copiedId && (
          <motion.div
            initial={{ opacity: 0, y: -20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="fixed top-24 right-8 z-50 flex items-center gap-2 px-4 py-2 rounded-xl bg-cyan-500 text-white text-sm font-bold shadow-cyan-glow"
          >
            <Check size={16} />
            TX Copied
          </motion.div>
        )}
      </AnimatePresence>

      {events.length === 0 ? (
        <div className="p-8 text-center rounded-xl bg-slate-900/50 border border-dashed border-slate-800">
          <p className="text-xs text-slate-500 font-mono">NO RECENT ACTIVITY</p>
        </div>
      ) : (
        events.map((event, index) => (
          <motion.div
            key={event.id}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.1 }}
            className="p-4 rounded-xl bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all group"
          >
            <div className="flex items-start gap-4">
              <div className="mt-1">
                {event.type === 'Triggered' && <Zap size={18} className="text-amber-400" />}
                {event.type === 'Executed' && <CheckCircle2 size={18} className="text-emerald-400" />}
                {event.type === 'Warning' && <AlertCircle size={18} className="text-rose-500" />}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between mb-1 gap-2">
                  <span className="font-semibold text-sm truncate">{event.rule}</span>
                  <span className="text-[10px] text-slate-500 whitespace-nowrap">{event.time}</span>
                </div>
                <div className="flex items-center justify-between gap-2">
                  <div className="text-xs text-slate-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-cyan-400" />
                    {event.status}
                  </div>
                  <button
                    onClick={() => handleCopy(event.tx, String(event.id))}
                    className={`text-[10px] font-mono flex items-center gap-1 transition-all ${
                      copiedId === String(event.id) 
                        ? 'text-emerald-400' 
                        : 'text-slate-500 hover:text-cyan-400'
                    }`}
                  >
                    {copiedId === String(event.id) ? <Check size={10} /> : <Copy size={10} />}
                    {event.tx}
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        ))
      )}

      {events.length > 0 && (
        <button className="w-full py-3 rounded-xl border border-dashed border-slate-800 text-slate-500 text-xs hover:text-slate-400 hover:border-slate-700 transition-all">
          View All History
        </button>
      )}
    </div>
  );
}
