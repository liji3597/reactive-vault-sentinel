'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, ShieldCheck, Activity, Menu, X } from 'lucide-react';
import { useState } from 'react';
import { clsx } from 'clsx';

const navItems = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Rules', href: '/rules', icon: ShieldCheck },
  { name: 'Live Trace', href: '/trace', icon: Activity },
];

export default function Sidebar() {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside className={clsx(
      "bg-slate-900 border-r border-slate-800 transition-all duration-300 flex flex-col",
      collapsed ? "w-20" : "w-64"
    )}>
      <div className="p-6 flex items-center justify-between border-b border-slate-800">
        {!collapsed && (
          <div className="flex items-center gap-2 font-bold text-xl tracking-tight text-white">
            <ShieldCheck className="text-cyan-400 w-8 h-8" />
            <span>SENTINEL</span>
          </div>
        )}
        {collapsed && (
          <ShieldCheck className="text-cyan-400 w-8 h-8 mx-auto" />
        )}
        <button 
          onClick={() => setCollapsed(!collapsed)}
          className="p-1 hover:bg-slate-800 rounded transition-colors"
        >
          {collapsed ? <Menu size={20} /> : <X size={20} />}
        </button>
      </div>

      <nav className="flex-1 p-4 space-y-2">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={clsx(
                "flex items-center gap-4 p-3 rounded-lg transition-all group relative",
                isActive ? "bg-cyan-400/10 text-cyan-400 shadow-cyan-glow" : "text-slate-400 hover:text-white hover:bg-slate-800"
              )}
            >
              <Icon size={24} className={clsx(isActive ? "text-cyan-400" : "group-hover:text-cyan-400 transition-colors")} />
              {!collapsed && <span className="font-medium">{item.name}</span>}
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-cyan-400 rounded-r-full" />
              )}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t border-slate-800">
        {!collapsed && (
          <div className="p-4 rounded-lg bg-slate-950/50 border border-slate-800">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-xs font-mono text-emerald-400">REACTVM ACTIVE</span>
            </div>
            <p className="text-[10px] text-slate-500 font-mono leading-tight">
              Reactive Network is monitoring your assets cross-chain.
            </p>
          </div>
        )}
      </div>
    </aside>
  );
}
