# Reactive Vault Sentinel

Reactive Vault Sentinel 是一个面向黑客松场景的跨链金库守护系统。它监听源链上的风险事件，在 Reactive Network 上执行规则判断，并在目标链触发保护动作，用来演示跨链自动化风控的完整链路。

## 概览

项目围绕一条三阶段执行链路展开：

1. **源链监控**：在 Sepolia 上监听价格和余额变化
2. **Reactive 决策**：在 Reactive Lasna 上根据规则判断是否触发动作
3. **目标链执行**：在 Base Sepolia 上通过 adapter 执行保护操作

当前仓库是一个 **hackathon demo + integration skeleton**：

- 合约、测试、部署脚本和 ABI 已具备
- 前端演示界面已可构建
- 配置仍以占位符和测试网联调为主

---

## 仓库结构

```text
reactive-vault-sentinel/
├─ apps/
│  └─ web/                      # Next.js 14 演示前端
├─ contracts/                   # Foundry 合约、脚本、测试
├─ packages/
│  ├─ abi/                      # 导出的 JSON ABI
│  └─ config/                   # 链与地址配置占位
├─ package.json                 # workspace 根脚本
├─ pnpm-workspace.yaml
└─ README.md
```

### `contracts/`

Foundry 工程，主要职责：

- 源链监控合约
- Reactive 决策合约
- 目标链执行合约与 adapter
- 部署脚本
- 单元测试与链路测试

核心合约：

- `contracts/src/mocks/MockPriceFeed.sol`
- `contracts/src/monitors/BalanceMonitor.sol`
- `contracts/src/sentinel/VaultSentinelReactive.sol`
- `contracts/src/execution/VaultExecution.sol`
- `contracts/src/adapters/basic/BasicTransferAdapter.sol`
- `contracts/src/adapters/uniswap/UniswapStopOrderAdapter.sol`
- `contracts/src/adapters/aave/AaveProtectionAdapter.sol`

部署脚本：

- `contracts/script/DeploySepolia.s.sol`
- `contracts/script/DeployBaseSepolia.s.sol`
- `contracts/script/DeployLasna.s.sol`

测试文件：

- `contracts/test/MockPriceFeed.t.sol`
- `contracts/test/BalanceMonitor.t.sol`
- `contracts/test/VaultExecution.t.sol`
- `contracts/test/VaultSentinelReactive.t.sol`
- `contracts/test/ReactiveVaultFlow.t.sol`

### `apps/web/`

基于 Next.js 14 App Router 的演示前端，提供 3 个主要页面：

- `/`：Dashboard
- `/rules`：Rule Configurator
- `/trace`：Sentinel Live Trace

核心入口：

- `apps/web/src/app/layout.tsx`
- `apps/web/src/app/providers.tsx`
- `apps/web/src/app/page.tsx`
- `apps/web/src/app/rules/page.tsx`
- `apps/web/src/app/trace/page.tsx`

### `packages/`

- `packages/abi/`：机器可读的 JSON ABI 文件
- `packages/config/`：测试网链 ID、callback proxy、部署地址占位配置

---

## 系统架构

```text
Sepolia
  ├─ MockPriceFeed
  └─ BalanceMonitor
        │
        ▼
Reactive Lasna
  └─ VaultSentinelReactive
        │ Callback
        ▼
Base Sepolia
  └─ VaultExecution
      ├─ BasicTransferAdapter
      ├─ UniswapStopOrderAdapter
      └─ AaveProtectionAdapter
```

### 规则类型

当前 Reactive 规则层支持：

- `PriceBelow`
- `PriceAbove`
- `TransferOutflow`

### 执行动作

当前目标链执行层支持：

- 基础转账
- Uniswap 止损交换
- Aave 防护动作

---

## 技术栈

### 合约侧

- Solidity `0.8.28`
- Foundry
- OpenZeppelin Contracts v5
- Reactive Lib

`contracts/foundry.toml` 当前配置了：

- `solc_version = "0.8.28"`
- `evm_version = "cancun"`
- OpenZeppelin / Reactive / forge-std remappings

### 前端侧

- Next.js `14.1.4`
- React `18`
- TypeScript
- Tailwind CSS
- wagmi v2
- RainbowKit
- viem
- TanStack Query
- Framer Motion

---

## 已完成内容

### 合约

- `MockPriceFeed`
- `BalanceMonitor`
- `VaultExecution`
- `VaultSentinelReactive`
- 三类 adapter
- Foundry 测试套件
- 测试网部署脚本

### 前端

- Dashboard 页面
- Rule Configurator 页面
- Live Trace 演示页
- wagmi / RainbowKit provider 初始化
- 前端链配置与 ABI 配置

### 集成产物

- ABI 已导出到 `packages/abi`
- workspace 脚本已可用
- web app 已完成构建修复

---

## 快速开始

### 1. 安装依赖

在仓库根目录执行：

```bash
pnpm install
```

### 2. 准备 Foundry

确认本机有 Foundry：

```bash
forge --version
```

### 3. 配置环境变量

复制示例文件：

```bash
cp contracts/.env.example contracts/.env
```

`contracts/.env.example` 当前包含：

- `SEPOLIA_RPC_URL`
- `BASE_SEPOLIA_RPC_URL`
- `REACTIVE_RPC_URL=https://lasna-rpc.rnk.dev/`
- `SEPOLIA_PRIVATE_KEY`
- `BASE_PRIVATE_KEY`
- `REACTIVE_PRIVATE_KEY`
- `OWNER`
- 各类部署输出地址占位

如果前端要启用真实钱包连接，还需要额外配置：

- `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID`

---

## 常用命令

### 根目录

```bash
pnpm dev:web
pnpm build:web
pnpm lint:web
pnpm test:contracts
```

### 合约目录

```bash
pnpm --dir contracts exec forge build
pnpm --dir contracts exec forge test
```

### 前端目录

```bash
cd apps/web
pnpm dev
pnpm build
pnpm exec tsc --noEmit
```

---

## ABI 与配置

### ABI 文件

- `packages/abi/VaultSentinelReactive.json`
- `packages/abi/VaultExecution.json`
- `packages/abi/MockPriceFeed.json`
- `packages/abi/BalanceMonitor.json`

这些文件已经是 **可解析的 JSON ABI**，可直接被前端或脚本消费。

### 配置文件

- `packages/config/contracts.ts`
- `packages/config/chains.ts`
- `packages/config/index.ts`

当前仍以测试网占位地址为主，后续接真实联调时需要替换成部署结果。

---

## 当前状态

当前仓库已经具备：

- 合约源码
- Foundry 测试
- 部署脚本
- ABI 导出
- 前端演示应用
- Git 仓库初始化

已验证：

- 合约测试已通过
- `apps/web` 类型检查通过
- `apps/web` 生产构建通过
- root `pnpm --filter @vault-sentinel/web build` 可用

但它还不是生产仓库。要进入真实测试网联调，至少还需要：

- 填入真实部署地址
- 在前端接入真实合约地址
- 设置 `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID`
- 做端到端 smoke test
- 根据需要补 zero-address guard 与更细的 a11y 修复

---

## Git

该目录已经初始化为 Git 仓库。

建议下一步：

```bash
git status
git add .
```

如果你准备继续，我下一步可以直接帮你做：

1. 生成首个提交前可用的 `.gitignore` 检查
2. 清理 `git status`，确认不会把无关文件带进仓库
3. 再帮你创建第一次提交
