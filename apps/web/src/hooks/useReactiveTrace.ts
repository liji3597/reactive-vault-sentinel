'use client';

import { useState, useEffect } from 'react';

export function useReactiveTrace() {
  const [traceState, setTraceState] = useState({
    activePhase: 1,
    logs: [],
    lastUpdate: new Date()
  });

  // Mock polling for demo
  useEffect(() => {
    const interval = setInterval(() => {
      setTraceState(prev => ({
        ...prev,
        activePhase: (prev.activePhase % 3) + 1,
        lastUpdate: new Date()
      }));
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  return traceState;
}
