# Dynamic APY System

EchoForge's Dynamic APY System is the core self-regulating mechanism that prevents death spirals by automatically adjusting emissions based on protocol health.

## Overview

Unlike fixed APY models that collapsed in previous reserve currency experiments, EchoForge's APY scales with the backing ratio, creating a natural equilibrium between growth and sustainability.

**Key Innovation**: APY automatically responds to treasury health, ensuring emissions never exceed the protocol's capacity to maintain backing.

## Formula

The Dynamic APY is calculated using a piecewise linear function based on the backing ratio:

```
APY(β) = {
  30,000%     if β ≥ 200%
  5,000%      if β = 100%
  0%          if β ≤ 50%

  Linear interpolation between thresholds
}
```

### Precise Calculation

```solidity
function calculateDynamicAPY(uint256 backingRatio) public pure returns (uint256) {
    if (backingRatio >= 20000) {  // ≥200%
        return 30000;  // 30,000% APY
    } else if (backingRatio >= 10000) {  // 100-200%
        // Linear from 5,000% at 100% to 30,000% at 200%
        return 5000 + ((backingRatio - 10000) * 25000) / 10000;
    } else if (backingRatio >= 5000) {  // 50-100%
        // Linear from 0% at 50% to 5,000% at 100%
        return ((backingRatio - 5000) * 5000) / 5000;
    } else {  // <50%
        return 0;  // No emissions below 50% backing
    }
}
```

**Backing Ratio (β)** is expressed in basis points (10000 = 100%)

## Economic Rationale

### Self-Regulation Mechanism

The Dynamic APY creates four distinct economic zones:

**1. Expansion Zone (β ≥ 200%)**
- **APY**: 30,000% (maximum)
- **Goal**: Rapid growth to attract capital
- **Safety**: Massive treasury cushion allows aggressive emissions
- **Outcome**: High returns incentivize staking, grows user base

**2. Growth Zone (100% ≤ β < 200%)**
- **APY**: 5,000-30,000% (linear scaling)
- **Goal**: Balanced expansion
- **Safety**: Adequate backing supports emissions
- **Outcome**: Attractive yields maintain growth

**3. Consolidation Zone (50% < β < 100%)**
- **APY**: 0-5,000% (linear scaling)
- **Goal**: Slow growth, rebuild backing
- **Safety**: Reduced emissions conserve treasury
- **Outcome**: Lower yields discourage new stakes, penalties fund treasury

**4. Crisis Zone (β ≤ 50%)**
- **APY**: 0% (no emissions)
- **Goal**: Complete emission halt
- **Safety**: Prevent further backing erosion
- **Outcome**: No rebases, treasury rebuilds via penalties and yield

### Why This Works

**Traditional Fixed APY Problem**:
```
OlympusDAO: 8,000% APY regardless of backing
→ Treasury at 100% backing still paying 8,000%
→ Emissions exceed treasury growth
→ Backing drops to 80%
→ Still paying 8,000% APY
→ Death spiral accelerates
```

**Dynamic APY Solution**:
```
EchoForge: APY scales with backing
→ Treasury at 100% backing paying 5,000%
→ Backing drops to 90%
→ APY reduces to 4,000%
→ Lower emissions slow backing decline
→ Penalties + yield rebuild backing
→ System stabilizes
```

## Per-Rebase Rate Calculation

The eECHO token rebases every 8 hours (1,095 times per year). The per-rebase rate uses **compound growth mathematics**:

```
rebaseRate = (1 + APY)^(1/1095) - 1
```

### Why Compound Formula?

**Critical Difference**: This is NOT linear division

```
❌ WRONG (linear): rebaseRate = APY / 1095
✅ CORRECT (compound): rebaseRate = (1 + APY)^(1/1095) - 1
```

**Example at 5,000% APY**:

```
Linear (WRONG):
rebaseRate = 5000% / 1095 = 4.566% per rebase
After 1095 rebases: (1.04566)^1095 = 51.00× ❌
→ Actually delivers 5,000% APY

Compound (CORRECT):
rebaseRate = (1 + 50)^(1/1095) - 1 = 0.3679% per rebase
After 1095 rebases: (1.003679)^1095 = 51.00× ✅
→ Exactly delivers 5,000% APY
```

**Why It Matters**: Using linear division would massively over-emit tokens, breaking the economic model.

## Rebase Execution

### Trigger

Anyone can call the `rebase()` function on the eECHO contract. There is no access control - this is intentional to ensure rebases always occur.

```solidity
function rebase() external {
    require(block.timestamp >= nextRebase, "Too early");

    // 1. Query treasury for current backing ratio
    uint256 backingRatio = treasury.getBackingRatio();

    // 2. Calculate current APY based on backing
    uint256 currentAPY = calculateDynamicAPY(backingRatio);

    // 3. Calculate per-rebase rate (compound growth)
    uint256 rebaseRate = _calculateRebaseRate(currentAPY);

    // 4. Increase total supply
    totalSupply = totalSupply * (BASIS + rebaseRate) / BASIS;

    // 5. Decrease gons per fragment (balances auto-update)
    gonsPerFragment = TOTAL_GONS / totalSupply;

    // 6. Schedule next rebase
    nextRebase = block.timestamp + 8 hours;

    emit Rebase(totalSupply, currentAPY, rebaseRate);
}
```

### Balance Updates

Users **never** need to claim rebases. The gons mechanism ensures all balances update automatically:

```solidity
// User balance calculation
function balanceOf(address user) public view returns (uint256) {
    return gonBalances[user] / gonsPerFragment;
}
```

When `gonsPerFragment` decreases (during rebase), all balances increase proportionally.

## APY Scenarios

### Launch Scenario

**Initial State**:
- Backing ratio: 400% (from bonding curve)
- Treasury: $40,000
- Market cap: $10,000
- APY: 30,000% (maximum)

**After 30 Days**:
- If stakers hold: Balance grows ~2.1× at 30,000% APY
- New market cap: $21,000
- If treasury grows 20% from yield: $48,000
- New backing ratio: $48,000 / $21,000 = 228%
- APY remains: 30,000%

### Healthy Scenario

**State**:
- Backing ratio: 120%
- Treasury: $600,000
- Market cap: $500,000
- APY: 10,000%

**After 30 Days**:
- Balance grows ~1.4× at 10,000% APY
- New market cap: $700,000
- Treasury grows from yield + penalties: $650,000
- New backing ratio: $650,000 / $700,000 = 93%
- APY reduces to: 4,300%

**Outcome**: Lower APY slows growth, allows treasury to catch up

### Stress Scenario

**State**:
- Backing ratio: 70%
- Treasury: $350,000
- Market cap: $500,000
- APY: 2,000%

**After 30 Days**:
- Balance grows ~1.05× at 2,000% APY
- New market cap: $525,000
- Heavy unstaking penalties: 50% burned, 50% to treasury
- Treasury grows from penalties + yield: $420,000
- New backing ratio: $420,000 / $525,000 = 80%
- APY increases to: 3,000%

**Outcome**: Lower emissions + penalties rebuild backing

## Integration with Other Mechanisms

### Lock Tier Multipliers

Lock tiers multiply the base APY:

```
User locks 1,000 eECHO for 365 days (4× multiplier)
Base APY: 5,000%
User's effective APY: 20,000%

Per-rebase rate: (1 + 200)^(1/1095) - 1 = 1.016%
User balance after 1 year: 1,000 × 201 = 201,000 eECHO
```

The multiplier is applied to the user's rebase rate, not the global supply.

### Referral Emissions

Referral bonuses are **separate** from rebase emissions:

```
User stakes 10,000 ECHO
Referrer receives: 400 eECHO (4%)

This 400 eECHO is minted instantly
It then participates in future rebases at the base APY
```

Referral minting does NOT affect the backing ratio calculation for APY determination.

### Transfer Tax

The transfer tax rate (4-15%) is **independent** of APY:

```
Tax rate = 4% + 11% × max(0, (90% - stakingRatio) / 90%)

This funds treasury regardless of APY
Even at 0% APY, transfer tax continues generating revenue
```

## Economic Analysis

### Sustainability

**Revenue Requirement** at 100% backing and 5,000% APY:

```
Market cap: $1M
Staked: 90% = $900k
Annual emissions to pay 5,000% APY: 900k × 50 = $45M in new tokens

If price holds:
New market cap: $45M + $1M = $46M
Required treasury growth: $460k to $46M

This is impossible → price cannot hold
```

**What Actually Happens**:

```
1. Price declines as supply increases
2. Market cap in dollars stays stable (more tokens × lower price)
3. Treasury grows from:
   - Transfer taxes on selling
   - Unstake penalties
   - DeFi yield
4. Backing ratio maintained through:
   - Deflationary burns
   - Treasury inflows
   - Reduced emissions if backing drops
```

### Equilibrium Finding

The system naturally finds equilibrium through feedback loops:

**If APY too high for backing**:
→ Rapid emissions increase supply
→ Selling pressure lowers price
→ Market cap stays stable, backing ratio drops
→ APY automatically reduces
→ Lower emissions slow the cycle

**If APY too low**:
→ Stakers have incentive to unstake
→ Unstake penalties heavily fund treasury
→ Supply burns increase scarcity
→ Backing ratio improves
→ APY automatically increases
→ Higher APY attracts stakers back

This creates a **stable oscillation** around the equilibrium backing ratio of 100-150%.

## Historical Context

### OlympusDAO Failure Analysis

**OlympusDAO Model**:
- Fixed 8,000% APY
- Backing started at 100%+
- APY never adjusted
- Death spiral result

**Timeline**:
1. Launch: 100% backing, attractive yields
2. Growth: Emissions exceed treasury growth
3. Backing drops: 80% → 60% → 40%
4. APY unchanged: Still paying 8,000%
5. Bank run: Mass unstaking
6. Collapse: -99.7% from peak

**EchoForge Improvement**:

Same scenario with Dynamic APY:
1. Launch: 100% backing, 5,000% APY
2. Backing drops to 80%: APY reduces to 3,000%
3. Lower emissions slow decline
4. Penalties + yield rebuild backing
5. Backing recovers to 90%: APY increases to 4,000%
6. Equilibrium: Oscillates around 100-120% backing

## Monitoring

### Key Metrics

Users should monitor these indicators:

**Backing Ratio**:
- ≥150%: Very healthy, high APY justified
- 100-150%: Healthy, sustainable
- 80-100%: Caution, watch for APY reduction
- <80%: Stress, expect low/zero APY

**Current APY**:
- Reflects real-time protocol health
- Higher APY = stronger backing
- Sudden drops indicate backing issues

**Treasury Trend**:
- Should grow from DeFi yield
- Should grow faster than market cap
- Declining treasury is red flag

**Staking Ratio**:
- >90%: Healthy, most supply staked
- 70-90%: Moderate, some unstaking
- <70%: Stress, mass unstaking

### Dashboard Display

The frontend displays:

```
Current APY: 5,000%
Backing Ratio: 120%
Next Rebase: 4:23:15
Your Balance: 10,542 eECHO (+42 since last rebase)
```

## Risk Considerations

### APY Volatility

APY can change significantly between rebases:

```
Rebase #1: 120% backing → 10,000% APY
Large unstake occurs
Rebase #2: 90% backing → 4,000% APY
```

Users should understand that APY is NOT guaranteed and fluctuates with protocol health.

### Zero APY Scenario

If backing drops below 50%, APY goes to 0%:

```
No rebases occur (or rebases at 0% rate)
Balances do not grow
Users still locked in queue + penalties to unstake
Treasury focuses on rebuilding backing
```

This is **intentional** - it prevents further backing erosion during crisis.

### Recovery Mechanics

Even at 0% APY, the protocol can recover:

```
1. Transfer tax continues: 4-15% funds treasury
2. Unstake penalties: 50-75% burns + treasury funding
3. DeFi yield: 15-30% APY on treasury assets
4. Buyback burns: Support price floor

Treasury grows while emissions paused
Backing ratio recovers
APY increases again when backing >50%
```

## Advanced Topics

### APY vs Price Relationship

APY does NOT directly correlate with price:

```
Scenario 1: 30,000% APY, price $10
- High emissions, rapid supply growth
- Price may decline despite high APY
- Net user value may not increase

Scenario 2: 5,000% APY, price stable
- Moderate emissions, sustainable growth
- Price stability preserves value
- User holdings grow 51× per year
```

**Better metric**: Dollar value of holdings over time

### Optimal APY Theory

The "optimal" APY balances:

1. **Attraction**: High enough to attract stakers
2. **Sustainability**: Low enough for treasury to support
3. **Stability**: Predictable enough for planning

Analysis suggests:
- <2,000% APY: Uncompetitive in DeFi
- 2,000-8,000% APY: Sweet spot for sustainability
- >15,000% APY: Likely unsustainable long-term

EchoForge's Dynamic APY naturally gravitates toward this sweet spot at 100-150% backing (5,000-12,500% APY).

---

**Last updated**: November 2025
**Related**: [Treasury Backing](./treasury-backing.md) | [Mathematics](../mathematics.md)
