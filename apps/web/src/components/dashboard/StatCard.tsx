'use client';

import { LucideIcon } from 'lucide-react';
import Card from '@/components/ui/Card';

type StatCardColor = 'cyan' | 'emerald' | 'amber' | 'slate';

interface StatCardProps {
  label: string;
  value: string;
  icon: LucideIcon;
  color: StatCardColor;
  pulse?: boolean;
}

export default function StatCard({
  label,
  value,
  icon: Icon,
  color,
  pulse,
}: StatCardProps) {
  const colorMap: Record<StatCardColor, string> = {
    cyan: 'text-cyan-400 bg-cyan-400/10 border-cyan-400/20',
    emerald: 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20',
    amber: 'text-amber-400 bg-amber-400/10 border-amber-400/20',
    slate: 'text-slate-400 bg-slate-400/10 border-slate-400/20',
  };

  return (
    <Card 
      variant={color === 'slate' ? 'default' : color} 
      withScan={pulse}
      className="group relative overflow-hidden"
    >
      <div className="flex items-center gap-4 mb-3">
        <div className={`p-2 rounded-lg transition-transform group-hover:scale-110 ${colorMap[color]}`}>
          <Icon size={20} />
        </div>
        <span className="text-slate-500 text-sm font-medium uppercase tracking-wider">{label}</span>
      </div>
      <div className="flex items-baseline gap-2">
        <span className="text-3xl font-bold font-mono tracking-tight">{value}</span>
        {pulse && (
          <div className="flex items-center gap-1.5 ml-auto">
            <span className="text-[10px] text-emerald-400 font-mono animate-pulse-slow">MONITORING</span>
            <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          </div>
        )}
      </div>
      
      {/* Decorative cyber corner */}
      <div className="absolute -bottom-1 -right-1 w-8 h-8 opacity-10">
        <div className={`w-full h-full border-r-2 border-b-2 ${colorMap[color].split(' ')[0]}`} />
      </div>
    </Card>
  );
}
