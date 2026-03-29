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
  trend?: string;
  trendUp?: boolean;
}

export default function StatCard({
  label,
  value,
  icon: Icon,
  color,
  pulse,
  trend,
  trendUp = true,
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
      className="group relative overflow-hidden h-full"
    >
      <div className="flex items-center gap-4 mb-3">
        <div className={`p-2 rounded-lg transition-transform group-hover:scale-110 ${colorMap[color]}`}>
          <Icon size={18} />
        </div>
        <span className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">{label}</span>
      </div>
      <div className="flex items-baseline justify-between gap-2">
        <span className="text-2xl md:text-3xl font-bold font-mono tracking-tight">{value}</span>
        {trend && (
          <div className={`text-[10px] font-bold px-2 py-0.5 rounded ${
            trendUp ? 'bg-emerald-400/10 text-emerald-400' : 'bg-rose-500/10 text-rose-500'
          }`}>
            {trendUp ? '↑' : '↓'} {trend}
          </div>
        )}
        {pulse && !trend && (
          <div className="flex items-center gap-1.5 ml-auto">
            <span className="text-[10px] text-emerald-400 font-mono animate-pulse-slow">LIVE</span>
            <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
          </div>
        )}
      </div>
      
      {/* Decorative cyber corner */}
      <div className="absolute bottom-0 right-0 w-6 h-6 opacity-20 pointer-events-none group-hover:opacity-40 transition-opacity">
        <div className={`absolute bottom-0 right-0 w-2 h-2 border-r border-b ${colorMap[color].split(' ')[0]}`} />
        <div className={`absolute bottom-1 right-1 w-1 h-1 border-r border-b opacity-50 ${colorMap[color].split(' ')[0]}`} />
      </div>
    </Card>
  );
}
