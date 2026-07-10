# 投票合约审查报告

## 总览
- **审查时间**：2026-07-10
- **代码行数**：77 行（含空行和注释），合约体 73 行
- **Plan 对齐度**：✅ **完全对齐**

---

## 逐项检查

### 完整性

| 检查项 | Plan 要求 | 代码实现 | 状态 |
|:---|:---|:---|:---|
| Poll struct 字段 | description, deadline, optionCount, exists | 全部实现（第5-10行） | ✅ |
| pollCount | uint256 public | 第12行 | ✅ |
| polls mapping | mapping(uint256 => Poll) public | 第13行 | ✅ |
| voteCounts mapping | mapping(uint256 => mapping(uint256 => uint256)) public | 第14行 | ✅ |
| hasVoted mapping | mapping(uint256 => mapping(address => bool)) public | 第15行 | ✅ |
| createPoll | 完整签名 + 返回值命名 | 第29-50行 | ✅ |
| vote | 完整签名 | 第52-63行 | ✅ |
| getResult | 完整签名 + 返回值命名 | 第65-76行 | ✅ |
| PollCreated 事件 | pollId(indexed), description, options[], deadline | 第17-22行 | ✅ |
| Voted 事件 | pollId(indexed), voter(indexed), optionIndex | 第23-27行 | ✅ |
| 选项不存链上 | 仅通过事件 emit | 未存储 options，仅在 PollCreated 中 emit | ✅ |
| 行数 ≤80 | ≤80 行 | 73 行合约体 | ✅ |

### 正确性

| 检查项 | 预期行为 | 实际行为 | 状态 |
|:---|:---|:---|:---|
| createPoll 选项数量校验 | `>= 2`，revert "need at least 2 options" | `require(_options.length >= 2, "need at least 2 options")` — 第34行 | ✅ |
| createPoll 时长校验 | `> 0`，revert "duration must be > 0" | `require(_durationMinutes > 0, "duration must be > 0")` — 第35行 | ✅ |
| createPoll pollId 返回 | 返回新创建的 pollId | `pollId = pollCount; pollCount++` — 第37-38行，从0开始自增 | ✅ |
| createPoll deadline 计算 | block.timestamp + 时长 | `block.timestamp + _durationMinutes * 1 minutes` — 第40行 | ✅ |
| createPoll 存储 Poll | description, deadline, optionCount, exists=true | 全部字段赋值（第42-47行），exists 设为 true | ✅ |
| vote 存在性检查 | revert "poll not found" | `require(poll.exists, "poll not found")` — 第54行 | ✅ |
| vote 截止时间检查 | block.timestamp < deadline，revert "poll ended" | `require(block.timestamp < poll.deadline, "poll ended")` — 第55行 | ✅ |
| vote 重复投票检查 | revert "already voted" | `require(!hasVoted[_pollId][msg.sender], "already voted")` — 第56行 | ✅ |
| vote 选项越界检查 | revert "invalid option" | `require(_optionIndex < poll.optionCount, "invalid option")` — 第57行 | ✅ |
| vote 计票逻辑 | 投票计数 +1，标记已投票 | `voteCounts[...]++`（第59行）后 `hasVoted[...] = true`（第60行） | ✅ |
| getResult 存在性检查 | revert "poll not found" | `require(poll.exists, "poll not found")` — 第70行 | ✅ |
| getResult 返回值 | 各选项得票数组 | 遍历 optionCount 填充 voteCounts（第72-75行） | ✅ |
| 状态机（Active/Ended） | 隐式推导，通过 timestamp vs deadline 判断 | vote() 使用 `block.timestamp < poll.deadline` 判断 — 第55行 | ✅ |
| 选项文本不存链上 | 仅 event emit | createPoll 仅存 optionCount，options 在事件中 emit | ✅ |

### 安全性

| 检查项 | 风险等级 | 发现 | 建议 |
|:---|:---|:---|:---|
| 重复投票防护 | 🟢 低 | hasVoted mapping 在计票前检查（第56行），检查通过后立即更新（第60行），逻辑正确 | — |
| 重入攻击 | 🟢 低 | vote() 遵循 CEI（检查-效果-交互）模式：所有状态更新（voteCounts、hasVoted）在事件 emit 之前完成。无外部调用，不存在重入风险 | — |
| 整数溢出 | 🟢 低 | Solidity ^0.8.0 内置溢出保护，voteCounts 自增和 pollCount 自增均安全 | — |
| deadline 绕过 | 🟢 低 | 使用 `block.timestamp < poll.deadline` 严格比较（第55行），截止后无法投票。矿工可微调 timestamp（±15秒），属区块链固有特性 | — |
| getResult 无截止检查 | 🟡 中 | Plan §4.2 提问：「getResult() 在截止前被调用是否应该 revert？」—— Plan 未明确要求 revert，代码允许随时查询。当前行为可查看中间结果，属合理设计选择 | 确认设计意图：若产品要求截止后才能查看结果，需在 getResult 加 `require(block.timestamp >= poll.deadline, "poll not ended")` |
| 未使用 pollId=0 的投票 | 🟢 低 | pollId 从 0 开始（pollCount 初始值为 0），polls[0] 默认 exists=false，vote/getResult 均会正确 revert "poll not found" | — |
| 前端交易（front-running） | 🟡 低 | 投票者可通过 mempool 看到他人的待确认投票，属公链固有特性，非合约缺陷 | 若隐私投票为强需求，需引入 commit-reveal 方案（超出当前 Plan 范围） |
| 访问控制 | 🟢 低 | createPoll 和 vote 均为 external 无权限限制，任何人可创建投票和投票，符合 Plan 设计 | — |

### Gas 效率

| 检查项 | 发现 | 建议 |
|:---|:---|:---|
| 存储布局 | mapping + mapping 嵌套，每次投票 2 次 SSTORE（voteCounts + hasVoted），属于标准设计，无法显著优化 | — |
| getResult 循环 | `for (uint256 i = 0; i < poll.optionCount; i++)` 遍历所有选项（第73行）。view 函数链下调用不消耗 gas，但若被其他合约调用（链上），optionCount 大时 gas 成本高 | 可考虑链下聚合事件日志获取结果，避免链上遍历（超出当前 Plan 范围） |
| 描述存储 | description 以 string 存在 Poll struct 中（链上存储），长字符串 gas 成本较高 | 可考虑仅存 IPFS hash（超出当前 Plan 范围） |
| 时间计算 | `_durationMinutes * 1 minutes` 每次 createPoll 执行乘法（第40行），gas 微不足道 | — |
| 无冗余存储 | 选项数组不存链上，仅存 optionCount（uint256），符合 Plan 设计，gas 高效 | — |

### 代码质量

| 检查项 | 发现 | 建议 |
|:---|:---|:---|
| 命名规范 | pollCount、polls、voteCounts、hasVoted 清晰直观，参数命名 _pollId、_optionIndex 等符合 Solidity 惯例 | — |
| Revert 消息 | 全部 revert 消息与 Plan 逐字一致："need at least 2 options"、"duration must be > 0"、"poll not found"、"poll ended"、"already voted"、"invalid option" | — |
| 注释 | 合约无注释 | Plan 未要求注释；建议在关键逻辑处添加简短注释（如 deadline 计算、状态检查） |
| 代码结构 | struct → 状态变量 → 事件 → 函数，逻辑分组清晰 | — |
| Solidity 版本 | `^0.8.0`（第2行），使用内置溢出保护，合理 | — |
| 函数可见性 | createPoll/vote 为 external，getResult 为 external view，符合 Plan | — |

---

## 问题分级

| 级别 | 定义 | 数量 |
|:---|:---|:---|
| ❌ 严重 | 与 Plan 不一致 / 存在安全漏洞 / 功能缺失 | **0** |
| ⚠️ 重要 | 逻辑偏差但可修复 / Gas 浪费明显 | **0** |
| 🔧 建议 | 风格改进 / 命名优化 / 设计意图需确认 | **2** |

### 🔧 建议项详情

1. **getResult 截止检查**（Plan §4.2）：Plan 提问 getResult 是否应在截止前 revert，当前代码允许随时查询。若产品需求为「截止后才能查看结果」，需补充 `require(block.timestamp >= poll.deadline, "poll not ended")`。建议与产品确认后决定。

2. **缺少注释**：合约整体无注释。建议在 createPoll 的 deadline 计算、vote 的状态检查链、getResult 的遍历逻辑处添加简短注释，提升可读性。

---

## 最终结论

- **判定**：✅ **通过**
- **是否建议人工修改**：否——代码完全对齐 Plan 设计文档，无安全漏洞，无需修改即可部署
- **修改建议汇总**：
  - 建议项 1（getResult 截止检查）需产品确认设计意图，非代码缺陷
  - 建议项 2（注释）为风格优化，不影响功能

---

### 审查证据索引

| Plan 要求 | 代码证据（行号） |
|:---|:---|
| Poll struct 四字段 | 第5-10行 |
| 全局状态变量 | 第12-15行 |
| 所有 revert 消息 | 第34、35、54、55、56、57、70行 |
| 事件签名 | 第17-27行 |
| 选项不存链上 | 第45行仅存 optionCount，第49行 event emit options |
| 状态机隐式推导 | 第55行 `block.timestamp < poll.deadline` |
| 行数 ≤80 | 合约体 73 行 |
| CEI 安全模式 | 第59-62行（状态更新在 event 前） |