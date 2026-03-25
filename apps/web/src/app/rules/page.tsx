'use client';

import { useState } from 'react';
import RuleWizard from '@/components/rules/RuleWizard';
import RuleList from '@/components/rules/RuleList';
import { Plus } from 'lucide-react';

export default function RulesPage() {
  const [showWizard, setShowWizard] = useState(false);

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold mb-2">Rule Configurator</h1>
          <p className="text-slate-400">Define cross-chain triggers and automated actions for your vault.</p>
        </div>
        <button 
          onClick={() => setShowWizard(!showWizard)}
          className="flex items-center gap-2 px-6 py-3 rounded-xl bg-cyan-400 text-black font-semibold hover:bg-cyan-300 transition-all shadow-cyan-glow"
        >
          {showWizard ? 'Cancel' : (
            <>
              <Plus size={20} />
              New Rule
            </>
          )}
        </button>
      </div>

      {showWizard ? (
        <RuleWizard onComplete={() => setShowWizard(false)} />
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <TemplateCard 
              title="Balance Refill" 
              description="Automatically bridge ETH from Base to Sepolia when balance falls below threshold." 
              onSelect={() => setShowWizard(true)}
            />
            <TemplateCard 
              title="Depeg Guardian" 
              description="Swap correlated assets to stablecoins if price deviation exceeds 2%." 
              onSelect={() => setShowWizard(true)}
            />
            <TemplateCard 
              title="Stop Loss" 
              description="Trigger emergency vault withdrawal if asset price falls below limit." 
              onSelect={() => setShowWizard(true)}
            />
          </div>
          
          <h2 className="text-xl font-bold mt-12 mb-4">Your Active Rules</h2>
          <RuleList />
        </div>
      )}
    </div>
  );
}

function TemplateCard({ title, description, onSelect }: any) {
  return (
    <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 hover:border-cyan-400/50 transition-all cursor-pointer group" onClick={onSelect}>
      <h3 className="font-bold text-lg mb-2 group-hover:text-cyan-400 transition-colors">{title}</h3>
      <p className="text-sm text-slate-400 mb-4">{description}</p>
      <div className="text-xs font-semibold text-cyan-400 uppercase tracking-wider">Use Template</div>
    </div>
  );
}
