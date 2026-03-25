'use client';

import { useReadContract, useWriteContract } from 'wagmi';
import { VAULT_SENTINEL_ABI, CONTRACT_ADDRESSES } from '@/lib/contracts';

export function useRules() {
  const { data: ruleIds } = useReadContract({
    address: CONTRACT_ADDRESSES.vaultSentinel as `0x${string}`,
    abi: VAULT_SENTINEL_ABI,
    functionName: 'getRuleIds',
  });

  const { writeContract: addRule } = useWriteContract();
  const { writeContract: pauseRule } = useWriteContract();
  const { writeContract: resumeRule } = useWriteContract();

  return {
    ruleIds,
    addRule,
    pauseRule,
    resumeRule,
  };
}
