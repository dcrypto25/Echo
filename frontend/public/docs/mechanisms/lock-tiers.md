# Lock Tiers

EchoForge's lock tier system allows users to voluntarily lock their eECHO for fixed periods in exchange for APY multipliers up to 4×, rewarding long-term commitment.

## Overview

Users can choose to lock their eECHO tokens for 30, 90, 180, or 365 days, receiving progressively higher APY multipliers. Locked tokens continue to rebase at the boosted rate.

**Key Feature**: Locks are **voluntary** - users can stake without locking and maintain full flexibility, or commit to locks for significantly higher returns.

## Tier Structure

### Multipliers

```
No Lock:     1.0× base APY (full flexibility)
30 days:     1.2× base APY (+20%)
90 days:     2.0× base APY (+100%)
180 days:    3.0× base APY (+200%)
365 days:    4.0× base APY (+300%)
```

### Return Comparison

At base APY of 5,000%:

```
No Lock:     5,000% APY
30 days:     6,000% APY (1.2× multiplier)
90 days:    10,000% APY (2.0× multiplier)
180 days:   15,000% APY (3.0× multiplier)
365 days:   20,000% APY (4.0× multiplier)
```

**1-Year Growth Example**:
```
Starting balance: 10,000 eECHO

No lock:  10,000 × 51 = 510,000 eECHO
30-day:   10,000 × 61 = 610,000 eECHO (+100k)
90-day:   10,000 × 101 = 1,010,000 eECHO (+500k)
180-day:  10,000 × 151 = 1,510,000 eECHO (+1M)
365-day:  10,000 × 201 = 2,010,000 eECHO (+1.5M)
```

**The 365-day lock generates 4× more eECHO than unlocked.**

## Mechanics

### Locking Process

```solidity
function lock(uint256 amount, uint8 tier) external {
    require(tier >= 1 && tier <= 4, "Invalid tier");
    require(eECHO.balanceOf(msg.sender) >= amount, "Insufficient balance");

    // Transfer eECHO to lock contract
    eECHO.transferFrom(msg.sender, address(this), amount);

    // Record lock
    locks[msg.sender].push(Lock({
        amount: amount,
        tier: tier,
        startTime: block.timestamp,
        duration: _getTierDuration(tier),
        claimed: false
    }));

    emit Locked(msg.sender, amount, tier, block.timestamp + _getTierDuration(tier));
}

function _getTierDuration(uint8 tier) internal pure returns (uint256) {
    if (tier == 1) return 30 days;
    if (tier == 2) return 90 days;
    if (tier == 3) return 180 days;
    if (tier == 4) return 365 days;
    revert("Invalid tier");
}
```

### Rebase Calculation

Locked tokens rebase at a **modified rate**:

```solidity
function _calculateLockedRebase(
    uint256 baseRebaseRate,
    uint8 tier
) internal pure returns (uint256) {
    uint256 multiplier = _getTierMultiplier(tier);

    // Multiply the base rate
    // baseRebaseRate = (1 + APY)^(1/1095) - 1
    // lockedRate = (1 + APY × multiplier)^(1/1095) - 1

    uint256 multipliedAPY = baseAPY * multiplier / 100;  // Apply multiplier
    return _calculateRebaseRate(multipliedAPY);
}

function _getTierMultiplier(uint8 tier) internal pure returns (uint256) {
    if (tier == 1) return 120;  // 1.2×
    if (tier == 2) return 200;  // 2.0×
    if (tier == 3) return 300;  // 3.0×
    if (tier == 4) return 400;  // 4.0×
    return 100;  // 1.0× (no lock)
}
```

### Balance Tracking

Locked balances are tracked separately:

```solidity
struct Lock {
    uint256 amount;        // Initial locked amount (in eECHO)
    uint256 gons;          // Gons representation for rebase tracking
    uint8 tier;            // Lock tier (1-4)
    uint256 startTime;     // Lock start timestamp
    uint256 duration;      // Lock duration in seconds
    bool claimed;          // Whether unlocked and claimed
}

mapping(address => Lock[]) public locks;
```

**User can have multiple locks**:
```
User locks:
- Lock 1: 5,000 eECHO for 365 days (4× multiplier)
- Lock 2: 3,000 eECHO for 90 days (2× multiplier)
- Lock 3: 2,000 eECHO for 30 days (1.2× multiplier)

Each lock tracked independently
Each rebases at its own multiplied rate
```

### Unlocking

At lock expiration:

```solidity
function unlock(uint256 lockIndex) external {
    Lock storage userLock = locks[msg.sender][lockIndex];
    require(!userLock.claimed, "Already claimed");
    require(block.timestamp >= userLock.startTime + userLock.duration, "Still locked");

    // Calculate final balance (with rebases applied)
    uint256 finalAmount = _calculateLockBalance(userLock);

    // Transfer eECHO back to user
    eECHO.transfer(msg.sender, finalAmount);

    // Mark as claimed
    userLock.claimed = true;

    emit Unlocked(msg.sender, lockIndex, finalAmount);
}
```

## Early Unlock Penalty

Users can unlock before expiration with a time-based penalty:

### Penalty Formula

```
penalty = 90% - (80% × timeServed / totalDuration)

Range: 90% (immediate) to 10% (at completion)
```

**Examples**:

```
365-day lock, unlock after 100 days:
timeServed = 100 days
totalDuration = 365 days
penalty = 90% - (80% × 100/365) = 90% - 21.9% = 68.1%

User keeps: 31.9%
Protocol burns: 68.1%
```

```
90-day lock, unlock after 60 days:
penalty = 90% - (80% × 60/90) = 90% - 53.3% = 36.7%

User keeps: 63.3%
Protocol burns: 36.7%
```

```
30-day lock, unlock after 29 days:
penalty = 90% - (80% × 29/30) = 90% - 77.3% = 12.7%

User keeps: 87.3%
Protocol burns: 12.7%
```

### Early Unlock Process

```solidity
function earlyUnlock(uint256 lockIndex) external {
    Lock storage userLock = locks[msg.sender][lockIndex];
    require(!userLock.claimed, "Already claimed");

    // Calculate current balance with rebases
    uint256 currentBalance = _calculateLockBalance(userLock);

    // Calculate penalty
    uint256 timeServed = block.timestamp - userLock.startTime;
    uint256 penalty = _calculateEarlyUnlockPenalty(timeServed, userLock.duration);

    // Apply penalty
    uint256 penaltyAmount = currentBalance * penalty / 10000;
    uint256 userAmount = currentBalance - penaltyAmount;

    // Burn penalty
    eECHO.burn(penaltyAmount);

    // Transfer remaining to user
    eECHO.transfer(msg.sender, userAmount);

    userLock.claimed = true;

    emit EarlyUnlocked(msg.sender, lockIndex, userAmount, penaltyAmount);
}

function _calculateEarlyUnlockPenalty(
    uint256 timeServed,
    uint256 totalDuration
) internal pure returns (uint256) {
    // penalty = 9000 - (8000 × timeServed / totalDuration)
    uint256 reduction = (8000 * timeServed) / totalDuration;
    return 9000 - reduction;  // Returns basis points (9000 = 90%)
}
```

## Economic Rationale

### Why Multipliers?

Lock tiers solve the **duration commitment problem**:

**Problem**:
```
User A: Stakes 10,000 ECHO, unstakes next day
User B: Stakes 10,000 ECHO, holds 1 year

Both earn same APY
User A took no risk, got free option
User B committed capital, same reward
Result: No incentive for long-term holding
```

**Solution with Lock Tiers**:
```
User A: No lock, earns 5,000% APY
User B: 365-day lock, earns 20,000% APY (4× multiplier)

User B earns 4× more for commitment
User A has flexibility but lower returns
Result: Balanced incentives
```

### Protocol Benefits

Long-term locks benefit the protocol:

1. **Reduced Selling Pressure**:
```
Without locks: Users can unstake anytime
→ High volatility
→ Frequent bank run risk
→ Unstable backing

With locks: Significant supply locked for months
→ Reduced liquid supply
→ Less unstaking during stress
→ More stable backing
```

2. **Predictable Treasury Planning**:
```
Protocol knows:
- 40% locked for 365 days
- 25% locked for 90-180 days
- 35% unlocked

Can plan:
- Yield strategy allocations
- Liquidity reserves
- Risk management
```

3. **Deflationary Burns**:
```
Early unlock penalties = 100% burned
No treasury portion (unlike unstake penalties)

Result: Pure supply reduction
Improves backing ratio
```

### User Benefits

**Higher Returns**:
```
10,000 eECHO unlocked at 5,000% APY:
After 1 year: 510,000 eECHO

10,000 eECHO locked 365 days at 20,000% APY:
After 1 year: 2,010,000 eECHO

Difference: 1,500,000 eECHO (294% more)
```

**Strategic Flexibility**:
```
User can split position:
- 50% locked 365 days (max returns)
- 30% locked 90 days (medium returns + earlier access)
- 20% unlocked (full flexibility)

Balances risk vs reward
```

## Lock Strategies

### Maximum Returns

```
Strategy: All-in 365-day lock

Stake: 100,000 ECHO
Lock: 100,000 eECHO for 365 days
Multiplier: 4×
APY: 20,000% (if base is 5,000%)

After 1 year:
Balance: 20,100,000 eECHO
ROI: 20,000%

Risk: Cannot exit for 1 year without severe penalty
Best for: Strong conviction, long-term holders
```

### Laddered Locks

```
Strategy: Stagger unlock dates

Month 1: Lock 25,000 eECHO for 365 days
Month 4: Lock 25,000 eECHO for 365 days
Month 7: Lock 25,000 eECHO for 365 days
Month 10: Lock 25,000 eECHO for 365 days

Result:
- Every 3 months, a lock matures
- Continuous access to liquidity
- Maintain 4× multiplier across all locks
- Can reinvest or withdraw unlocked portions

Best for: Regular liquidity needs, dollar-cost averaging out
```

### Barbell Strategy

```
Strategy: Combine extremes

80,000 eECHO locked for 365 days (4× multiplier)
20,000 eECHO unlocked (1× multiplier, full flexibility)

Benefits:
- Majority earning maximum returns
- Minority available for opportunistic unstaking
- Can lock the flexible portion later if confident

Best for: Balanced risk management
```

### Tier Stepping

```
Strategy: Start short, extend if confident

Month 1: Lock 50,000 for 30 days (1.2× multiplier)
Month 2: Unlock, relock for 90 days (2.0× multiplier)
Month 5: Unlock, relock for 180 days (3.0× multiplier)
Month 11: Unlock, relock for 365 days (4.0× multiplier)

Benefits:
- Test protocol with lower commitment
- Gradually increase exposure
- Learn while earning

Best for: New users, conservative investors
```

## Advanced Mechanics

### Lock Extension

Users can extend existing locks:

```solidity
function extendLock(uint256 lockIndex, uint8 newTier) external {
    Lock storage userLock = locks[msg.sender][lockIndex];
    require(!userLock.claimed, "Already claimed");
    require(newTier > userLock.tier, "Must upgrade tier");

    uint256 timeRemaining = (userLock.startTime + userLock.duration) - block.timestamp;
    uint256 newDuration = _getTierDuration(newTier);

    // Extend duration
    userLock.tier = newTier;
    userLock.duration = newDuration;
    userLock.startTime = block.timestamp;  // Reset start time

    emit LockExtended(msg.sender, lockIndex, newTier);
}
```

**Example**:
```
Original: 10,000 eECHO locked for 90 days, 60 days remaining
Current balance: 11,500 eECHO (after rebases)

Extend to 365 days:
- New lock: 11,500 eECHO for 365 days (from now)
- Multiplier: 2× → 4×
- New APY: 10,000% → 20,000%
```

### Partial Unlocking

Users can unlock portions of a lock:

```solidity
function partialUnlock(uint256 lockIndex, uint256 amount) external {
    Lock storage userLock = locks[msg.sender][lockIndex];
    uint256 currentBalance = _calculateLockBalance(userLock);
    require(amount <= currentBalance, "Insufficient balance");

    // Calculate penalty on unlocked amount
    uint256 penalty = _calculateEarlyUnlockPenalty(...);
    uint256 penaltyAmount = amount * penalty / 10000;
    uint256 userAmount = amount - penaltyAmount;

    // Reduce lock balance
    userLock.gons -= _convertToGons(amount);

    // Burn penalty, transfer remaining
    eECHO.burn(penaltyAmount);
    eECHO.transfer(msg.sender, userAmount);

    emit PartialUnlock(msg.sender, lockIndex, amount, penaltyAmount);
}
```

**Use case**:
```
Lock: 100,000 eECHO for 365 days
After 200 days: Balance is ~135,000 eECHO

Emergency: Need 20,000 eECHO
Partial unlock: 20,000 eECHO
Penalty: ~40% (200/365 served)
Receive: 12,000 eECHO
Remaining locked: 115,000 eECHO continues earning 4×
```

### Compounding Unlocks

Users can auto-relock upon maturity:

```solidity
function setAutoRelock(uint256 lockIndex, bool enabled, uint8 tier) external {
    locks[msg.sender][lockIndex].autoRelock = enabled;
    locks[msg.sender][lockIndex].autoRelockTier = tier;
}

function _processUnlock(Lock storage userLock) internal {
    if (userLock.autoRelock) {
        // Calculate final balance
        uint256 finalBalance = _calculateLockBalance(userLock);

        // Create new lock automatically
        _createLock(msg.sender, finalBalance, userLock.autoRelockTier);

        userLock.claimed = true;
    }
}
```

**Benefit**:
```
Initial lock: 10,000 eECHO for 365 days
After 1 year: 20,100,000 eECHO

Auto-relock enabled:
New lock: 20,100,000 eECHO for 365 days
After year 2: 404,010,000 eECHO

No manual intervention required
Maximum compounding
```

## Risk Considerations

### Lock-Up Risk

**Liquidity Risk**:
```
User locks 100,000 eECHO for 365 days
Market crashes on day 30
User cannot exit without:
- 83% penalty (30/365 served)
- Only receive 17,000 eECHO

Locked funds inaccessible at favorable terms
```

**Mitigation**: Only lock capital you won't need for duration

### Penalty Risk

**Early Exit Cost**:
```
365-day lock, unlock after 90 days:
Penalty: 70.4%

User effectively:
- Earned 4× APY for 90 days
- Paid 70.4% penalty
- Net: Likely negative return vs unlocked

Early unlock almost always unprofitable
```

**Mitigation**: Use shorter lock periods if uncertain

### Protocol Risk

**Compounding Uncertainty**:
```
Lock 10,000 eECHO for 365 days at 20,000% APY
Expected: 2,010,000 eECHO

But APY is dynamic:
- If backing drops, base APY reduces
- Your multiplier still applies to lower base
- e.g., base 2,000% × 4× = 8,000% (not 20,000%)

Locked at uncertain rate
```

**Mitigation**: Locks are higher risk/reward than flexible staking

## Monitoring Locks

### User Dashboard

```
Your Locks:
├── Lock 1: 50,000 eECHO
│   ├── Tier: 365 days (4× multiplier)
│   ├── Started: Jan 1, 2026
│   ├── Unlocks: Jan 1, 2027 (245 days remaining)
│   ├── Current balance: 73,425 eECHO (+46.9%)
│   ├── Early unlock penalty: 46.4%
│   └── Projected at maturity: 201,000 eECHO
│
├── Lock 2: 20,000 eECHO
│   ├── Tier: 90 days (2× multiplier)
│   ├── Started: Mar 15, 2026
│   ├── Unlocks: Jun 13, 2026 (12 days remaining)
│   ├── Current balance: 22,840 eECHO (+14.2%)
│   ├── Early unlock penalty: 13.4%
│   └── Projected at maturity: 24,100 eECHO
```

### Protocol Metrics

```
Total Locked: 45M eECHO (68% of supply)
├── 365-day: 28M eECHO (62%)
├── 180-day: 10M eECHO (22%)
├── 90-day: 5M eECHO (11%)
└── 30-day: 2M eECHO (5%)

Average lock duration: 287 days
Early unlock rate: 3.2% of locks
Total burned from early unlocks: 2.4M eECHO
```

---

**Last updated**: November 2025
**Related**: [Dynamic APY](./dynamic-apy.md) | [Unstake Penalty](./unstake-penalty.md)
