'use client';

import { Pause, Play, Settings2, Trash2 } from 'lucide-react';
import { DEFAULT_DEMO_RULES, type DemoRule } from '@/lib/demoData';

export default function RulesSummary({
  rules = DEFAULT_DEMO_RULES,
  onToggleRule,
  onRemoveRule,
}: {
  rules?: DemoRule[];
  onToggleRule?: (ruleId: number) => void;
  onRemoveRule?: (ruleId: number) => void;
}) {
  return (
    <div className="space-y-4">
      {rules.length === 0 ? (
        <div className="p-8 text-center rounded-xl bg-slate-900/50 border border-dashed border-slate-800">
          <p className="text-xs text-slate-500 font-mono italic">No rules configured yet.</p>
        </div>
      ) : (
        rules.map((rule) => (
          <div
            key={rule.id}
            className="p-5 rounded-xl bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all flex items-center justify-between gap-4 group"
          >
            <div className="flex items-center gap-4 min-w-0">
              <div
                className={`w-3 h-3 rounded-full ${
                  rule.status === 'Active' ? 'bg-emerald-400 animate-pulse' : 'bg-slate-500'
                }`}
              />
              <div className="min-w-0">
                <div className="font-semibold truncate">{rule.name}</div>
                <div className="text-xs text-slate-500 font-mono truncate">
                  {rule.type} | Threshold: {rule.threshold}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
              <button className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-all">
                <Settings2 size={16} />
              </button>
              <button 
                onClick={() => onToggleRule?.(rule.id)}
                className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-all"
              >
                {rule.status === 'Active' ? <Pause size={16} /> : <Play size={16} />}
              </button>
              <button 
                onClick={() => onRemoveRule?.(rule.id)}
                className="p-2 rounded-lg bg-slate-800 text-slate-400 hover:text-rose-500 hover:bg-rose-500/10 transition-all"
              >
                <Trash2 size={16} />
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  );
}
