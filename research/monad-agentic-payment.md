# Monad Agentic Payment 基础设施调研

> 日期：2026-07-10 | 目的：为后续 Course 任务选型

---

## 三层架构总览

```
Layer 1: x402 Protocol     HTTP 402 → 签名支付 → 内容交付
Layer 2: MPP SDK           @monad-crypto/mpp（Pull/Push 模式）
Layer 3: Onchain            USDC + ERC-3009 合约结算
```

---

## Layer 1: x402（HTTP 402 Payment Required）

将 HTTP 402 状态码变成互联网原生微支付协议。

**流程**：
```
Client → GET /api/premium → Server
Client ← 402 Payment Required (含 payment requirement JSON) ← Server
Client → 签名支付授权 → Server
Client ← 200 OK + 内容 ← Server
         ↓
    Monad x402 Facilitator
    ├─ POST /verify (验证签名)
    └─ POST /settle (链上结算 USDC)
```

**Monad x402 Facilitator**：
- URL: `https://x402-facilitator.molandak.org`
- 支持 Mainnet (chain 143) + Testnet (chain 10143)
- 两种 scheme：`exact`（精确金额）+ `upto`（上限授权）
- Signer: `0x7f6a2850669202519f0FE8aa912451238820Db86`
- 结算 token: USDC
- Facilitator 代付 Gas

**SDK**: `@x402/core` `@x402/evm` `@x402/fetch` `@x402/next`

**参考**：
- Monad docs: https://docs.monad.xyz/tooling-and-infra/agentic-payments
- x402 guide: https://docs.monad.xyz/guides/x402
- x402.org

---

## Layer 2: MPP（Machine Payments Protocol）

**`@monad-crypto/mpp`** npm 包，实现 Monad 上的程序化支付。

**两种结算模式**：

| 模式 | 谁广播交易 | 协议 |
|:---|:---|:---|
| **Pull**（默认） | 服务端 | ERC-3009 签名授权 → 服务端调 `receiveWithAuthorization` |
| Push | 客户端 | 客户端直接广播 ERC-20 transfer |

**服务端示例**：
```typescript
import { monad } from "@monad-crypto/mpp/server";
import { Mppx } from "mppx";

const mppx = await Mppx.create({
  methods: { monad({ account, recipient, testnet: true }) }
});

// 中间件：未支付返回 402，已支付放行
app.get("/premium", mppx.charge(), (c) => c.json({ message: "Premium content" }));
```

**参考**：
- MPP Overview: https://docs.monad.xyz/reference/mpp/overview
- MPP API: https://docs.monad.xyz/reference/mpp/api
- MPP monad method: https://mpp.dev/payment-methods/monad
- GitHub: https://github.com/monad-crypto/monad-ts/tree/main/packages/mpp

---

## Layer 3: 合约层（USDC + ERC-3009）

**Monad Testnet USDC**: `0x534b2f3A21130d7a60830c2Df862319e593943A3`
- 领取: https://faucet.circle.com（选择 USDC → Monad Testnet）
- 限制: 每 2 小时 1 USDC

**ERC-3009**: 带授权的转账标准
- 用户签名授权（不广播交易）
- 第三方（Facilitator/服务端）调用 `receiveWithAuthorization` 执行转账
- 这就是 MPP Pull 模式的底层合约机制

---

## 后续计划：三层穿透演示

目标：一个任务覆盖全部三层。

| 步骤 | 对应 Layer | 内容 |
|:---|:---|:---|
| 1 | L1 | 搭建 x402 付费 HTTP 端点（Next.js + @x402/next） |
| 2 | L1 | 验证 402→签名→内容交付 协议流程 |
| 3 | L2 | 后端用 @monad-crypto/mpp 处理 ERC-3009 授权（Pull 模式） |
| 4 | L3 | 在 Monad 区块浏览器验证 USDC transfer + receiveWithAuthorization |
| 5 | - | 记录完整链上证据（Tx hash、合约地址） |

**前置准备**：
- 领取 Monad Testnet USDC（Circle Faucet）
- 领取 Monad Testnet MON（Gas）
- 初始化 Next.js 项目
- 安装 @x402/* + @monad-crypto/mpp + mppx
