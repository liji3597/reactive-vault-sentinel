'use client';

import { useCallback, useEffect, useState } from 'react';
import { useReadContract } from 'wagmi';
import {
  CONTRACT_ADDRESSES,
  VAULT_SENTINEL_ABI,
  appMode,
  contractsConfigured,
} from '@/lib/contracts';
import {
  DEFAULT_DEMO_RULES,
  DEMO_RULES_STORAGE_KEY,
  type DemoRule,
} from '@/lib/demoData';
import type { RuleWizardFormData } from '@/components/rules/RuleWizard';

function cloneDefaultRules() {
  return DEFAULT_DEMO_RULES.map((rule) => ({ ...rule }));
}

function isDemoRule(value: unknown): value is DemoRule {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const candidate = value as Partial<DemoRule>;

  const validStatus = candidate.status === 'Active' || candidate.status === 'Paused';
  const validType =
    candidate.type === 'PriceBelow' ||
    candidate.type === 'PriceAbove' ||
    candidate.type === 'TransferOutflow';
  const validChain =
    candidate.chain === 'Sepolia' || candidate.chain === 'Base Sepolia';
  const validTarget = candidate.target === 'Base Sepolia';
  const validHealth = candidate.health === 'Healthy' || candidate.health === 'Idle';

  return (
    typeof candidate.id === 'number' &&
    typeof candidate.name === 'string' &&
    typeof candidate.threshold === 'string' &&
    validStatus &&
    validType &&
    validChain &&
    validTarget &&
    validHealth
  );
}

function loadStoredRules(): DemoRule[] {
  if (typeof window === 'undefined') {
    return cloneDefaultRules();
  }

  try {
    const raw = window.localStorage.getItem(DEMO_RULES_STORAGE_KEY);
    if (!raw) {
      return cloneDefaultRules();
    }

    const parsed = JSON.parse(raw);
    const sanitized = Array.isArray(parsed) ? parsed.filter(isDemoRule) : [];

    return sanitized.length > 0 ? sanitized : cloneDefaultRules();
  } catch {
    return cloneDefaultRules();
  }
}

function formatThreshold(formData: RuleWizardFormData) {
  const fallback =
    formData.condition === 'TransferOutflow'
      ? `1 ${formData.asset}`
      : `3500 USD`;

  const value = formData.threshold.trim() || fallback;
  const upperValue = value.toUpperCase();

  if (
    upperValue.includes('USD') ||
    upperValue.includes('ETH') ||
    upperValue.includes('USDC') ||
    upperValue.includes('WBTC')
  ) {
    return value;
  }

  return formData.condition === 'TransferOutflow'
    ? `${value} ${formData.asset}`
    : `${value} USD`;
}

function buildRuleName(formData: RuleWizardFormData) {
  if (formData.condition === 'TransferOutflow') {
    return `${formData.asset} Balance Refill`;
  }

  if (formData.condition === 'PriceAbove') {
    return `${formData.asset} Upside Alert`;
  }

  return `${formData.asset} Depeg Guardian`;
}

export function useRules() {
  const [rules, setRules] = useState<DemoRule[]>(() => cloneDefaultRules());
  const [hasHydrated, setHasHydrated] = useState(false);

  const { data: ruleIds, isLoading, error } = useReadContract({
    address: CONTRACT_ADDRESSES.vaultSentinel,
    abi: VAULT_SENTINEL_ABI,
    functionName: 'getRuleIds',
    query: {
      enabled: contractsConfigured,
    },
  });

  useEffect(() => {
    setRules(loadStoredRules());
    setHasHydrated(true);
  }, []);

  useEffect(() => {
    if (!hasHydrated || typeof window === 'undefined') {
      return;
    }

    window.localStorage.setItem(DEMO_RULES_STORAGE_KEY, JSON.stringify(rules));
  }, [hasHydrated, rules]);

  const createDemoRule = useCallback((formData: RuleWizardFormData) => {
    setRules((currentRules) => {
      const nextId = currentRules.reduce(
        (highestId, rule) => Math.max(highestId, rule.id),
        0
      ) + 1;

      const nextRule: DemoRule = {
        id: nextId,
        name: buildRuleName(formData),
        type: formData.condition,
        threshold: formatThreshold(formData),
        status: 'Active',
        chain: formData.chain === 'base-sepolia' ? 'Base Sepolia' : 'Sepolia',
        target: 'Base Sepolia',
        health: 'Healthy',
      };

      return [nextRule, ...currentRules];
    });
  }, []);

  const toggleRule = useCallback((ruleId: number) => {
    setRules((currentRules) =>
      currentRules.map((rule) => {
        if (rule.id !== ruleId) {
          return rule;
        }

        const nextStatus = rule.status === 'Active' ? 'Paused' : 'Active';

        return {
          ...rule,
          status: nextStatus,
          health: nextStatus === 'Active' ? 'Healthy' : 'Idle',
        };
      })
    );
  }, []);

  const removeRule = useCallback((ruleId: number) => {
    setRules((currentRules) => currentRules.filter((rule) => rule.id !== ruleId));
  }, []);

  return {
    mode: appMode,
    isConfigured: contractsConfigured,
    isLoading,
    error,
    ruleIds,
    rules,
    createDemoRule,
    toggleRule,
    removeRule,
  };
}
