# Voting.sol — Foundry 单元测试清单

> **Contract**: `Voting.sol`  
> **Framework**: Foundry + `forge-std/Test.sol`  
> **Solidity Version**: `^0.8.0`  
> **Total Test Cases**: 16  
> **Legend**: 🔴 P0 = 核心功能（必须全部通过） | 🟡 P1 = 重要边界/回归 | 🟢 P2 = 补充覆盖

---

## 1. `createPoll` — 创建投票

### UT-001 — 正常创建投票并验证返回值与状态

| 属性 | 内容 |
|------|------|
| **ID** | UT-001 |
| **类别** | Happy |
| **优先级** | 🔴 P0 |
| **对应合约行** | L19–L26（`createPoll` 全文） |
| **操作序列** | 1. 准备 `description = "Favorite Color"`, `options = ["Red","Blue","Green"]`, `duration = 10`<br>2. 调用 `createPoll(...)` 获取返回的 `pollId` |
| **断言** | `assertEq(pollId, 0)` — 第一个投票 ID 应为 0<br>`assertEq(pollCount, 1)` — 全局计数器 +1<br>`(desc, deadline, optCount, exists) = polls(0)`<br>· `assertEq(desc, "Favorite Color")`<br>· `assertEq(optCount, 3)`<br>· `assertTrue(exists)`<br>· `assertEq(deadline, block.timestamp + 600)` |
| **事件** | `expectEmit` → `PollCreated(0, "Favorite Color", ["Red","Blue","Green"], deadline)` |

---

### UT-002 — options 数量 < 2 时 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-002 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L20 — `require(_options.length >= 2, "need at least 2 options")` |
| **操作序列** | 1. `options = ["SingleOption"]` (长度 = 1)<br>2. `expectRevert("need at least 2 options")`<br>3. 调用 `createPoll(...)` |
| **断言** | 交易 revert，revert 原因匹配 `"need at least 2 options"` |

---

### UT-002b — options 为空数组时 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-002b |
| **类别** | Revert / Edge |
| **优先级** | 🟡 P1 |
| **对应合约行** | L20 — `require(_options.length >= 2, ...)` |
| **操作序列** | 1. `options = []` (长度 = 0)<br>2. `expectRevert(...)`<br>3. `createPoll(...)` |
| **断言** | 同样 revert `"need at least 2 options"`，验证 `>= 2` 的整数下界 |

---

### UT-003 — duration 为 0 时 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-003 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L21 — `require(_durationMinutes > 0, "duration must be > 0")` |
| **操作序列** | 1. `duration = 0`<br>2. `expectRevert("duration must be > 0")`<br>3. `createPoll(...)` |
| **断言** | 交易 revert，revert 原因匹配 `"duration must be > 0"` |

---

### UT-004 — 连续创建多个投票，pollId 递增

| 属性 | 内容 |
|------|------|
| **ID** | UT-004 |
| **类别** | Edge |
| **优先级** | 🟡 P1 |
| **对应合约行** | L22–L23 — `pollId = pollCount; pollCount++` |
| **操作序列** | 1. `createPoll("A", ["x","y"], 5)` → 返回 0<br>2. `createPoll("B", ["a","b"], 5)` → 返回 1<br>3. `createPoll("C", ["1","2"], 5)` → 返回 2 |
| **断言** | `assertEq(pollCount, 3)`<br>`polls(0).exists == true`<br>`polls(1).exists == true`<br>`polls(2).exists == true`<br>`polls(0).description == "A"` — 各自独立 |

---

### UT-004b — deadline 不重叠（时间递增）

| 属性 | 内容 |
|------|------|
| **ID** | UT-004b |
| **类别** | Edge |
| **优先级** | 🟢 P2 |
| **对应合约行** | L24 — `deadline = block.timestamp + _durationMinutes * 1 minutes` |
| **操作序列** | 1. `warp(1000)` → 创建投票 duration=5 → deadline=1300<br>2. `warp(2000)` → 创建投票 duration=10 → deadline=2600 |
| **断言** | `polls(0).deadline == 1300`<br>`polls(1).deadline == 2600` — 各自独立计算 |

---

## 2. `vote` — 投票

### UT-005 — 正常投票并验证状态变更

| 属性 | 内容 |
|------|------|
| **ID** | UT-005 |
| **类别** | Happy |
| **优先级** | 🔴 P0 |
| **对应合约行** | L28–L35（`vote` 全文） |
| **操作序列** | 1. Alice 创建 poll（duration=10）<br>2. Alice 对 option 1 投票 |
| **断言** | `voteCounts(0, 1) == 1`<br>`hasVoted(0, alice) == true` |
| **事件** | `expectEmit` → `Voted(0, alice, 1)` |

---

### UT-006 — 多人投票同一选项，得票累加

| 属性 | 内容 |
|------|------|
| **ID** | UT-006 |
| **类别** | Happy / Edge |
| **优先级** | 🔴 P0 |
| **对应合约行** | L33 — `voteCounts[_pollId][_optionIndex]++` |
| **操作序列** | 1. Alice 创建 poll（duration=10）<br>2. `prank(alice)` → vote(0, 1)<br>3. `prank(bob)` → vote(0, 1)<br>4. `prank(charlie)` → vote(0, 0) |
| **断言** | `voteCounts(0, 0) == 1`<br>`voteCounts(0, 1) == 2`<br>`hasVoted(0, alice) == true`<br>`hasVoted(0, bob) == true`<br>`hasVoted(0, charlie) == true` |

---

### UT-007 — 投票不存在的 poll 时 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-007 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L30 — `require(poll.exists, "poll not found")` |
| **操作序列** | 1. `expectRevert("poll not found")`<br>2. `vote(999, 0)` — 对不存在的 pollId 投票 |
| **断言** | 交易 revert，revert 原因匹配 `"poll not found"` |

---

### UT-008 — 投票截止后投票 revert（warp 到未来）

| 属性 | 内容 |
|------|------|
| **ID** | UT-008 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L31 — `require(block.timestamp < poll.deadline, "poll ended")` |
| **操作序列** | 1. Alice 创建 poll（duration=10）→ deadline = `now + 600`<br>2. `warp(deadline)` — 跳到截止时间<br>3. `expectRevert("poll ended")`<br>4. `vote(0, 0)` |
| **断言** | 交易 revert，revert 原因匹配 `"poll ended"` |

---

### UT-008b — 恰好截止时刻 revert（边界条件）

| 属性 | 内容 |
|------|------|
| **ID** | UT-008b |
| **类别** | Edge / Revert |
| **优先级** | 🟡 P1 |
| **对应合约行** | L31 — `require(block.timestamp < poll.deadline, ...)` |
| **操作序列** | 1. 创建 poll（duration=10）→ deadline = T<br>2. `warp(T)` — 严格等于 deadline<br>3. `vote(0, 0)` |
| **断言** | 交易 **revert**（`<` 是 strict less-than，`T < T` 为 false） |

---

### UT-008c — 截止前最后 1 秒仍可投票（边界条件）

| 属性 | 内容 |
|------|------|
| **ID** | UT-008c |
| **类别** | Edge / Happy |
| **优先级** | 🟡 P1 |
| **对应合约行** | L31 — `require(block.timestamp < poll.deadline, ...)` |
| **操作序列** | 1. 创建 poll（duration=10）→ deadline = T<br>2. `warp(T - 1)` — 截止前 1 秒<br>3. `vote(0, 0)` |
| **断言** | 交易成功，`voteCounts(0, 0) == 1` |

---

### UT-009 — 同一地址重复投票 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-009 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L32 — `require(!hasVoted[_pollId][msg.sender], "already voted")` |
| **操作序列** | 1. Alice 创建 poll<br>2. Alice → `vote(0, 0)` ✓<br>3. `expectRevert("already voted")`<br>4. Alice → `vote(0, 1)` — 尝试换选项 |
| **断言** | 第二次投票 revert `"already voted"` |

---

### UT-010 — 选项索引越界（= optionCount）revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-010 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L33 — `require(_optionIndex < poll.optionCount, "invalid option")` |
| **操作序列** | 1. Alice 创建 poll options=["A","B","C"] → `optionCount=3`<br>2. `expectRevert("invalid option")`<br>3. `vote(0, 3)` — 索引 3 越界 |
| **断言** | 交易 revert `"invalid option"` |

---

### UT-010b — 选项索引远大于 optionCount revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-010b |
| **类别** | Revert / Edge |
| **优先级** | 🟢 P2 |
| **对应合约行** | L33 — `require(_optionIndex < poll.optionCount, ...)` |
| **操作序列** | 1. 创建 poll（optionCount=3）<br>2. `vote(0, type(uint256).max)` |
| **断言** | 交易 revert `"invalid option"` |

---

## 3. `getResult` — 查询结果

### UT-011 — 正常查询得票数组

| 属性 | 内容 |
|------|------|
| **ID** | UT-011 |
| **类别** | Happy |
| **优先级** | 🔴 P0 |
| **对应合约行** | L38–L43（`getResult` 全文） |
| **操作序列** | 1. Alice 创建 poll options=["A","B","C"]<br>2. Alice → vote(0, 0)<br>3. Bob → vote(0, 1)<br>4. Charlie → vote(0, 1)<br>5. 调用 `getResult(0)` |
| **断言** | `results.length == 3`<br>`results[0] == 1` (A 得 1 票)<br>`results[1] == 2` (B 得 2 票)<br>`results[2] == 0` (C 得 0 票) |

---

### UT-012 — 查询不存在的 poll 时 revert

| 属性 | 内容 |
|------|------|
| **ID** | UT-012 |
| **类别** | Revert |
| **优先级** | 🔴 P0 |
| **对应合约行** | L40 — `require(poll.exists, "poll not found")` |
| **操作序列** | 1. `expectRevert("poll not found")`<br>2. `getResult(999)` |
| **断言** | 交易 revert `"poll not found"` |

---

### UT-013 — 零票时返回全零数组

| 属性 | 内容 |
|------|------|
| **ID** | UT-013 |
| **类别** | Edge |
| **优先级** | 🟡 P1 |
| **对应合约行** | L41–L43 — `new uint256[](poll.optionCount) → 默认全 0` |
| **操作序列** | 1. Alice 创建 poll options=["A","B","C","D","E"]<br>2. 无任何人投票<br>3. `getResult(0)` |
| **断言** | `results.length == 5`<br>`results[0..4]` 全部为 0 |

---

### UT-014 — 结果数组长度严格等于 optionCount

| 属性 | 内容 |
|------|------|
| **ID** | UT-014 |
| **类别** | Edge |
| **优先级** | 🟡 P1 |
| **对应合约行** | L41 — `new uint256[](poll.optionCount)` |
| **操作序列** | 1. 创建 poll options=["A","B"] → optionCount=2<br>2. vote(0,0) 一次<br>3. 创建 poll options=["A","B","C","D","E","F"] → optionCount=6<br>4. 分别调用 `getResult(0)` 和 `getResult(1)` |
| **断言** | `getResult(0).length == 2`<br>`getResult(1).length == 6` |

---

## 4. 综合 / 跨函数集成测试

### UT-015 — 完整生命周期端到端

| 属性 | 内容 |
|------|------|
| **ID** | UT-015 |
| **类别** | Integration |
| **优先级** | 🔴 P0 |
| **操作序列** | 1. Alice 创建 poll "Best Language", options=["Solidity","Rust","Go"], duration=60<br>2. Alice → vote(0, 0)<br>3. Bob → vote(0, 1)<br>4. Charlie → vote(0, 1)<br>5. Dave → vote(0, 2)<br>6. 验证 deadline 前可投票<br>7. `getResult(0)` → [1, 2, 1]<br>8. Bob 尝试再次 vote → revert `"already voted"`<br>9. `warp(deadline)` → Alice 尝试 vote → revert `"poll ended"`<br>10. `getResult(0)` 应仍返回 [1, 2, 1]（截止后仍可查询） |
| **断言** | 每一步的中期断言如上，最终结果一致<br>`pollCount == 1` |

---

### UT-016 — 截至后 getResult 仍可查询（不依赖时间）

| 属性 | 内容 |
|------|------|
| **ID** | UT-016 |
| **类别** | Edge |
| **优先级** | 🟢 P2 |
| **对应合约行** | L38–L43 — `getResult` 无时间检查 |
| **操作序列** | 1. 创建 poll，投票<br>2. `warp(deadline + 10000)`<br>3. `getResult(0)` |
| **断言** | 仍能成功返回结果，不会 revert |

---

## 5. 汇总矩阵

| 函数 | P0 | P1 | P2 | 合计 |
|------|----|----|----|------|
| `createPoll` | UT-001, UT-002, UT-003 | UT-002b, UT-004 | UT-004b | **6** |
| `vote` | UT-005, UT-006, UT-007, UT-008, UT-009, UT-010 | UT-008b, UT-008c | UT-010b | **9** |
| `getResult` | UT-011, UT-012 | UT-013, UT-014 | — | **4** |
| 集成 | UT-015 | — | UT-016 | **2** |
| **总计** | **12** | **6** | **3** | **21** |

*(注：集成用例 UT-015 覆盖多个函数的子场景，上表为避免重复计数将每个用例归属到其主要测试的函数。实际场景总数 16 个独立测试函数。)*

---

## 6. 测试文件结构建议

```
test/
└── Voting.t.sol
    ├── contract VotingTest is Test
    │   ├── Voting voting;
    │   ├── address alice = makeAddr("alice");
    │   ├── address bob   = makeAddr("bob");
    │   ├── address charlie = makeAddr("charlie");
    │   ├── address dave  = makeAddr("dave");
    │   │
    │   ├── function setUp() public { voting = new Voting(); }
    │   │
    │   ├── // ── createPoll ──
    │   ├── testCreatePollHappy()              // UT-001
    │   ├── testCreatePollRevertsTooFewOptions() // UT-002
    │   ├── testCreatePollRevertsEmptyOptions()  // UT-002b
    │   ├── testCreatePollRevertsZeroDuration()  // UT-003
    │   ├── testCreatePollIncrementsPollId()     // UT-004
    │   ├── testCreatePollDeadlineIndependent()  // UT-004b
    │   │
    │   ├── // ── vote ──
    │   ├── testVoteHappy()                      // UT-005
    │   ├── testVoteMultipleVoters()             // UT-006
    │   ├── testVoteRevertsPollNotFound()        // UT-007
    │   ├── testVoteRevertsPollEnded()           // UT-008
    │   ├── testVoteRevertsAtExactDeadline()     // UT-008b
    │   ├── testVoteSuccessOneSecondBeforeDeadline() // UT-008c
    │   ├── testVoteRevertsAlreadyVoted()        // UT-009
    │   ├── testVoteRevertsInvalidOption()       // UT-010
    │   ├── testVoteRevertsFarOutOfBoundsOption() // UT-010b
    │   │
    │   ├── // ── getResult ──
    │   ├── testGetResultHappy()                 // UT-011
    │   ├── testGetResultRevertsPollNotFound()   // UT-012
    │   ├── testGetResultAllZeroWhenNoVotes()    // UT-013
    │   ├── testGetResultLengthEqualsOptionCount() // UT-014
    │   │
    │   ├── // ── 集成 ──
    │   ├── testFullLifecycle()                  // UT-015
    │   └── testGetResultAfterDeadline()         // UT-016
```

---

## 7. Foundry Cheatcode 使用清单

| Cheatcode | 用例 |
|-----------|------|
| `vm.prank(addr)` | 模拟不同地址调用 `vote`（UT-005, UT-006, UT-009, UT-015） |
| `vm.warp(timestamp)` | 跳过时间到 deadline 前后（UT-008, UT-008b, UT-008c, UT-015, UT-016） |
| `vm.expectRevert(bytes)` | 所有 Revert 用例（UT-002, UT-003, UT-007, UT-008, UT-009, UT-010, UT-012） |
| `vm.expectEmit(...)` | 验证事件（UT-001, UT-005） |
| `makeAddr("label")` | 创建标记地址（Alice/Bob/Charlie/Dave） |
| `assertEq` / `assertTrue` | 所有断言 |
| `assertEq(arr1, arr2)` | 数组比较（检查 getResult 返回值） |

---

*End of Test Plan*