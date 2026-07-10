# Voting Contract — Monad Testnet 部署记录

## 合约简介

最小化链上投票合约（Voting Contract），纯 Solidity 实现，零外部依赖。

**功能**：
- `createPoll(description, options[], durationMinutes)` — 创建投票（至少 2 个选项）
- `vote(pollId, optionIndex)` — 投票（每地址每投票限投一次，截止后不可投）
- `getResult(pollId)` — 查询得票数（uint256[]）

**设计要点**：
- 状态通过 `block.timestamp >= deadline` 隐式推导，不存 enum
- 选项文本不存链上，仅通过 `PollCreated` 事件 emit（省 gas）
- 双层 mapping `hasVoted[pollId][voter]` 防止重复投票

## 链上证据（Monad Testnet）

| 项目 | 值 |
|:---|:---|
| **网络** | Monad Testnet（Chain ID: 10143） |
| **合约地址** | `0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC` |
| **部署者** | `0x995202E7f74573B17e417b8d6537669c484137B1` |
| **部署 Tx** | `0xec91300deb8faff55d622ff264e43869a82dce3161617977a0383d3ed20fc795` |

### 区块浏览器链接

- 合约：https://testnet.monadscan.com/address/0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC
- 部署交易：https://testnet.monadscan.com/tx/0xec91300deb8faff55d622ff264e43869a82dce3161617977a0383d3ed20fc795
- createPoll 交易：https://testnet.monadscan.com/tx/0x2485a47f9cab7dc60d3443a24a8d8ffa018cb013f34d64a48a0ae620c8153f5e
- vote 交易：https://testnet.monadscan.com/tx/0xbb4c483afe706e253f6a4b2f5e3d56e16e513b5b4ea360c3408d2d6e388630bd

## 交互记录

### Read: `pollCount()`

```
cast call 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC "pollCount()(uint256)"
→ 0（部署后，创建投票前）
```

### Write: `createPoll()`

```
cast send 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC \
  "createPoll(string,string[],uint256)" \
  "Monad Builder Camp Week 1 Demo" \
  '["Solidity","Rust","Go","Python"]' 60
→ Tx: 0x2485a47f9cab7dc60d3443a24a8d8ffa018cb013f34d64a48a0ae620c8153f5e
→ Block: 43763160, Status: success
→ 创建投票 ID=0，4 个选项，60 分钟截止
```

### Write: `vote()`

```
cast send 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC \
  "vote(uint256,uint256)" 0 1
→ Tx: 0xbb4c483afe706e253f6a4b2f5e3d56e16e513b5b4ea360c3408d2d6e388630bd
→ Block: 43763168, Status: success
→ 投票给 pollId=0, optionIndex=1（Rust）
```

### Read: `getResult()` 和 `polls()`

```
cast call 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC "getResult(uint256)(uint256[])" 0
→ [0, 1, 0, 0]  — Solidity(0票) Rust(1票) Go(0票) Python(0票)

cast call 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC "polls(uint256)(string,uint256,uint256,bool)" 0
→ "Monad Builder Camp Week 1 Demo", 1783710834, 4, true
```

## 如何部署（Foundry）

```bash
# 1. 编译
forge build

# 2. 部署到 Monad Testnet
forge create contracts/Voting.sol:Voting \
  --rpc-url https://testnet-rpc.monad.xyz \
  --private-key <YOUR_PRIVATE_KEY> \
  --legacy --broadcast
```

## 如何交互（cast）

```bash
RPC="https://testnet-rpc.monad.xyz"
ADDR="<合约地址>"
PK="<私钥>"

# Read — 查询投票数
cast call $ADDR "pollCount()(uint256)" --rpc-url $RPC

# Write — 创建投票
cast send $ADDR "createPoll(string,string[],uint256)" \
  "投票标题" '["选项A","选项B"]' 30 \
  --rpc-url $RPC --private-key $PK --legacy

# Write — 投票
cast send $ADDR "vote(uint256,uint256)" 0 0 \
  --rpc-url $RPC --private-key $PK --legacy

# Read — 查询结果
cast call $ADDR "getResult(uint256)(uint256[])" 0 --rpc-url $RPC
```

## 全链路总结

```
合约源码 (Voting.sol, 73行)
  → forge build 编译
  → forge create 部署到 Monad Testnet
  → 合约地址: 0x381B5cfbAC921cA07Ad3615ad9aeB736F5B203FC
  → cast call 调用 read function (pollCount, getResult, polls)
  → cast send 调用 write function (createPoll, vote)
  → 区块浏览器验证: testnet.monadscan.com
```
