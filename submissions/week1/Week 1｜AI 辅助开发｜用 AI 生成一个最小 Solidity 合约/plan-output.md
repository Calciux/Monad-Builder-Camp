# 投票合约（Voting Contract）设计文档

> **文档类型**：架构设计文档
> **版本**：v1.0
> **日期**：2026-07-10
> **Solidity 版本**：^0.8.0
> **目标代码行数**：≤ 80 行

---

## 1. 概述

本合约实现一个最小化的链上投票系统，用于学习和演示 AI 辅助 Solidity 开发的工作流。

**核心功能**：
- 任何人可以创建投票（Poll），设定描述、选项和截止时间
- 任何地址可以在投票截止前投票，每个地址每个投票限投一票
- 任何人可以随时查询任意投票的实时结果

**设计原则**：
- 极简：不引入任何外部库，纯 Solidity 原生类型
- 透明：所有状态变量公开可查，事件完整记录关键操作
- 自包含：合约不依赖前端存储选项文本，选项信息通过事件链下重建

---

## 2. 状态机

### 2.1 投票生命周期

一个投票（Poll）经历两个逻辑状态，状态由 `block.timestamp` 与 `deadline` 的比较**隐式推导**，不显式存储状态字段。

```
                    createPoll()
     [不存在] ─────────────────────► [Active]
                                         │
                                         │ block.timestamp >= deadline
                                         │ （隐式触发，无显式状态转换函数）
                                         ▼
                                    [Ended]
```

### 2.2 状态定义

| 状态 | 判定条件 | 允许操作 |
|------|---------|---------|
| **Active** | `block.timestamp < poll.deadline` | `vote()` |
| **Ended** | `block.timestamp >= poll.deadline` | `getResult()`（也可在 Active 时调用，查询实时票数） |

### 2.3 状态转换触发条件

| 转换 | 触发条件 | 触发方式 |
|------|---------|---------|
| 不存在 → Active | `createPoll()` 被调用且参数合法 | 显式函数调用 |
| Active → Ended | `block.timestamp >= deadline` | 隐式（时间自然流逝，无需显式调用） |

**设计说明**：状态不显式存储（不使用 `enum` 或 `bool isActive`），而是通过 `block.timestamp` 与 `deadline` 的比较动态判定。这样做的好处：
- 节省存储空间（每个 poll 省一个 `bool` 或 `enum` 字段）
- 避免"忘记关停"的 bug（不存在"应该 Ended 但状态字段仍是 Active"的情况）
- 符合 ~80 行的极简约束

---

## 3. 数据结构

### 3.1 Poll 结构体

```solidity
struct Poll {
    string description;   // 投票描述/标题
    uint256 deadline;     // 截止时间（Unix 时间戳，秒）
    uint256 optionCount;  // 选项数量
    bool exists;          // 防伪标记：用于区分「不存在的 poll」和「零值 poll」
}
```

| 字段 | 类型 | 用途 | 备注 |
|------|------|------|------|
| `description` | `string` | 投票描述，说明投票主题 | 无长度限制（gas 由调用者承担） |
| `deadline` | `uint256` | 投票截止的区块时间戳 | `block.timestamp + duration`，单位为秒 |
| `optionCount` | `uint256` | 该投票的选项个数 | 创建时由 `_options.length` 确定，不可变 |
| `exists` | `bool` | 标记该 poll 是否已被创建 | 用于 `require(polls[id].exists, "not found")`，区分 ID 0 与不存在 |

**为什么不在 struct 中存储选项文本？**

选项文本（`string[]`）不存储在链上，而是在 `PollCreated` 事件中 emit。这样：
- 链上存储成本降低（字符串数组 gas 消耗大）
- 链下索引服务（如 The Graph）或前端可直接从事件日志中读取选项
- `getResult()` 返回的是 `uint256[]`（各选项得票数），前端结合事件日志中的选项顺序即可展示完整结果

### 3.2 全局状态变量

```solidity
uint256 public pollCount;                                                // 已创建的投票总数
mapping(uint256 => Poll) public polls;                                   // pollId => Poll
mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;       // pollId => optionIndex => 得票数
mapping(uint256 => mapping(address => bool)) public hasVoted;            // pollId => voter => 是否已投票
```

| 变量 | 类型 | 可见性 | 用途 |
|------|------|--------|------|
| `pollCount` | `uint256` | `public` | 已创建投票总数，兼作下一个 poll 的 ID（自增计数器） |
| `polls` | `mapping(uint256 => Poll)` | `public` | poll ID → Poll 结构体，存储每个投票的元数据 |
| `voteCounts` | `mapping(uint256 => mapping(uint256 => uint256))` | `public` | poll ID → 选项索引 → 得票数。二维映射，内层 key 为选项编号（0,1,2…） |
| `hasVoted` | `mapping(uint256 => mapping(address => bool))` | `public` | poll ID → 投票者地址 → 是否已投票。实现「每地址每投票限投一次」 |

### 3.3 投票追踪机制

**「每个地址在每个投票中只能投一次」的实现：**

使用双层 mapping `hasVoted`，在 `vote()` 中：
1. 写入前检查：`require(!hasVoted[pollId][msg.sender], "already voted")`
2. 投票后立即标记：`hasVoted[pollId][msg.sender] = true`

这两个操作在同一笔交易中原子执行，天然防止重入攻击（Solidity 0.8.0+ 默认溢出检查，且无外部调用）。

**「每个选项的得票数」的存储：**

使用双层 mapping `voteCounts`，在 `vote()` 中：
```solidity
voteCounts[pollId][optionIndex]++;
```
- `pollId`：标识哪个投票
- `optionIndex`：标识哪个选项（从 0 开始，与创建时的选项数组索引对应）
- 值：累计得票数（`uint256`，无符号整数，不会溢出除非有人烧掉 2^256 gas 来投票）

---

## 4. 函数规格

### 4.1 createPoll — 创建投票

| | 内容 |
|---|---|
| **函数签名** | `function createPoll(string calldata _description, string[] calldata _options, uint256 _durationMinutes) external returns (uint256 pollId)` |
| **调用者** | 任何人（无权限限制） |
| **前置条件** | 1. `_options.length >= 2`（至少 2 个选项，否则投票无意义）<br>2. `_durationMinutes > 0`（截止时间必须在未来） |
| **行为** | 1. 取当前 `pollCount` 作为新 poll 的 ID<br>2. 构造 `Poll` 结构体并写入 `polls[pollId]`：<br>　- `description = _description`<br>　- `deadline = block.timestamp + _durationMinutes * 1 minutes`<br>　- `optionCount = _options.length`<br>　- `exists = true`<br>3. `pollCount++`（自增计数器）<br>4. 返回新创建的 `pollId` |
| **Revert 条件** | 1. `_options.length < 2` → `"need at least 2 options"`<br>2. `_durationMinutes == 0` → `"duration must be > 0"` |
| **事件** | `emit PollCreated(pollId, _description, _options, deadline)` |

**注意**：`_options` 数组仅在事件中传递到链下，不存储在合约 storage 中。

### 4.2 vote — 投票

| | 内容 |
|---|---|
| **函数签名** | `function vote(uint256 _pollId, uint256 _optionIndex) external` |
| **调用者** | 任何人（每个地址在每个 poll 中限投一次） |
| **前置条件** | 1. `polls[_pollId].exists == true`（投票必须存在）<br>2. `block.timestamp < polls[_pollId].deadline`（投票未截止）<br>3. `!hasVoted[_pollId][msg.sender]`（该地址在此 poll 中尚未投票）<br>4. `_optionIndex < polls[_pollId].optionCount`（选项索引有效） |
| **行为** | 1. 通过全部前置条件检查<br>2. `voteCounts[_pollId][_optionIndex]++`（该选项得票数 +1）<br>3. `hasVoted[_pollId][msg.sender] = true`（标记该地址已投票） |
| **Revert 条件** | 1. `poll 不存在` → `"poll not found"`<br>2. `已截止` → `"poll ended"`<br>3. `已投过票` → `"already voted"`<br>4. `选项索引越界` → `"invalid option"` |
| **事件** | `emit Voted(_pollId, msg.sender, _optionIndex)` |

**设计说明**：`vote()` 不返回任何值（不返回新的票数），调用者如需结果应另行调用 `getResult()`。这样将"写入"和"查询"解耦，函数职责单一。

### 4.3 getResult — 查询结果

| | 内容 |
|---|---|
| **函数签名** | `function getResult(uint256 _pollId) external view returns (uint256[] memory results)` |
| **调用者** | 任何人（view 函数，无 gas 消耗） |
| **前置条件** | `polls[_pollId].exists == true`（投票必须存在） |
| **行为** | 1. 读取 `polls[_pollId].optionCount` 确定数组长度<br>2. 遍历 `i = 0` 到 `optionCount - 1`，从 `voteCounts[_pollId][i]` 读取每个选项的得票数<br>3. 构造并返回 `uint256[] memory` 数组 |
| **Revert 条件** | `poll 不存在` → `"poll not found"` |
| **事件** | 无（view 函数不 emit 事件） |

**设计说明**：
- `getResult()` 在 Active 和 Ended 状态下均可调用，返回实时票数。调用者可根据 `block.timestamp` 与 `deadline` 自行判断结果是否为"最终结果"。
- 函数仅返回票数数组（`uint256[]`），不包含选项文本。选项文本需从 `PollCreated` 事件日志中获取，按索引对齐。

---

## 5. 事件定义

### 5.1 PollCreated

| 属性 | 值 |
|------|-----|
| **事件名称** | `PollCreated` |
| **emit 位置** | `createPoll()` |
| **签名** | `event PollCreated(uint256 indexed pollId, string description, string[] options, uint256 deadline)` |

| 参数 | 类型 | indexed | 说明 |
|------|------|:---:|------|
| `pollId` | `uint256` | ✅ | 新创建的投票 ID，用于后续 `vote()` 和 `getResult()` 调用 |
| `description` | `string` | — | 投票描述，与创建时传入的 `_description` 一致 |
| `options` | `string[]` | — | 选项文本数组，**链上不存储，仅通过事件传递**。前端/索引器据此重建选项列表 |
| `deadline` | `uint256` | — | 投票截止时间（Unix 时间戳），与 `polls[pollId].deadline` 一致 |

**为什么要 `indexed pollId`？**
- 允许链下服务按 pollId 高效过滤日志（如 `eth_getLogs` 按 topic 过滤）
- `description`、`options`、`deadline` 不设 indexed，因为 indexed 参数限制 3 个，且这些字段通常不需要按值搜索

### 5.2 Voted

| 属性 | 值 |
|------|-----|
| **事件名称** | `Voted` |
| **emit 位置** | `vote()` |
| **签名** | `event Voted(uint256 indexed pollId, address indexed voter, uint256 optionIndex)` |

| 参数 | 类型 | indexed | 说明 |
|------|------|:---:|------|
| `pollId` | `uint256` | ✅ | 被投票的 poll ID |
| `voter` | `address` | ✅ | 投票者地址（`msg.sender`） |
| `optionIndex` | `uint256` | — | 投给的选项索引（0-based） |

**为什么要 `indexed pollId` 和 `indexed voter`？**
- 按 poll 查询所有投票记录：`eth_getLogs` filter topic[0]=Voted, topic[1]=pollId
- 按地址查询该用户的所有投票：filter topic[0]=Voted, topic[2]=voter
- 统计某个 poll 的总参与人数：按 pollId 过滤后计数唯一 voter 地址

---

## 6. 设计决策与权衡

### 6.1 选项文本不存链上

| 方案 | 优点 | 缺点 |
|------|------|------|
| 选项存 `Poll` struct | 合约自包含，`getResult` 可直接返回完整信息 | gas 成本高，代码行数增加，~80 行目标难以达成 |
| **选项仅 emit 在事件中（采用）** | 极省 gas，代码精简 | 依赖链下索引服务或前端保存事件日志 |

**选择理由**：对于演示/学习用途，事件日志方案已足够。生产环境中通常也会搭配 The Graph 等索引层。

### 6.2 状态隐式推导 vs 显式存储

| 方案 | 优点 | 缺点 |
|------|------|------|
| 显式存储 `enum State { Active, Ended }` | 代码意图清晰，可快速判断状态 | 额外存储成本，需要显式状态转换函数 |
| **隐式推导（采用）** | 零额外存储，状态永不同步出错 | 每次判断都需要 `block.timestamp` 比较 |

**选择理由**：极简约束下，隐式推导是最优解。只要 `block.timestamp` 单调增长，状态判定永远正确。

### 6.3 未实现的功能（有意省略）

以下功能因 ~80 行约束有意省略，但它们属于常见投票合约扩展方向：

- **委托投票**：允许用户将投票权委托给他人
- **权重投票**：按持币量加权投票
- **匿名投票**：使用承诺-揭示方案隐藏投票选择
- **提前关闭**：创建者手动关闭投票
- **选项增删**：创建后修改选项
- **多选投票**：允许一个地址投多个选项
- **白名单投票**：仅允许特定地址参与

---

## 7. 合约规模估算

| 模块 | 预估行数 |
|------|:---:|
| SPDX + pragma + 合约声明 | 3 |
| Struct 定义 (`Poll`) | 5 |
| 状态变量 (`pollCount`, 3 个 mapping) | 4 |
| 事件定义 (`PollCreated`, `Voted`) | 3 |
| `createPoll` 函数体 | 14 |
| `vote` 函数体 | 12 |
| `getResult` 函数体 | 10 |
| **总计** | **≈ 51 行** |

计入空行、注释后，预计最终合约 **60-75 行**，在 80 行目标范围内。

---

## 8. 完整接口总览

```solidity
// ============ 状态变量 ============
uint256 public pollCount;
mapping(uint256 => Poll) public polls;
mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;
mapping(uint256 => mapping(address => bool)) public hasVoted;

// ============ 事件 ============
event PollCreated(uint256 indexed pollId, string description, string[] options, uint256 deadline);
event Voted(uint256 indexed pollId, address indexed voter, uint256 optionIndex);

// ============ 函数 ============
function createPoll(string calldata _description, string[] calldata _options, uint256 _durationMinutes) external returns (uint256 pollId);
function vote(uint256 _pollId, uint256 _optionIndex) external;
function getResult(uint256 _pollId) external view returns (uint256[] memory results);
```

---

*本文档由 Plan Agent 生成，仅供设计参考。不包含 Solidity 实现代码，不执行编译或部署。*
