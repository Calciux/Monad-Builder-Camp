# Monad Builder Camp — 学习计划

> 程序全称：Web3 Summer Internship Program – Monad Builder Camp
> 时间：2026-07-06 ~ 2026-08-07（4 周必修 + 1 周可选）
> 结构：3 周共学/分轨/协作 + 1 周 Hackathon + 1 周作品集 Workshop
> 个人仓库：https://github.com/Calciux/Monad-Builder-Camp

---

## 程序总览

| Week | 日期 | 主题 | 核心产出 |
|:----:|------|------|----------|
| 1 | Jul 6–11 | 共同底座 — Enter Onchain World | Build Log + Mini Demo 0 |
| 2 | Jul 13–18 | Track Split — 选方向出 Proof of Work | 方向产出（Repo/Demo/文档/方案） |
| 3 | Jul 20–25 | Builder Collaboration & Mini Demo | 团队 Prototype + Mini Demo 展示 |
| 4 | Jul 27–Aug 1 | Monad Hackathon Week | 可运行产品 + Pitch Deck + Demo Video |
| 5 | Aug 3–7 | Portfolio & Resume（可选） | 作品集 + 简历 Bullet Point |

---

## Week 1 — 共同底座：Enter Onchain World

> 目标：建立 Web3 和链上世界的基本认知，完成钱包、链上交互、Monad 生态和 AI 工具使用的基础准备。
> 参考资料：[Web3 实习手册](https://web3intern.xyz/zh/) | [Monad Docs](https://docs.monad.xyz/) | [BuildAnything Freshman](https://buildanything.so/zh/tracks/freshman)

### Day 1 — 开营与 Web3 入门：我为什么要进入链上世界？

**学习目标：**
- 理解 Web3、区块链、以太坊、钱包、地址、交易、gas、智能合约等基础概念
- 完成开营内容，明确本周要留下的 Proof of Work
- 建立 Week 1 Build Log，记录每日学习、截图、链接、Prompt、错误和修复过程

**学习任务：**

| # | 内容 | 资源 | 产出 |
|---|------|------|------|
| 1.1 | Web3 实习手册入门导读 | [前言/导读](https://web3intern.xyz/zh/preface/) → [区块链基础](https://web3intern.xyz/zh/blockchain-basic/) → [以太坊概览](https://web3intern.xyz/zh/overview-of-ethereum/) | 概念笔记 |
| 1.2 | BuildAnything Freshman — Vibecoding 入门 | [intro-to-vibecoding](https://buildanything.so/zh/tracks/freshman/lessons/introduction-to-vibecoding) → [为什么要构建 DApp](https://buildanything.so/zh/tracks/freshman) | 理解记录 |
| 1.3 | 创建 Week 1 Build Log | 在本仓库 `daily/2026-07-06.md` | Build Log 文件 |

**交付物：**
- [ ] `daily/2026-07-06.md` — Day 1 Build Log
- [ ] 概念笔记：Web3/区块链/以太坊 基础术语表

---

### Day 2 — 工具准备与 Builder 身份：我如何开始远程协作？

**学习目标：**
- 完成 Web3 常用工具安装和账号准备
- 理解 DevRel / Builder / 生态连接者角色
- 参与 Co-learning，把学习记录变成可持续的公开 Proof of Work

**学习任务：**

| # | 内容 | 资源 | 产出 |
|---|------|------|------|
| 2.1 | Web3 工作方式 & 工具安装指南 | [远程工作指南](https://web3intern.xyz/zh/remote-work-guide/) | 工具清单 |
| 2.2 | Web3 岗位全景图 | [岗位介绍](https://web3intern.xyz/zh/position-introduction/) | 角色理解笔记 |
| 2.3 | 工具准备确认 | X / Telegram / Discord / GitHub / Notion / AI Coding 工具（Cursor/Claude Code/Codex） | 账号就绪 |

**交付物：**
- [ ] `daily/2026-07-07.md` — Day 2 Build Log
- [ ] 工具清单 & 岗位认知笔记

---

### Day 3 — 钱包、安全与第一笔测试网交易：我如何留下第一条链上记录？

**学习目标：**
- 创建**课程专用钱包**（不使用主力钱包做课程实验）
- 添加 Monad Testnet，领取测试资产
- 完成第一笔测试网交易或应用交互
- 学会用 Block Explorer 解释一笔交易

**学习任务：**

| # | 内容 | 资源 | 产出 |
|---|------|------|------|
| 3.1 | 安全与合规 | [Web3 实习手册 - 安全](https://web3intern.xyz/zh/security/) | 安全检查清单 |
| 3.2 | 加密钱包基础 | [Ethereum Wallets](https://ethereum.org/en/wallets/) + [Transactions](https://ethereum.org/en/developers/docs/transactions/) + [Gas](https://ethereum.org/en/developers/docs/gas/) | 概念笔记 |
| 3.3 | Monad Testnet 配置 | [Monad Testnets](https://docs.monad.xyz/developer-essentials/testnets) + [Block Explorers](https://docs.monad.xyz/tooling-and-infra/block-explorers) | 钱包配置截图 |
| 3.4 | 实操：创建钱包 → 领水 → 转账 → 查看 Explorer | MetaMask/Rabby + Monad 水龙头 | Tx Hash 记录 |

**交付物：**
- [ ] `daily/2026-07-08.md` — Day 3 Build Log（含 Tx Hash + Explorer 链接）
- [ ] 课程专用钱包地址记录
- [ ] 安全自检清单

---

### Day 4 — AI + Solidity + 合约部署：我如何从交易进入最小合约实践？

**学习目标：**
- 用 AI 生成一个最小 Solidity 合约，**但不盲信 AI 输出**
- 在 Remix 中编译、检查、部署或交互合约
- 理解合约源码、ABI、合约地址、read/write function 和 Tx Hash 之间的关系

**学习任务：**

| # | 内容 | 资源 | 产出 |
|---|------|------|------|
| 4.1 | 智能合约开发入门 | [实习手册-合约开发](https://web3intern.xyz/zh/smart-contract-development/) + [Solidity Docs](https://docs.soliditylang.org/) | 概念笔记 |
| 4.2 | Remix + Monad 部署指南 | [Monad Remix Guide](https://docs.monad.xyz/guides/deploy-smart-contract/remix) | 操作截图 |
| 4.3 | AI 生成 + 人工审查合约 | 用 Cursor/Claude Code 生成一个最小合约（如 SimpleStorage），审查后部署到 Monad Testnet | 合约源码 + 部署 Tx Hash |
| 4.4 | BuildAnything — 构建你的第一个 DApp | [Freshman Track](https://buildanything.so/zh/tracks/freshman) | DApp 交互记录 |

**交付物：**
- [ ] `daily/2026-07-09.md` — Day 4 Build Log
- [ ] 合约源码文件（`contracts/SimpleStorage.sol`）
- [ ] 部署 Tx Hash + Explorer 链接
- [ ] AI Prompt 记录 & 人工修改记录

---

### Day 5 — Monad 理解、Build Log 与 Mini Demo 0：我如何总结第一周并选择方向？

**学习目标：**
- 理解 Monad 不为什么只是"更快"——而是可能改变高频交互产品体验
- 把 Week 1 的钱包、交易、合约、AI 协作和安全记录整理成 Build Log
- 提交 Mini Demo 0
- 选择 Week 2 主方向：Tech / Ops / Research

**学习任务：**

| # | 内容 | 资源 | 产出 |
|---|------|------|------|
| 5.1 | Monad vs Ethereum 差异 | [Differences](https://docs.monad.xyz/developer-essentials/differences) + [Best Practices](https://docs.monad.xyz/developer-essentials/best-practices) + [Gas Pricing](https://docs.monad.xyz/developer-essentials/gas-pricing) | 对比笔记 |
| 5.2 | Monad 架构理解：为什么 10,000 TPS 让什么成为可能？ | BuildAnything — 什么是 Monad？10,000 TPS 会让什么成为可能 | 分析笔记 |
| 5.3 | 行业赛道全览 | [行业知识](https://web3intern.xyz/zh/industry-knowledge/) + [社区运营指南](https://web3intern.xyz/zh/community-intern/) | 赛道地图 |
| 5.4 | Build Log 整理 | 汇总 Week 1 全部产出 → `weekly/week1-summary.md` | Week 1 总结 |
| 5.5 | Mini Demo 0 提交 + Week 2 方向选择 | 决定 Tech/Ops/Research | Mini Demo 0 + 方向声明 |

**交付物：**
- [ ] `daily/2026-07-10.md` — Day 5 Build Log
- [ ] `weekly/week1-summary.md` — Week 1 总结（含所有 Tx Hash + 截图索引）
- [ ] `notes/monad-architecture.md` — Monad 架构对比笔记
- [ ] Mini Demo 0（Week 1 产出展示）
- [ ] Week 2 Track 选择声明

---

## Week 2 — Builder Track Split：选择 Web3 职业路径

> 目标：不是单纯学习知识，而是留下可验证的 Proof of Work（Repo / Demo / 研究文档 / 运营方案 / 内容稿件 / 数据记录）

### 三大方向

| Track | 做什么 | 适合谁 |
|-------|--------|--------|
| 🛠️ Tech | 使用 AI Coding 工具完成产品原型、前端、智能合约或链上交互功能开发 | 想写代码、做产品 |
| 📢 Ops | 围绕产品进行社群运营、活动设计、用户反馈、传播内容制作和增长实验 | 想做社区/增长 |
| 🔍 Research | 围绕项目方向、生态案例、用户需求和赛道判断产出研究材料与分析报告 | 想做研究/分析 |

### 方向选择说明

Week 1 Day 5 时根据 Week 1 体验决定，以下为预置分析：

**Monad Builder Camp 可选方向**（来自报名表 option）：
1. Monad 基础开发学习
2. 智能合约开发
3. Monad 治理框架
4. Monad 生态项目协作
5. Hackathon 项目孵化
6. Builder Networking
7. **AI × Web3 方向探索** ← Monad 有 ERC-8004（Trustless Agents）+ x402/MPP（Agentic Payments）原生支持
8. 其他

**详细周计划将在 Week 1 Day 5 确定方向后展开。**

---

## Week 3 — Builder Collaboration & Mini Demo Week

> 目标：不同方向的学员围绕一个产品想法共同协作，将前两周学习成果整合为可展示的 Prototype

### 本周重点

1. 组队与角色分工
2. 产品方向收敛
3. Demo 原型开发
4. 用户场景与传播叙事打磨
5. Mini Demo 展示与反馈
6. 为 Week 4 Hackathon 做准备

### Hackathon 筹备组（可选）

运营方向学员可加入 Hackathon 筹备组：
- 活动规则设计 / 赛道说明编写 / 时间线规划 / 提交要求制定
- 社群运营 / FAQ 整理 / DDL 提醒
- Demo Day 筹备 / 活动复盘材料

**详细日计划将在 Week 3 开始前展开。**

---

## Week 4 — Monad Builder Season & Hackathon Week

> 主题：From Prototype to Product — Ship on Monad

### 最终交付成果

| 交付物 | 说明 |
|--------|------|
| 可运行产品链接或 Repo | 部署到 Monad 的可用产品 |
| 合约地址 + Tx Hash + Explorer 链接 | 链上可验证证据 |
| Pitch Deck | 项目展示 PPT |
| 2–5 分钟 Demo Video | 产品演示视频 |
| Final Presentation | Demo Day 展示用 |

### 评审维度

| 维度 | 权重 |
|------|:----:|
| 产品完成度 | 高 |
| Monad Native 程度 | 高 |
| 用户体验 | 中 |
| 传播潜力 | 中 |
| 团队协作 | 中 |
| 作品集价值 | 中 |

**详细 Hackathon 计划将在 Week 3 结束后展开。**

---

## Week 5 — 作品集与简历 Workshop（可选）

> 目标：把训练营成果转化为可展示、可验证、可传播的职业材料

### 产出物

- 项目作品集页面（Portfolio）
- GitHub / Demo / Pitch Deck / 视频链接整理
- 简历 Bullet Point
- 个人学习日志
- 研究或运营案例
- 可公开展示的 Web3 Proof of Work

---

## 仓库结构规划

```
Monad-Builder-Camp/
├── learning-plan.md          # 本文件
├── daily/                    # 每日 Build Log
│   ├── 2026-07-06.md         # Day 1
│   ├── 2026-07-07.md         # Day 2
│   └── ...
├── weekly/                   # 每周总结
│   ├── week1-summary.md
│   └── ...
├── notes/                    # 概念笔记
│   ├── web3-fundamentals.md
│   ├── monad-architecture.md
│   └── ...
├── contracts/                # 合约源码（Week 1+）
│   └── ...
├── experiments/              # 实验记录（链上交互、部署）
│   └── ...
├── hackathon/                # Hackathon 产出（Week 3-4）
│   └── ...
└── portfolio/                # 作品集材料（Week 5）
    └── ...
```

## 学习节奏

- **每日投入**：2-3 小时
- **每日产出**：一个 Build Log 文件（daily/YYYY-MM-DD.md）
- **每周产出**：一个 Week Summary + 对应 Demo/文档/代码
- **关键习惯**：截图每个关键步骤、保存每个 Tx Hash、记录每个 AI Prompt

---

## 参考资料索引

### Week 1 核心资料
- Web3 实习手册：https://web3intern.xyz/zh/
- Monad Docs：https://docs.monad.xyz/
- Monad Testnet：https://docs.monad.xyz/developer-essentials/testnets
- BuildAnything Freshman：https://buildanything.so/zh/tracks/freshman
- Remix IDE：https://remix.ethereum.org/
- Monad Remix 部署指南：https://docs.monad.xyz/guides/deploy-smart-contract/remix
- Ethereum 官方文档：https://ethereum.org/en/developers/docs/
- Solidity Docs：https://docs.soliditylang.org/
- OpenZeppelin：https://docs.openzeppelin.com/contracts/

### Monad 生态资料（进阶参考）
- ERC-8004 指南：https://docs.monad.xyz/guides/erc-8004
- Agentic Payments：https://docs.monad.xyz/tooling-and-infra/agentic-payments.md
- Monad MCP Server：https://docs.monad.xyz/guides/monad-mcp.md
- Monad vs Ethereum：https://docs.monad.xyz/developer-essentials/differences
- Block Explorers：MonadVision / Monadscan / Gmonads

---

> **声明：** 本学习计划基于 Web3 Career Build 平台「Web3 Summer Internship Program – Monad Builder Camp」课程页面（https://web3career.build/en/programs/Web3-Summer-Intership-Progra?tab=learning）的实际课程结构编写。Week 1 为逐日详细计划，Week 2-5 为框架性规划，将在各自阶段开始前展开为逐日计划。
