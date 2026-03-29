# Reactive Vault Sentinel

Reactive Vault Sentinel 是一个面向黑客松场景的跨链金库守护 Demo：它在 **Sepolia** 监听风险事件，在 **Reactive Lasna** 上执行规则判断，并在 **Base Sepolia** 触发保护动作，用来展示一条完整的“事件驱动跨链自动化风控”链路。

当前仓库已经具备：

- 智能合约源码、部署脚本、ABI、Foundry 测试
- Next.js 前端演示应用
- Sepolia / Base Sepolia 的部署与验证基础能力
- 本地可运行的 Demo 演示路径

当前仓库**尚未完成最终实链闭环验收**。阻塞点集中在 **Reactive Lasna**：`VaultSentinelReactive` 在 Lasna 上执行 `service.subscribe(...)` 时发生系统级回滚，因此 **Sepolia → Lasna → Base Sepolia** 的真实回调链路目前无法确认为已打通。

---

## 1. 项目目标

本项目的目标不是做一个庞大的 DeFi 平台，而是做一条足够清晰、可验证、可演示的跨链风控主链路：

1. **源链监控**：监听价格或余额变化
2. **Reactive 决策**：根据规则判断是否需要执行保护动作
3. **目标链执行**：在目标链执行 transfer / swap / protection 等动作
4. **前端展示**：通过 Dashboard、Rules、Live Trace 展示完整产品形态

一句话概括：

> 当 Sepolia 上出现风险事件时，Reactive Vault Sentinel 尝试在 Reactive Lasna 上判断规则，并在 Base Sepolia 上执行预定义保护动作。

---

## 2. 系统架构

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

### 2.1 三段式职责

#### Sepolia：事件源
负责产生日志事件，作为风控触发输入。

- `MockPriceFeed`：模拟价格变动
- `BalanceMonitor`：模拟余额变化 / 转出风险

#### Reactive Lasna：规则引擎
负责接收源链事件并在 Reactive 网络中判断是否命中规则。

- `VaultSentinelReactive`：规则注册、规则暂停/恢复、事件匹配、回调发射

#### Base Sepolia：执行层
负责接收回调并执行保护动作。

- `VaultExecution`：统一执行入口
- adapters：具体动作实现

---

## 3. 核心能力

### 3.1 规则类型

当前支持的规则类型：

- `PriceBelow`
- `PriceAbove`
- `TransferOutflow`

### 3.2 执行动作

当前支持的目标链动作：

- 基础转账：`BasicTransferAdapter`
- Uniswap 止损：`UniswapStopOrderAdapter`
- Aave 防护：`AaveProtectionAdapter`

### 3.3 前端演示能力

前端提供三个可演示页面：

- `/`：Dashboard
- `/rules`：Rule Configurator
- `/trace`：Live Trace

其中：

- Dashboard 展示整体产品形态与规则/事件概览
- Rules 支持 Demo 模式下本地模拟创建规则
- Live Trace 展示一条完整的跨链执行回放

---

## 4. 技术栈

### 合约侧

- Solidity `0.8.28`
- Foundry
- OpenZeppelin Contracts v5
- Reactive Lib

### 前端侧

- Next.js `14.1.4`
- React `18`
- TypeScript
- Tailwind CSS
- wagmi v2
- viem
- TanStack Query
- Framer Motion
- RainbowKit（依赖仍存在，但当前运行路径已不依赖其 UI 组件）

---

## 5. 仓库结构

```text
reactive-vault-sentinel/
├─ apps/
│  └─ web/                      # Next.js 14 演示前端
├─ contracts/                   # Foundry 合约、脚本、测试、.env
├─ packages/
│  ├─ abi/                      # 导出的 JSON ABI
│  └─ config/                   # 链与地址配置
├─ scripts/
│  ├─ contracts/                # 合约测试脚本
│  └─ e2e/                      # Step11 冒烟验证与排障材料
├─ package.json                 # workspace 根脚本
├─ pnpm-workspace.yaml
└─ README.md
```

### 5.1 合约目录

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

- `contracts/test/VaultSentinelReactive.t.sol`
- `contracts/test/ReactiveVaultFlow.t.sol`
- 以及 mocks / monitors / execution / adapters 相关测试

### 5.2 前端目录

主要入口：

- `apps/web/src/app/page.tsx`
- `apps/web/src/app/rules/page.tsx`
- `apps/web/src/app/trace/page.tsx`
- `apps/web/src/app/providers.tsx`

---

## 6. 已完成内容

### 6.1 合约与脚本

已完成并验证过的部分：

- 核心合约实现完成
- VaultExecution + adapters 执行层实现完成
- Foundry 单元测试通过
- Sentinel 规则初始化 / 触发逻辑测试通过
- Sepolia / Base Sepolia 部署脚本可运行
- Lasna 部署脚本已多轮排查与修正

### 6.2 前端

已完成并可用：

- Dashboard 页面
- Rule Configurator 页面
- Live Trace 页面
- 本地 Demo 模式
- 本地规则创建模拟
- 钱包连接入口 UI

### 6.3 集成与交付材料

已具备：

- `packages/abi/*` JSON ABI
- `scripts/e2e/smoke.sh`
- `scripts/e2e/step11-incident-evidence.txt`
- `scripts/e2e/step11-escalation-final.txt`

---

## 7. 当前状态与限制

这是最重要的一节。不要跳过。

### 7.1 已验证通过的内容

- `VaultSentinelReactive` 相关 Foundry 测试通过
- 前端 `pnpm dev:web` 可启动
- 前端页面可正常打开与交互
- Rules 页可以在 Demo 模式下创建模拟规则
- Live Trace 页面可播放模拟跨链流程
- Sepolia 源链事件发送与基础部署流程已验证
- Base Sepolia 执行层部署已验证

### 7.2 当前阻塞点

**Reactive Lasna 实链订阅链路未通过。**

在真实 Lasna 部署时，`VaultSentinelReactive` 的 `service.subscribe(...)` 调用会触发系统级失败，表现为：

- 合约构造可成功
- 进入订阅阶段时回滚
- 回滚路径落在 Lasna 系统合约 / `0x64` 自定义调用附近
- 这不是本地单测能覆盖的问题

因此，当前**不能宣称已经完成 Sepolia → Reactive Lasna → Base Sepolia 的真实链上闭环验收**。

### 7.3 这意味着什么

这意味着：

- 项目主体不是坏的
- 合约设计、测试、前端和部署脚本都已经成型
- 但 Reactive Lasna 当前 runtime / RPC / 系统订阅路径阻塞了最后一步

准确表述应该是：

> 本项目已完成 MVP 与大部分链路验证；Lasna 实链回调闭环目前受测试网环境 / RPC / 系统订阅失败阻塞，暂未完成最终链上验收。

---

## 8. 快速开始

### 8.1 安装依赖

在仓库根目录执行：

```bash
pnpm install
```

### 8.2 准备 Foundry

确认本机可用：

```bash
forge --version
cast --version
```

### 8.3 配置合约环境变量

复制环境文件：

```bash
cp contracts/.env.example contracts/.env
```

然后根据实际情况填写：

- `SEPOLIA_RPC_URL`
- `BASE_SEPOLIA_RPC_URL`
- `REACTIVE_RPC_URL`
- `OWNER`
- keystore / private key
- 已部署合约地址

说明：

- 当前仓库实际使用过的 Lasna RPC 为：`https://lasna-rpc.rnk.dev/`
- 但该 RPC / runtime 当前并不稳定，且是已知阻塞点之一

---

## 9. 常用命令

### 9.1 根目录

```bash
pnpm dev:web
pnpm build:web
pnpm lint:web
pnpm test:contracts
pnpm smoke:e2e
```

### 9.2 合约相关

```bash
pnpm --dir contracts exec forge build
pnpm --dir contracts exec forge test
```

### 9.3 前端相关

```bash
pnpm --filter @vault-sentinel/web dev
pnpm --filter @vault-sentinel/web build
pnpm --filter @vault-sentinel/web lint
```

---

## 10. 前端运行方式

在仓库根目录执行：

```bash
pnpm dev:web
```

启动成功后访问：

```text
http://localhost:3000
```

当前前端以 **Demo Mode** 为主，不依赖 Lasna 实链回调就可以展示主要产品流程。

### 当前已验证的前端页面

- `/` Dashboard：正常
- `/rules` Rule Configurator：正常
- `/trace` Live Trace：正常

### 当前已知前端小问题

不影响演示，但存在一些非阻塞问题：

- `grid.svg` 缺失导致首页背景资源 404
- `favicon.ico` 缺失导致浏览器资源 404
- Lasna explorer 地址配置仍可能指向旧测试网地址，需要后续修正

---

## 11. 合约测试与 E2E

### 11.1 合约测试

运行：

```bash
pnpm test:contracts
```

或：

```bash
pnpm --dir contracts exec forge test
```

### 11.2 E2E 冒烟验证

运行：

```bash
pnpm smoke:e2e
```

其核心脚本为：

- `scripts/e2e/smoke.sh`

用途：

- 从 Sepolia 触发源事件
- 观察 Lasna 是否出现回调痕迹
- 检查 Base Sepolia 执行链路

当前结论：

- Sepolia 源事件可观察到
- Lasna 回调事件当前未稳定出现
- 因此 Step11 仍处于阻塞态

---

## 12. 部署说明

### 12.1 目标网络

- Sepolia：源链事件
- Base Sepolia：目标链执行
- Reactive Lasna：规则判断 / callback 发射

### 12.2 脚本

- `contracts/script/DeploySepolia.s.sol`
- `contracts/script/DeployBaseSepolia.s.sol`
- `contracts/script/DeployLasna.s.sol`

### 12.3 当前部署现实

- Sepolia / Base Sepolia 路径已具备可重复部署基础
- Lasna 路径当前仍可能因系统订阅失败而回滚

因此，当前部署状态应理解为：

- **Sepolia / Base：可继续联调**
- **Lasna：当前受外部测试网环境阻塞**

---

## 13. 演示模式说明

当前最稳的演示方式，不是硬讲实链全通，而是：

- 用前端展示产品完整形态
- 用 Demo Mode 演示规则配置
- 用 Live Trace 演示完整业务路径
- 用 README / 排障包诚实说明 Lasna 阻塞原因

这比硬编一个“已经全打通”的故事靠谱得多。

---

## 14. 如何演示

下面是一套可直接对评审/面试官/黑客松评委使用的演示顺序。

### 第一步：启动前端

```bash
pnpm install
pnpm dev:web
```

打开：

```text
http://localhost:3000
```

### 第二步：展示 Dashboard

进入首页 `/`，重点说明：

- 这是一个跨链自动化风控系统
- 事件来自 Sepolia
- 规则在 Reactive Network 上判断
- 动作在 Base Sepolia 执行

可展示内容：

- Overview 卡片
- Active Sentinel Rules
- Live Event Feed
- Demo Mode 提示

推荐话术：

> 这里展示的是整个产品的控制台视角。用户在源链配置监控规则，一旦事件触发，Reactive 网络负责判断是否命中策略，随后在目标链执行保护动作。

### 第三步：展示 Rules 页面

进入 `/rules`，重点展示：

- 当前规则列表
- 模板入口
- Rule Wizard
- Demo 模式下的本地模拟创建

实际操作建议：

1. 点击 `New Rule`
2. 选择默认 Source Chain / Asset
3. 继续到条件页
4. 输入一个阈值，例如 `1234`
5. 点击 `Simulate Rule Deployment`

成功后页面会出现 toast：

- `Sentinel rule simulated successfully!`

规则列表数量会增加，可直接作为“交互完成”的可视结果。

推荐话术：

> 这里我演示的是规则配置层。当前 Demo 模式不会依赖链上真实回调，所以我们可以稳定展示用户如何定义触发条件和目标动作。

### 第四步：展示 Live Trace

进入 `/trace`，说明：

- 这是整个 Sepolia → ReactVM → Base Sepolia 的执行回放
- 当前是 **模拟 trace**，不是实时 Lasna 链上回放
- 它用于展示产品逻辑闭环和用户可理解的执行路径

推荐强调：

- Phase 01：源链事件
- Phase 02：Reactive VM 判断
- Phase 03：目标链执行

推荐话术：

> 这里展示的是完整业务闭环：在源链发现风险事件后，Reactive 网络进行规则判断，再将回调发送到目标链执行保护动作。当前页面展示的是 replay 版 trace，用于稳定演示完整流程。

### 第五步：诚实说明当前未完成项

最后一定要讲清楚：

- 合约和前端主体已完成
- 本地演示与大多数工程能力已验证
- 当前未完成的是 **Lasna 实链最终回调闭环验收**
- 原因不是本地前端挂了，而是 Reactive Lasna 当前订阅路径回滚

推荐总结话术：

> 当前 MVP、前端演示、规则配置、合约测试和多链部署基础能力都已经完成。最后一步实链闭环被 Lasna 测试网的系统订阅失败阻塞，所以现场我用 Demo Mode 和 Trace Replay 展示完整产品形态，同时保留真实链上联调结果与排障证据。

---

## 15. 不要夸大的边界

演示时不要说以下话：

- “已经全链路实链打通”
- “Lasna 已稳定完成 callback”
- “Step11 已完全通过”

更准确的说法是：

- “本地 MVP 与前端演示已完成”
- “Sepolia / Base 路径已基本验证”
- “Lasna 最后一段实链闭环当前受测试网环境阻塞”

---

## 16. 后续工作建议

如果继续推进，优先级建议如下：

1. 修复 /确认 Lasna `service.subscribe(...)` 系统级失败原因
2. 与 Reactive 团队确认 Lasna RPC / runtime / system contract 状态
3. 完成 Step11 实链闭环复测
4. 将前端切换为真实地址模式
5. 修复前端静态资源缺失（`grid.svg` / `favicon.ico`）
6. 修正 Lasna explorer 地址

---

## 17. 结论

Reactive Vault Sentinel 目前已经是一个**可运行、可测试、可演示、可继续联调**的 MVP 仓库。

它已经完成了：

- 产品结构
- 合约骨架
- 测试体系
- 前端 Demo
- 多链部署基础

它尚未完成的，是 **Reactive Lasna 测试网环境上的最后一段真实闭环验收**。

这不是“项目没做完”，而是“最后一段实链依赖当前被测试网环境卡住”。

对黑客松交付来说，这个状态是可以说明、可以展示、也可以继续推进的。