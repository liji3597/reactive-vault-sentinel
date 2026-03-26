'use client';

import PhaseCard from './PhaseCard';
import ConnectingLine from './ConnectingLine';

export default function CrossChainMap({ activePhase }: { activePhase: 1 | 2 | 3 }) {
  return (
    <div className="relative h-full flex items-center justify-between gap-4 z-10 px-4">
      <div className="flex-1 flex flex-col items-center">
        <h3 className="text-slate-500 font-mono text-sm mb-6 uppercase tracking-widest">Source Chain</h3>
        <PhaseCard
          phase={1}
          title="Sepolia"
          status={activePhase === 1 ? 'triggering' : 'idle'}
          details="Price Alert: ETH/USD"
          txHash="0x4a2b...c23e"
          isActive={activePhase === 1}
        />
      </div>

      <div className="w-32 relative flex items-center justify-center">
        <ConnectingLine active={activePhase === 2} />
      </div>

      <div className="flex-1 flex flex-col items-center">
        <h3 className="text-cyan-400 font-mono text-sm mb-6 uppercase tracking-widest">Reactive VM</h3>
        <PhaseCard
          phase={2}
          title="ReactVM"
          status={activePhase === 2 ? 'processing' : 'idle'}
          details="Executing Rule #1 Logic"
          txHash="kopli:trace:8812"
          isActive={activePhase === 2}
        />
      </div>

      <div className="w-32 relative flex items-center justify-center">
        <ConnectingLine active={activePhase === 3} />
      </div>

      <div className="flex-1 flex flex-col items-center">
        <h3 className="text-slate-500 font-mono text-sm mb-6 uppercase tracking-widest">Destination Chain</h3>
        <PhaseCard
          phase={3}
          title="Base Sepolia"
          status={activePhase === 3 ? 'executing' : activePhase === 1 ? 'completed' : 'idle'}
          details="Vault Action Executed"
          txHash="0x8b1c...f912"
          isActive={activePhase === 3}
        />
      </div>
    </div>
  );
}
