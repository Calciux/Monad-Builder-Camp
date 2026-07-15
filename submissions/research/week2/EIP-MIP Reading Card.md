# EIP / MIP Reading Card — Week 2

## 提案名称和编号

**ERC-8183: Agentic Commerce**（原名 EIP-8183，重新编号为 ERC-8183）

---

## 提案原文链接

- 规范原文：https://eips.ethereum.org/EIPS/eip-8183
- 讨论帖：https://ethereum-magicians.org/t/erc-8183-agentic-commerce/27902
- 状态：Draft（草案，2026-02-25 创建），Standards Track: ERC
- 依赖：EIP-20（ERC-20 代币标准）
---

## 背景问题

**提案出现前的问题：**

1. **AI Agent 缺乏标准化的链上支付通道。** 当一个 AI Agent（作为服务提供者）为另一个 Agent 完成工作后，如何完成「交付→验收→付款」没有统一标准。每个项目都要自己写托管合约、支付路由、纠纷仲裁。

2. **Agent 间交易的信任问题。传统解法是引入可信第三方仲裁，但这又回到中心化。

3. **合约复杂度蔓延。** 现有的托管方案往往把支付、验证、惩罚、声誉混在一个大合约里，导致接口膨胀、审计成本高、难以组合。

4. **缺乏可组合的扩展点。** 如果想在托管流程中加入 KYC 检查、声誉信号、竞价拍卖等自定义逻辑，通常需要 fork 或继承核心合约——破坏了标准化。

---

## 核心方案

一个最小化的标准化链上任务托管协议：Client 锁定预算 → Provider 提交工作 → Evaluator 裁决放款或退款。以Hook机制在流程中调用其他协议提升可扩展性.


---

## 关键术语

| Term | Definition |
|------|------------|
| **Job** | An on-chain task with an escrowed budget, going through Open → Funded → Submitted → Terminal lifecycle |
| **Client** | The party that creates the job, sets budget, and funds escrow |
| **Provider** | The party that performs the work, submits deliverables, and receives payment |
| **Evaluator** | The single attester who alone may call complete (release funds) or reject (refund); may be the Client or a smart contract |
| **Escrow** | The contract holding Client's funds after `fund()`; only the Evaluator's decision or expiry can move them |
| **Hook** | An optional external contract (IACPHook) called before/after 6 core functions; `claimRefund` SHALL NOT be hookable |
| **Expiry** | After `expiredAt`, anyone may call `claimRefund` to trigger a refund — the permissionless safety bottom line |
| **Platform Fee** | Deducted only on `complete()` from Provider's payout, in basis points; not charged on refund |
| **Deliverable** | A `bytes32` reference to submitted work (e.g., hash of off-chain deliverable, IPFS CID, attestation commitment) |
| **Expected Budget** | Passed to `fund(jobId, expectedBudget)`; reverts if `job.budget != expectedBudget` — front-running protection |
| **RFC 2119** | The authoritative source for MUST / SHALL / SHOULD / MAY keyword interpretation in EIPs |



---

## 争议与风险

### 1. 单点裁决者（Evaluator Centralization）
一旦进入 Submitted 状态，只有 Evaluator 能裁决。恶意 Evaluator 可以无限期不为 Provider 放款，或错误地 reject 优质工作。规范对此的说法是："Evaluator is trusted"——用声誉（ERC-8004）或质押解决, 不属于本规范的范围.但这可能是一个很难解决的问题.

### 2. 无纠纷仲裁机制
reject/expire 就是终局，没有上诉路径。被 reject 的 Provider 无法申诉，也没有链上 dispute resolution。这对高价值交易构成风险。


### 3. Hook 的安全边界
Hook 合约由 Client 在创建时指定，是**受信任的**。恶意或 buggy Hook 可以：
- revert 所有 hookable 操作（阻塞任务进程）
- 在 callback 中执行任意逻辑
`claimRefund` 是不可 Hook 的底线保护——但如果 Hook 在 fund 阶段就做了恶意操作，退款的只是核心资金，Hook 内的额外资产可能仍被锁定。

---

## 产品启发

### 对 AI × Web3 方向的启发

1. **AI Agent 市场的基础设施层。** 如果每个 AI Agent 服务（代码审查、翻译、数据分析）都通过 ERC-8183 收款，就会出现一个统一的链上 Agent 服务市场。

2. **Facilitator 模式（ERC-2771）。** 配合 x402 + ERC-2771，AI Agent 只需要私钥和代币——不需要管理 gas、RPC、链上细节。Agent 签离链意图，Facilitator 代为上链。


### 对这个设计模式的推广思考

ERC-8183 的 Hook 机制类似 HTTP 中间件——不改变核心，但允许在 request/response 前后插入任意逻辑。这个模式可以推广到：
- 链上订阅支付（Subscription escrow with recurring hooks）
- 多签审批的工作流（Hook 收集 M 个签名才放行 fund）
- 跨链托管（Hook 验证目标链的 event 才 complete）

---

## 你的疑问
1. **恶意行为的可能性**:在这份合约的设计中, 有多个可以明显被攻击的点.例如:provider 可在 client 出资前抢跑修改预算、零预算任务可绕过付款直接进入完成状态，以及 setProvider() 可绕过 Hook 的签名与竞价验证。管理员还可在任务出资后修改费用、将平台费提高至 100%，并通过 UUPS 升级完全控制合约资金。除此之外，到期后的完成与退款存在抢跑竞争，恶意 evaluator、Hook 和非标准 ERC-20 也可能导致错误付款、任务阻塞或资金亏空。

2. **Token 灵活性。** 规范规定单合约单代币（"one token per contract"），是否考虑过 per-job 的代币选择？这对 USDC/USDT/DAI 共存的市场很重要——现在每个代币都要部署一个合约。


