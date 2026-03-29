'use client';

import { useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Check, ChevronRight, Database, Shield, Zap } from 'lucide-react';
import type { AppMode } from '@/lib/contracts';
import type { DemoRuleType } from '@/lib/demoData';

const steps = [
  { id: 1, name: 'Trigger Source', icon: Shield },
  { id: 2, name: 'Conditions', icon: Zap },
  { id: 3, name: 'Execution', icon: Database },
] as const;

export interface RuleWizardFormData {
  chain: 'sepolia' | 'base-sepolia';
  asset: 'ETH' | 'USDC' | 'WBTC';
  condition: DemoRuleType;
  threshold: string;
  action: 'bridge';
}

export default function RuleWizard({
  mode,
  onComplete,
}: {
  mode: AppMode;
  onComplete: (formData: RuleWizardFormData) => void;
}) {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<RuleWizardFormData>({
    chain: 'sepolia',
    asset: 'ETH',
    condition: 'PriceBelow',
    threshold: '',
    action: 'bridge',
  });

  const nextStep = () => setCurrentStep((prev) => Math.min(prev + 1, 3));
  const prevStep = () => setCurrentStep((prev) => Math.max(prev - 1, 1));

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden shadow-2xl">
      <div className="flex border-b border-slate-800">
        {steps.map((step) => {
          const isActive = currentStep === step.id;
          const isCompleted = currentStep > step.id;

          return (
            <div
              key={step.id}
              className={`flex-1 flex items-center justify-center gap-3 py-6 relative ${
                isActive ? 'bg-slate-800/50' : ''
              }`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center border-2 ${
                  isCompleted
                    ? 'bg-emerald-400 border-emerald-400 text-black'
                    : isActive
                      ? 'border-cyan-400 text-cyan-400'
                      : 'border-slate-700 text-slate-600'
                }`}
              >
                {isCompleted ? <Check size={18} /> : step.id}
              </div>
              <span
                className={`font-semibold hidden md:inline ${
                  isActive ? 'text-white' : 'text-slate-500'
                }`}
              >
                {step.name}
              </span>
              {isActive && (
                <>
                  <motion.div
                    layoutId="step-indicator"
                    className="absolute bottom-0 left-0 right-0 h-1 bg-cyan-400 shadow-[0_0_10px_#22d3ee]"
                  />
                  <div className="absolute inset-0 pointer-events-none overflow-hidden">
                    <div className="w-full h-[1px] bg-cyan-400/10 absolute top-0 animate-scan" />
                  </div>
                </>
              )}
            </div>
          );
        })}
      </div>

      <div className="p-8 md:p-12 min-h-[400px]">
        <AnimatePresence mode="wait">
          {currentStep === 1 && (
            <motion.div
              key="step1"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h3 className="text-xl font-bold">Select Asset & Chain</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="text-sm text-slate-500">Source Chain</label>
                  <select
                    className="w-full bg-slate-800 border border-slate-700 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-cyan-400/50"
                    value={formData.chain}
                    onChange={(event) =>
                      setFormData({
                        ...formData,
                        chain: event.target.value as RuleWizardFormData['chain'],
                      })
                    }
                  >
                    <option value="sepolia">Ethereum Sepolia</option>
                    <option value="base-sepolia">Base Sepolia</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-slate-500">Asset to Monitor</label>
                  <select
                    className="w-full bg-slate-800 border border-slate-700 rounded-xl p-4 focus:outline-none focus:ring-2 focus:ring-cyan-400/50"
                    value={formData.asset}
                    onChange={(event) =>
                      setFormData({
                        ...formData,
                        asset: event.target.value as RuleWizardFormData['asset'],
                      })
                    }
                  >
                    <option value="ETH">ETH (Native)</option>
                    <option value="USDC">USDC (Mock)</option>
                    <option value="WBTC">WBTC (Mock)</option>
                  </select>
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 2 && (
            <motion.div
              key="step2"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h3 className="text-xl font-bold">Define Trigger Condition</h3>
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {(['PriceBelow', 'PriceAbove', 'TransferOutflow'] as DemoRuleType[]).map((condition) => (
                    <button
                      key={condition}
                      onClick={() => setFormData({ ...formData, condition })}
                      className={`p-4 rounded-xl border-2 transition-all text-sm font-semibold ${
                        formData.condition === condition
                          ? 'border-cyan-400 bg-cyan-400/10 text-cyan-400'
                          : 'border-slate-800 bg-slate-800/50 text-slate-500'
                      }`}
                    >
                      {condition}
                    </button>
                  ))}
                </div>
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <label className="text-sm text-slate-500">Threshold Value</label>
                    <span className="text-[10px] font-mono text-cyan-400 uppercase tracking-widest">
                      {formData.condition === 'TransferOutflow' ? formData.asset : 'USD'}
                    </span>
                  </div>
                  <div className="relative group">
                    <input
                      type="number"
                      step="any"
                      placeholder={formData.condition === 'TransferOutflow' ? "e.g. 0.5" : "e.g. 3500"}
                      className="w-full bg-slate-800 border border-slate-700 rounded-xl p-4 pr-16 focus:outline-none focus:ring-2 focus:ring-cyan-400/50 font-mono transition-all group-hover:border-slate-600"
                      value={formData.threshold}
                      onChange={(event) =>
                        setFormData({ ...formData, threshold: event.target.value })
                      }
                    />
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-500 pointer-events-none">
                      {formData.condition === 'TransferOutflow' ? formData.asset : 'USD'}
                    </div>
                  </div>
                  <p className="text-[10px] text-slate-600">
                    Sentinel will trigger if {formData.condition === 'TransferOutflow' ? 'balance' : 'price'} drops below this value.
                  </p>
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 3 && (
            <motion.div
              key="step3"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="space-y-6"
            >
              <h3 className="text-xl font-bold">Configure Action</h3>
              <div className="space-y-6">
                <div className="p-6 rounded-2xl bg-slate-800/50 border border-slate-700">
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-12 h-12 rounded-full bg-emerald-400/10 flex items-center justify-center text-emerald-400">
                      <Database size={24} />
                    </div>
                    <div>
                      <div className="font-bold">Vault Execution Adapter</div>
                      <div className="text-xs text-slate-500">Destination: Base Sepolia</div>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <label className="flex items-center gap-3 p-4 rounded-xl border border-slate-700 bg-slate-800 hover:border-cyan-400/50 transition-all cursor-pointer">
                      <input type="radio" name="action" className="accent-cyan-400" defaultChecked />
                      <div>
                        <div className="text-sm font-bold">Emergency Bridge & Swap</div>
                        <div className="text-[10px] text-slate-500">
                          Safeguard assets to stablecoins on target chain
                        </div>
                      </div>
                    </label>
                  </div>
                </div>

                <div className="p-4 rounded-xl bg-cyan-400/5 border border-cyan-400/20 text-xs text-slate-400 leading-relaxed">
                  <span className="text-cyan-400 font-bold uppercase mr-2">Note:</span>
                  {mode === 'demo'
                    ? 'This action is simulated for local development. No signature or on-chain transaction will be sent.'
                    : `Creating this rule requires a signature. Reactive VM will subscribe to the ${formData.chain} events and execute on Base Sepolia when conditions are met.`}
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="p-8 border-t border-slate-800 bg-slate-900/50 flex items-center justify-between">
        <button
          onClick={prevStep}
          disabled={currentStep === 1}
          className="px-6 py-2 rounded-xl text-slate-400 hover:text-white disabled:opacity-0 transition-all"
        >
          Back
        </button>
        <button
          onClick={currentStep === 3 ? () => onComplete(formData) : nextStep}
          className="flex items-center gap-2 px-8 py-3 rounded-xl bg-cyan-400 text-black font-bold hover:bg-cyan-300 transition-all shadow-cyan-glow"
        >
          {currentStep === 3
            ? mode === 'demo'
              ? 'Simulate Rule Deployment'
              : 'Deploy Sentinel Rule'
            : 'Continue'}
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  );
}
