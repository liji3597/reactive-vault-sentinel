# Reactive Vault Sentinel

![Solidity](https://img.shields.io/badge/Solidity-0.8.28-363636?logo=solidity&logoColor=white) ![Foundry](https://img.shields.io/badge/Foundry-Contracts-black?logo=ethereum&logoColor=white) ![Next.js](https://img.shields.io/badge/Next.js-14-black?logo=nextdotjs&logoColor=white) ![Sepolia](https://img.shields.io/badge/Source-Sepolia-6c5ce7) ![Base Sepolia](https://img.shields.io/badge/Target-Base%20Sepolia-0052ff) ![Reactive Lasna](https://img.shields.io/badge/Reactive-Lasna-00c2ff)

> Autonomous cross-chain risk management for vaults: detect risk on **Sepolia**, evaluate intent on **Reactive Lasna**, and execute protection actions on **Base Sepolia**.
>
> **Current status:** the MVP, frontend demo surfaces, contract code, tests, and deployment artifacts exist. The remaining blocker is **confirmed end-to-end callback delivery on Lasna**.

[Demo Surfaces](#demo-surfaces) · [Architecture](#architecture) · [Status](#current-status) · [Evidence](#evidence) · [Setup](#local-setup) · [Repository Layout](#repository-layout)

## Judge summary

| Area | Status | Evidence |
|---|---|---|
| Product demo | Ready | `apps/web/src/app/page.tsx`, `apps/web/src/app/rules/page.tsx`, `apps/web/src/app/trace/page.tsx` |
| Contract code | Implemented | `contracts/src/` |
| Sepolia source deploy | Evidenced | `contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json` |
| Base execution deploy | Evidenced | `contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json` |
| Lasna subscribe via `forge script` | Blocked | `scripts/e2e/step11-escalation-final.txt` |
| Lasna subscribe via `forge create` | Works for registration | recent probe and deploy evidence in `scripts/e2e/` + local broadcast artifacts |
| Full Sepolia → Lasna → Base callback landing | Not yet confirmed | `scripts/e2e/step11-incident-evidence.txt`, `scripts/e2e/step11-escalation-final.txt` |

## What judges should inspect first

1. **Product surface**
   - `apps/web/src/app/page.tsx`
   - `apps/web/src/app/rules/page.tsx`
   - `apps/web/src/app/trace/page.tsx`
2. **Execution core**
   - `contracts/src/sentinel/VaultSentinelReactive.sol`
   - `contracts/src/execution/VaultExecution.sol`
3. **Deployment proof**
   - `contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json`
   - `contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json`
4. **Real blocker evidence**
   - `scripts/e2e/step11-incident-evidence.txt`
   - `scripts/e2e/step11-escalation-final.txt`

---

## Problem → Solution

### Problem

Cross-chain protection logic usually degrades into an ugly stack:

- an off-chain watcher
- a backend relay service
- a hot wallet with execution rights
- more moving parts than the demo actually needs

That creates extra trust assumptions and makes the system harder to explain in a hackathon setting.

### Solution

Reactive Vault Sentinel reduces the intended path to three understandable layers:

- **Sepolia** emits risk signals
- **Reactive Lasna** decides whether a rule should fire
- **Base Sepolia** executes the protective action through a single callback entrypoint

That is the product and architecture being demonstrated in this repo.

---

## What this project does

Reactive Vault Sentinel is a hackathon-style prototype for event-driven cross-chain vault protection.

It is designed to:

1. **Detect risk events on Sepolia** from price or balance monitors.
2. **Evaluate reactive rules on Reactive Lasna** using subscription-driven logic.
3. **Execute protection actions on Base Sepolia** through a unified callback executor and adapters.

The repo also includes a **judge-friendly frontend demo** with a dashboard, a rule configurator, and a live trace replay.

## Why Reactive Network here

Without a reactive callback layer, the fallback is the usual ugly path: an off-chain watcher, a hot wallet, extra backend glue, and more trust assumptions.

This project uses the Reactive pattern to keep the intended flow simple:

- source-chain events originate on Sepolia
- reactive logic decides whether protection should fire
- target-chain execution happens through a single callback entrypoint on Base Sepolia

That is the architectural idea being demonstrated here, even though the final Lasna callback delivery step is still the current blocker.

---

## Architecture

```text
Sepolia
  ├─ MockPriceFeed
  └─ BalanceMonitor
        │ emits source events
        ▼
Reactive Lasna
  └─ VaultSentinelReactive
        │ emits callback payloads
        ▼
Base Sepolia
  └─ VaultExecution
      ├─ BasicTransferAdapter
      ├─ UniswapStopOrderAdapter
      └─ AaveProtectionAdapter
```

### Component overview

| Layer | Component | Responsibility | Current state |
|---|---|---|---|
| Source chain | `MockPriceFeed`, `BalanceMonitor` | Emit risk signals on Sepolia | Implemented, deployed, and evidenced |
| Reactive layer | `VaultSentinelReactive` | Register subscriptions, match rules, emit callback payloads | Implemented; Lasna delivery remains the blocker |
| Execution layer | `VaultExecution` + adapters | Receive callback and execute protection logic on Base Sepolia | Implemented, tested, and deployed |
| Frontend | Dashboard / Rules / Trace | Explain and demo the product flow | Working in demo-safe mode |

---

## Current status

### Confirmed working

- Core Solidity contracts are implemented under `contracts/src/`
- Foundry test coverage exists for the sentinel, execution layer, adapters, and integrated flow
- The frontend app under `apps/web` runs and presents the product clearly
- The UI already exposes three useful demo surfaces:
  - Dashboard
  - Rule Configurator
  - Live Trace replay
- Sepolia source contracts can be deployed and emit source events
- Base Sepolia execution contracts can be deployed and configured

### Confirmed and evidenced

- Sepolia deployment artifacts exist for:
  - `MockPriceFeed`
  - `BalanceMonitor`
- Base Sepolia deployment artifacts exist for:
  - `VaultExecution`
  - `BasicTransferAdapter`
  - `UniswapStopOrderAdapter`
  - `AaveProtectionAdapter`
- Smoke and escalation evidence files are present under `scripts/e2e/`
- Latest Step 11 rerun still produced the same failure boundary:
  - Sepolia source event was observed successfully
  - Lasna showed **no** new `RuleTriggered` and **no** new `Callback` event in the verification window
  - Base showed **no** `ExecutionSucceeded`
  - Lasna RPC state reads for pause/subscription flags were unstable during the rerun, but debt read returned zero
- Recent debugging established a sharper fault boundary:
  - `forge script` on Lasna fails in the `subscribe()` path
  - `forge create` can deploy and register subscriptions on Lasna
  - even with minimal probes, we still do **not** have a confirmed Base-side callback landing from Lasna

### Not yet end-to-end validated

The repo does **not** currently claim a fully verified Sepolia → Lasna → Base callback closure.

The latest Step 11 smoke rerun also failed with the same shape:

- source event on Sepolia: observed
- new Lasna `RuleTriggered`: not observed
- new Lasna `Callback`: not observed
- Base `ExecutionSucceeded`: not observed

The strongest current diagnosis is:

- the blocker is **not** primarily in business-contract logic,
- and is **more likely in Lasna callback delivery/runtime behavior** after subscription registration.

That distinction matters: this is not an incomplete toy repo. It is a mostly-built MVP whose last real-network step is still blocked by the Reactive Lasna path.

---

## Evidence

### Artifact map

| If you want to inspect... | Open this |
|---|---|
| Current Sepolia deployment artifact | `contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json` |
| Current Base deployment artifact | `contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json` |
| Historical Base redeploy referenced in escalation | `contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-1775059000247.json` |
| Smoke verification procedure | `scripts/e2e/smoke.sh` |
| Incident log | `scripts/e2e/step11-incident-evidence.txt` |
| Escalation summary | `scripts/e2e/step11-escalation-final.txt` |
| Reactive ABI | `packages/abi/VaultSentinelReactive.json` |
| Base execution ABI | `packages/abi/VaultExecution.json` |

### Deployment artifacts

| Artifact | What it proves |
|---|---|
| [`contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json`](contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json) | Current Sepolia deployment artifact for `MockPriceFeed` and `BalanceMonitor` |
| [`contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json`](contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json) | Current Base Sepolia deployment artifact for the execution layer |
| [`contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-1775059000247.json`](contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-1775059000247.json) | Earlier Base Sepolia redeploy artifact referenced in escalation notes |

### Smoke and incident evidence

| Artifact | What it shows |
|---|---|
| [`scripts/e2e/smoke.sh`](scripts/e2e/smoke.sh) | Current smoke verification procedure; success now requires the full chain: Sepolia source event, Lasna callback, and Base `ExecutionSucceeded` |
| [`scripts/e2e/step11-incident-evidence.txt`](scripts/e2e/step11-incident-evidence.txt) | Observed Sepolia event / missing Lasna callback evidence |
| [`scripts/e2e/step11-escalation-final.txt`](scripts/e2e/step11-escalation-final.txt) | Minimal repro summary and escalation-ready diagnosis |

### Exported interfaces

| ABI | Purpose |
|---|---|
| [`packages/abi/VaultSentinelReactive.json`](packages/abi/VaultSentinelReactive.json) | Reactive rule engine ABI |
| [`packages/abi/VaultExecution.json`](packages/abi/VaultExecution.json) | Base execution entrypoint ABI |

### Representative deployed contracts from current local artifacts

These addresses are shown here only as **artifact-backed examples**, not as a promise that every linked path is fully live end-to-end.

#### Sepolia (`contracts/broadcast/DeploySepolia.s.sol/11155111/run-latest.json`)

- `MockPriceFeed`: `0xbc3e0eeb32d174f0a2de9cbf7d2bae5259b7a8e1`
- `BalanceMonitor`: `0x433d2e2138571196f07e750cbab73aec36d46bc9`
- Deployment txs:
  - `0x98d0d03c40f30205155b4810a74e0febccdb4b389ad4ae84d4fa15ac2fa5bd62`
  - `0x3576f5163a55d27bdc82723af31ece892d14d6c882b59c29e86fe0976a1d6dcb`

#### Base Sepolia (`contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-latest.json`)

- `VaultExecution`: `0x2497bd28d02297F0aCC928674bD915e519950C3F`
- `BasicTransferAdapter`: `0xEa1976afEF7AACeFDf4F0Ab21CB77Cf39Db54703`
- `UniswapStopOrderAdapter`: `0xc79957B6A4f1AF49039C9295F6d8900241571dd9`
- `AaveProtectionAdapter`: `0xB37F2e404671be09446b5ab99Fd758DA91a47611`

#### Historical Base redeploy referenced in escalation notes

From [`scripts/e2e/step11-escalation-final.txt`](scripts/e2e/step11-escalation-final.txt) and [`contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-1775059000247.json`](contracts/broadcast/DeployBaseSepolia.s.sol/84532/run-1775059000247.json):

- `VaultExecution`: `0x00a03196D9536337ed857F5D43dc7aE648e89Bf9`
- `BasicTransferAdapter`: `0x5DCe4Eaaf21Bf4DaCB767dC6a8b45B7165dD92C0`
- `UniswapStopOrderAdapter`: `0x91Da5ee2A393B8056E688BDD43103854b0Ee7128`
- `AaveProtectionAdapter`: `0x06013D3B5cA4662246CC3E345E39BEDf29758484`

---

## Demo surfaces

The frontend is intentionally useful for hackathon review even when Lasna is not completing the final callback hop.

### Dashboard

- File: `apps/web/src/app/page.tsx`
- Purpose: explain the product in one screen
- Current behavior:
  - shows safe demo mode when contracts are not configured
  - highlights positions, rules, and event feed

### Rule Configurator

- File: `apps/web/src/app/rules/page.tsx`
- Purpose: show how users define cross-chain protection rules
- Current behavior:
  - in demo mode, creation / pause / removal are simulated locally
  - success message makes this explicit

### Live Trace

- File: `apps/web/src/app/trace/page.tsx`
- Purpose: show the intended end-to-end lifecycle visually
- Current behavior:
  - runs as a simulated replay until real contract addresses and stable chain callbacks are configured
  - useful for product communication, not proof of Lasna callback delivery

---

## Contracts and code structure

### Core contracts

| Contract | File | Role |
|---|---|---|
| `VaultSentinelReactive` | `contracts/src/sentinel/VaultSentinelReactive.sol` | Reactive rule engine on Lasna |
| `VaultExecution` | `contracts/src/execution/VaultExecution.sol` | Base Sepolia execution entrypoint |
| `BasicTransferAdapter` | `contracts/src/adapters/basic/BasicTransferAdapter.sol` | Basic transfer action |
| `UniswapStopOrderAdapter` | `contracts/src/adapters/uniswap/UniswapStopOrderAdapter.sol` | Stop-order style action |
| `AaveProtectionAdapter` | `contracts/src/adapters/aave/AaveProtectionAdapter.sol` | Aave-oriented protection action |
| `MockPriceFeed` | `contracts/src/mocks/MockPriceFeed.sol` | Source event emitter |
| `BalanceMonitor` | `contracts/src/monitors/BalanceMonitor.sol` | Source balance monitor |

### Deployment scripts

- `contracts/script/DeploySepolia.s.sol`
- `contracts/script/DeployBaseSepolia.s.sol`
- `contracts/script/DeployLasna.s.sol`

### Test and validation material

- Foundry tests under `contracts/test/`
- Smoke and incident material under `scripts/e2e/`

---

## Known limitations

This section is intentionally blunt.

- Do **not** claim the full cross-chain callback path is fully verified today.
- On Lasna, the `forge script` deployment path fails in the `service.subscribe(...)` setup path.
- A `forge create` deployment path can still register subscriptions on Lasna.
- Even after that, recent minimal-probe validation still did **not** produce a confirmed Base-side callback landing.
- The current strongest diagnosis is therefore:
  - **Lasna callback delivery/runtime remains the blocking fault domain**,
  - not the product idea,
  - not the frontend,
  - and not obviously the Base execution contract logic.

Also note:

- `packages/config/contracts.ts` may lag behind the newest artifact-backed addresses.
- For README-level claims, prefer the `contracts/broadcast/*` artifacts and `scripts/e2e/*` evidence files as the source of truth.

---

## Local setup

### Prerequisites

- Node.js / pnpm
- Foundry (`forge`, `cast`)

### Install

```bash
pnpm install
```

### Configure contracts

Copy the example environment file:

```bash
cp contracts/.env.example contracts/.env
```

Important variables from `contracts/.env.example`:

- `SEPOLIA_RPC_URL`
- `BASE_SEPOLIA_RPC_URL`
- `REACTIVE_RPC_URL`
- `OWNER`
- `SEPOLIA_PRIVATE_KEY` / `BASE_PRIVATE_KEY` / `REACTIVE_PRIVATE_KEY`
- `VAULT_EXECUTION_EXPECTED_RVM_ID`
- deployment output addresses after each step

Important note:

- `VAULT_EXECUTION_EXPECTED_RVM_ID` is the **Reactive deployer wallet / expected RVM ID**, **not** the Lasna contract address.

### Useful commands

#### Root

```bash
pnpm dev:web
pnpm build:web
pnpm lint:web
pnpm test:contracts
pnpm smoke:e2e
```

#### Contracts

```bash
pnpm --dir contracts exec forge build
pnpm --dir contracts exec forge test
```

#### Frontend

```bash
pnpm --filter @vault-sentinel/web dev
pnpm --filter @vault-sentinel/web build
pnpm --filter @vault-sentinel/web lint
```

---

## Demo run

If you want the fastest judge/demo path:

1. Start the frontend:
   ```bash
   pnpm dev:web
   ```
2. Open `http://localhost:3000`
3. Show:
   - Dashboard
   - Rule Configurator
   - Live Trace
4. Explain clearly:
   - source events come from Sepolia
   - intended rules run on Reactive Lasna
   - target actions execute on Base Sepolia
   - current UI is demo-safe where Lasna callback confirmation is still blocked

This is a stronger demo than pretending the final callback hop is already stable.

---

## Repository layout

```text
reactive-vault-sentinel/
├─ apps/          # Next.js demo frontend
├─ contracts/     # Solidity contracts, scripts, tests, env, broadcast artifacts
├─ packages/      # exported ABIs and shared config
├─ scripts/       # smoke and evidence scripts
├─ package.json
├─ pnpm-workspace.yaml
└─ README.md
```

---

## Bottom line

Reactive Vault Sentinel is already a serious MVP:

- the product surface exists,
- the contracts are implemented,
- tests and deployment artifacts exist,
- the frontend is polished enough for a hackathon review,
- and the remaining problem is sharply isolated.

The unfinished part is **not** “does the project make sense?”

The unfinished part is:

> whether Reactive Lasna will reliably complete the final callback delivery step for this flow in the current testnet/runtime environment.

That is the right boundary to communicate to judges, collaborators, and future maintainers.