'use client';

import { useEffect, useState } from 'react';
import { appMode, contractsConfigured } from '@/lib/contracts';
import { DEMO_EVENTS, DEMO_TRACE_LOGS } from '@/lib/demoData';

export function useReactiveTrace() {
  const [activePhase, setActivePhase] = useState<1 | 2 | 3>(1);
  const [isLive, setIsLive] = useState(true);
  const [lastUpdate, setLastUpdate] = useState(() => new Date());

  useEffect(() => {
    if (!isLive) {
      return;
    }

    const interval = window.setInterval(() => {
      setActivePhase((currentPhase) =>
        currentPhase === 3 ? 1 : ((currentPhase + 1) as 1 | 2 | 3)
      );
      setLastUpdate(new Date());
    }, 4000);

    return () => window.clearInterval(interval);
  }, [isLive]);

  return {
    mode: appMode,
    isConfigured: contractsConfigured,
    activePhase,
    isLive,
    setIsLive,
    lastUpdate,
    events: DEMO_EVENTS,
    logs: DEMO_TRACE_LOGS,
  };
}
