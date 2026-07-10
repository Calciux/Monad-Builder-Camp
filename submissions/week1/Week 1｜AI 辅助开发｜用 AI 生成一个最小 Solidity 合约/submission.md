# Week 1｜AI 辅助开发｜用 AI 生成一个最小 Solidity 合约

> 合约方向：投票合约（Voting Contract）
> 工作流：Plan Agent → Implement Agent → Review Agent（三阶段子 Agent 管道）
> 提交时间：2026-07-10 | Monad Builder Camp Week 1

---

## 工作流总览

```
Prompt Agent（主 Agent：写 prompt，不写代码）
  │
  ├── Phase 1: Plan Agent   → plan-output.md（288 行设计文档）
  ├── Phase 2: Implement Agent → Voting.sol（73 行合约代码）
  └── Phase 3: Review Agent → review-output.md（120 行审查报告）
```

三个 prompt 的完整文本见：[prompt.md](./prompt.md)

---

## Phase 1: Plan Agent 产出

完整设计文档：[plan-output.md](./plan-output.md)

### 核心设计决策

| 决策 | 理由 |
|:---|:---|
| 状态隐式推导（不用 enum） | 节省存储，避免同步错误，通过 `block.timestamp >= deadline` 判定 |
| 选项文本不存链上 | 仅通过 `PollCreated` 事件 emit，省 gas + 省代码行数 |
| `exists` 字段防伪 | 区分「不存在的 poll」和「零值 poll」，避免 pollId=0 误判 |
| 双层 mapping 防重复 | `hasVoted[pollId][voter]` 实现每地址每投票限投一次 |

---

## Phase 2: Implement Agent 产出

完整合约代码：[Voting.sol](./Voting.sol)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Poll {
        string description;
        uint256 deadline;
        uint256 optionCount;
        bool exists;
    }

    uint256 public pollCount;
    mapping(uint256 => Poll) public polls;
    mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event PollCreated(
        uint256 indexed pollId,
        string description,
        string[] options,
        uint256 deadline
    );
    event Voted(
        uint256 indexed pollId,
        address indexed voter,
        uint256 optionIndex
    );

    function createPoll(
        string calldata _description,
        string[] calldata _options,
        uint256 _durationMinutes
    ) external returns (uint256 pollId) {
        require(_options.length >= 2, "need at least 2 options");
        require(_durationMinutes > 0, "duration must be > 0");

        pollId = pollCount;
        pollCount++;

        uint256 deadline = block.timestamp + _durationMinutes * 1 minutes;

        polls[pollId] = Poll({
            description: _description,
            deadline: deadline,
            optionCount: _options.length,
            exists: true
        });

        emit PollCreated(pollId, _description, _options, deadline);
    }

    function vote(uint256 _pollId, uint256 _optionIndex) external {
        Poll storage poll = polls[_pollId];
        require(poll.exists, "poll not found");
        require(block.timestamp < poll.deadline, "poll ended");
        require(!hasVoted[_pollId][msg.sender], "already voted");
        require(_optionIndex < poll.optionCount, "invalid option");

        voteCounts[_pollId][_optionIndex]++;
        hasVoted[_pollId][msg.sender] = true;

        emit Voted(_pollId, msg.sender, _optionIndex);
    }

    function getResult(uint256 _pollId)
        external
        view
        returns (uint256[] memory results)
    {
        Poll storage poll = polls[_pollId];
        require(poll.exists, "poll not found");

        results = new uint256[](poll.optionCount);
        for (uint256 i = 0; i < poll.optionCount; i++) {
            results[i] = voteCounts[_pollId][i];
        }
    }
}
```

### Plan → Implement 对齐验证

| Plan 要求 | 代码行号 | 状态 |
|:---|:---|:---|
| Poll struct 四字段 | 5-10 | ✅ |
| 4 个全局状态变量（全部 public） | 12-15 | ✅ |
| 2 个事件（indexed 字段一致） | 17-27 | ✅ |
| 3 个函数（签名完全一致） | 29-76 | ✅ |
| 6 条 revert 消息（逐字一致） | 34,35,54-57,70 | ✅ |
| 选项文本不存链上（仅 event emit） | 45,49 | ✅ |
| 行数 ≤80 | 73 行 | ✅ |

---

## Phase 3: Review Agent 产出

完整审查报告：[review-output.md](./phase3-review/review-output.md)

### 审查摘要

| 维度 | 权重 | 结论 |
|:---|:---|:---|
| 完整性 | ⭐⭐⭐ | ✅ 全部 12 项 Plan 要求均已实现 |
| 正确性 | ⭐⭐⭐ | ✅ 14 项行为检查全部对齐，revert 消息逐字一致 |
| 安全性 | ⭐⭐⭐ | ✅ 无重入风险（CEI 模式），溢出保护（0.8.0），重复投票防护正确 |
| Gas 效率 | ⭐⭐ | ✅ 选项不存链上，无冗余存储 |
| 代码质量 | ⭐ | ✅ 命名清晰，结构分组合理 |

**问题分级**：❌严重 0 / ⚠️重要 0 / 🔧建议 2

**最终判定**：✅ **通过** — 代码完全对齐 Plan，无需修改即可部署

### Review 发现的 2 个建议项

1. **getResult 截止检查**：当前允许随时查询实时票数。若产品要求「截止后才能查看最终结果」，需补充 `require(block.timestamp >= poll.deadline)`——非代码缺陷，设计意图确认问题
2. **缺少注释**：建议在关键逻辑处添加简短注释

---

## 4. 人工检查（至少 3 个关键点）

> 阅读 Review Agent 审查报告后，我的判断：

| # | 检查项 | Review 怎么说 | 我的判断 | 行动 |
|:---|:---|:---|:---|:---|
| 1 | getResult 截止检查 | 允许随时查询，需确认设计意图 | Plan 明确写了「Active 时也可查询实时票数」，当前行为正确。不需要改 | 无 |
| 2 | 注释缺失 | 建议在关键逻辑添加注释 | 73 行代码结构清晰，变量命名自文档化，不需要额外注释 | 无 |
| 3 | block.timestamp 可被矿工微调（±15秒） | 公链固有特性，非合约缺陷 | 投票截止时间通常以天计，±15 秒偏差在实际使用中无影响 | 无 |

---

## 5. 修改记录 & 判断

本次工作流中，Implement Agent 产出的代码与 Plan Agent 的设计文档**完全对齐**——零偏差。

**未做任何修改。**

这证明了三阶段管道（Plan → Implement → Review）的有效性：当 Plan 足够精确时，Implement 可以一次产出符合规范的代码，Review 只需要确认对齐，不需要进入 Review → Implement 修复循环。

---

## 6. 工作流复盘

### 各 Agent 表现

| Agent | 耗时 | 产出 | 评价 |
|:---|:---|:---|:---|
| Plan Agent | 133s | 288 行设计文档 | 质量高，覆盖状态机/数据结构/函数规格/事件/设计权衡/规模估算 |
| Implement Agent | 27s | 73 行合约代码 | 严格对齐 Plan，revert 消息逐字一致，CEI 模式正确 |
| Review Agent | 91s | 120 行审查报告 | 五维度审计覆盖全面，证据链清晰（行号引用），建议项区分 Plan 问题 vs Implement 问题 |

### Prompt 质量自评

三个 prompt 使用了 §-style 章节式结构（角色定义 → 背景 → 任务 → 约束 → 交付物），这是从 Cobo Hackathon 的 subagent-driven-development 工作流中积累的模式。对于「最小合约」这个任务规模，§1-§5 的 prompt 深度已足够——Implement Agent 27 秒完成，无需任何修复循环。

### 人工介入的价值

本次工作流中，人工的介入点不在「修改代码」，而在：
1. **确认设计意图**：Review 提出的 getResult 截止检查建议，我对照 Plan 原文确认了「Active 时可查询实时票数」的设计意图——这是 AI 无法代劳的决策
2. **判断建议的优先级**：两个 🔧 建议我判断为「不需要改」，这需要人对合约用途和使用场景的理解

---

---

## Phase 2：Foundry 单元测试

> 四阶段：Plan Agent → Implement Agent → Review Agent → Executor Agent

### 2-1. Plan Agent Prompt（测试设计）

```
§1. 角色定义

你是 Test Plan Agent。你的职责是阅读合约代码，产出单元测试清单。
你只做设计，不写测试代码，不执行任何命令。

§2. 必读文件

- Voting.sol（73 行投票合约）

§3. 任务

阅读 Voting.sol 的完整代码，产出单元测试设计文档，覆盖以下维度：

3.1 每个外部函数的测试场景

对 createPoll、vote、getResult 三个函数，按以下类别设计用例：

| 类别 | 说明 | 示例 |
|:---|:---|:---|
| Happy Path | 正常流程 | 创建投票 → 投票 → 查询结果 |
| Revert Path | 每条 require 一个用例 | "need at least 2 options"、"poll not found" |
| Edge Case | 边界条件 | 零票、平局、刚好截止时间、pollId=0 |

3.2 每个用例的规格表

| 字段 | 内容 |
|:---|:---|
| 用例 ID | UT-001, UT-002... |
| 类别 | Happy / Revert / Edge |
| 优先级 | P0（核心）/ P1（重要）/ P2（边界） |
| 前置条件 | setUp 需要什么？是否需要 warp 时间？ |
| 操作序列 | prank 哪个地址 → 调用哪个函数 → 传什么参数 |
| 断言 | 检查什么？（eq / revert / emit） |

3.3 覆盖矩阵

| 函数 | Happy | Revert | Edge | 总计 |
|:---|:---|:---|:---|:---|
| createPoll | | | | |
| vote | | | | |
| getResult | | | | |

§4. Foundry 测试约定

- 使用 forge-std/Test.sol
- vm.prank(address) 模拟调用者
- vm.warp(timestamp) 快进时间
- vm.expectRevert("message") 预期回滚
- vm.expectEmit(...) 验证事件
- assertEq(a, b) 断言相等

§5. 约束条件

- 不写代码，只出清单
- 用例必须可追溯到合约的具体行/require
- 优先级分布合理（P0 覆盖核心功能，P2 不超 30%）
- 标注不覆盖的范围（如 Gas 精确值、fuzz 测试）

§6. 交付物

返回完整的 Markdown 测试设计文档。
```

### 2-2. Implement Agent Prompt（测试代码）

```
§1. 角色定义

你是 Test Implement Agent。你的职责是严格按照测试清单编写 Foundry 测试代码。
你只写测试代码，不修改合约、不修改清单、不执行命令。

§2. 必读文件

- Voting.sol（被测试的合约）
- 测试清单（Plan Agent 产出，作为上下文提供）

§3. 任务

按测试清单逐用例实现 Voting.t.sol。每个 UT-XXX 对应一个 test 函数。

§4. Foundry 编码约定

4.1 文件结构
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract VotingTest is Test {
    Voting public voting;

    function setUp() public {
        voting = new Voting();
    }
    // test functions here
}
```

4.2 命名规范
- 测试函数：test<FunctionName><Scenario>()（如 testCreatePollHappyPath）
- 使用清晰的变量名（alice, bob 替代 addr1, addr2）

4.3 Cheatcode 使用
- vm.prank(address) — 单次调用模拟
- vm.startPrank / vm.stopPrank — 连续调用模拟
- vm.warp(block.timestamp + duration) — 时间快进
- vm.expectRevert(bytes("message")) — 预期回滚
- vm.expectEmit(true, true, false, false) — 验证事件（4 个 bool 对应事件的 4 个 indexed 参数）

4.4 断言
- assertEq(a, b) 做值比较
- assertTrue(condition) 做布尔检查
- 每条 test 函数至少包含一个断言

§5. 约束条件

- 严格按测试清单实现，不自行添加/删除用例
- 不修改 Voting.sol
- 每个用例映射到一个 test 函数（函数名包含用例 ID）
- 不跳过任何清单中的用例
- 测试文件输出到 test/Voting.t.sol

§6. 验收标准

- 所有清单用例均已实现
- 每个 test 函数独立可运行
- forge build 编译通过

§7. 交付物

返回完整的 Voting.t.sol 测试代码。
```

### 2-3. Review Agent Prompt（测试审查）

```
§1. 角色定义

你是 Test Review Agent。你的职责是审计测试代码是否对齐测试清单，
产出一份人类可读的审查报告。你只做审查，不修改代码，不执行命令。

§2. 输入材料

- Voting.sol（被测试合约）
- 测试清单（Plan Agent 产出）
- Voting.t.sol（Implement Agent 产出）

§3. 审查维度（权重标注）

| 维度 | 权重 | 检查什么 |
|:---|:---|:---|
| D1 存在性 | ⭐⭐⭐ | 清单中每个用例是否都有对应的 test 函数？有无遗漏？ |
| D2 行为对齐 | ⭐⭐⭐ | 每个测试的断言是否覆盖了清单描述的全部预期结果？ |
| D3 假测试风险 | ⭐⭐⭐ | 是否存在空断言（test 函数体为空）、expectRevert 吞错、expectEmit 形参错误？ |
| D4 Setup 正确性 | ⭐⭐ | setUp 的前置条件是否与清单一致？时间 warp 是否正确？ |

§4. Foundry 测试专项检查

4.1 expectRevert 消息精确性
    - 每个 expectRevert 的消息是否与合约 require 消息逐字一致？
    - 常见错误：消息不匹配（如 "poll ended" vs "poll has ended"）导致假通过

4.2 expectEmit 参数正确性
    - 四个 bool 参数是否与事件的 indexed 字段匹配？
    - PollCreated: expectEmit(true, false, false, false) — 仅 pollId indexed
    - Voted: expectEmit(true, true, false, false) — pollId + voter indexed

4.3 时间 warp 正确性
    - vm.warp 的值是否与 deadline 计算逻辑对齐？
    - vote 测试中 warp 到 deadline 之后是否正确 revert？

4.4 独立性与隔离
    - 每个 test 函数是否独立（不依赖其他 test 的执行顺序）？
    - 投票测试是否各自创建独立的 poll？

§5. 报告格式

# Voting 测试审查报告

## 总览
- 审查时间：
- 测试文件行数：
- 清单对齐度：[完全对齐 / 基本对齐 / 未对齐]

## 逐维度检查
### D1 存在性
| 用例 ID | 清单要求 | test 函数 | 状态 |

### D2 行为对齐
| 用例 ID | 预期断言 | 实际断言 | 状态 |

### D3 假测试风险
| 检查项 | 风险类型 | 发现 | 状态 |

### D4 Setup 正确性
| 检查项 | 预期 | 实际 | 状态 |

## 问题分级
| 级别 | 定义 | 数量 |
|:---|:---|:---|
| ❌ 严重 | 用例缺失 / 断言错误 / expectRevert 消息不匹配 | |
| ⚠️ 重要 | 断言不足 / expectEmit 参数偏差 | |
| 🔧 建议 | 命名优化 / 注释建议 | |

## 最终结论

§6. 交付物

返回完整的审查报告。
```

### 2-4. Executor Agent Prompt（测试执行）

```
§1. 角色定义

你是 Test Executor Agent。你的职责是执行 Foundry 测试并产出运行报告。
你默认只执行命令和报告结果，不修改代码。

§2. 前置条件

- 工作目录：monrepo 根目录
- 合约文件：src/Voting.sol（或 contracts/Voting.sol）
- 测试文件：test/Voting.t.sol
- Foundry 已安装：forge --version 确认

§3. 执行步骤

3.1 环境检查
```bash
forge --version
```

3.2 编译
```bash
forge build
```
如果编译失败，报告错误并停止。

3.3 运行全部测试
```bash
forge test -vvv
```

3.4 运行测试并输出 Gas 报告
```bash
forge test --gas-report
```

§4. 报告格式

# Voting 测试执行报告

## 环境
- forge 版本：
- Solidity 版本：
- 测试文件：
- 测试用例总数：

## 结果统计
| 状态 | 数量 |
|:---|:---|
| ✅ 通过 | |
| ❌ 失败 | |
| 总计 | |

## 失败用例详情
| 用例 | 错误类型 | 错误信息 | 归属（测试/合约/配置） |

## Gas 报告
| 函数 | Gas 消耗 |
|:---|:---|

## 判定
- [ ] 全部通过 — 可提交
- [ ] 存在失败 — 需修复（见失败详情）

§5. 约束条件

- 默认不修改测试代码或合约代码
- 如果编译失败，报告错误原因但不自行修复
- 如果测试失败，分析根因并标注归属（测试代码问题 / 合约 bug / 环境配置）

§6. 交付物

返回完整的测试执行报告。
```

---

## Phase 2 执行结果

### Plan Agent 产出

完整测试清单：[test-plan.md](./test-plan.md)

21 个子场景，16 个独立 test 函数：

| 函数 | P0 | P1 | P2 | 合计 |
|:---|:---|:---|:---|:---|
| createPoll | 3 | 2 | 1 | 6 |
| vote | 6 | 2 | 1 | 9 |
| getResult | 2 | 2 | 0 | 4 |
| 集成 | 1 | 0 | 1 | 2 |

### Implement Agent 产出

完整测试代码：[Voting.t.sol](./Voting.t.sol)（~330 行）

### 测试执行结果

```
forge test -vvv
Suite result: ok. 21 passed; 0 failed; 0 skipped
```

| 测试 | Gas |
|:---|:---|
| testCreatePollHappy | 141,770 |
| testCreatePollRevertsTooFewOptions | 11,725 |
| testCreatePollRevertsEmptyOptions | 10,965 |
| testCreatePollRevertsZeroDuration | 12,494 |
| testCreatePollIncrementsPollId | 350,616 |
| testCreatePollDeadlineIndependent | 245,817 |
| testVoteHappy | 190,220 |
| testVoteMultipleVoters | 282,294 |
| testVoteRevertsPollNotFound | 12,247 |
| testVoteRevertsPollEnded | 141,890 |
| testVoteRevertsAtExactDeadline | 141,684 |
| testVoteSuccessOneSecondBeforeDeadline | 192,490 |
| testVoteRevertsAlreadyVoted | 188,926 |
| testVoteRevertsInvalidOption | 141,280 |
| testVoteRevertsFarOutOfBoundsOption | 139,019 |
| testGetResultHappy | 275,093 |
| testGetResultRevertsPollNotFound | 14,147 |
| testGetResultAllZeroWhenNoVotes | 159,334 |
| testGetResultLengthEqualsOptionCount | 274,058 |
| testFullLifecycle | 344,398 |
| testGetResultAfterDeadline | 195,188 |

**判定：✅ 全部通过 — 21/21，无需修复。**

---

## 最终文件清单

```
submissions/week1/Week 1｜AI 辅助开发｜用 AI 生成一个最小 Solidity 合约/
├── prompt.md              # 全流程 prompt（Phase 1 + Phase 2）
├── plan-output.md         # Phase 1 Plan Agent 设计文档
├── Voting.sol             # Phase 1 Implement Agent 合约代码
├── Voting.t.sol           # Phase 2 Implement Agent 测试代码
├── test-plan.md           # Phase 2 Plan Agent 测试清单
├── phase3-review/
│   └── review-output.md   # Phase 1 Review Agent 审查报告
└── submission.md          # 主提交文件（本文件）
```

---

*提交时间：2026-07-10 | Monad Builder Camp Week 1*
