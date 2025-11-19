# EchoForge - Complete Mathematical Specification

## Table of Contents

1. [Core Constants & Variables](#core-constants--variables)
2. [Rebase Mathematics](#rebase-mathematics)
3. [Dynamic APY System](#dynamic-apy-system)
4. [Dynamic Unstake Penalty (DUP)](#dynamic-unstake-penalty-dup)
5. [Redemption Queue Length](#redemption-queue-length)
6. [Time-Based Unlock Penalty](#time-based-unlock-penalty)
7. [Adaptive Transfer Tax](#adaptive-transfer-tax)
8. [Treasury Buyback Engine](#treasury-buyback-engine)
9. [Lock Tier Multipliers](#lock-tier-multipliers)
10. [Referral Bonus Distribution](#referral-bonus-distribution)
11. [Bonding Curve Pricing](#bonding-curve-pricing)
12. [Appendix: Example Calculations](#appendix-example-calculations)

---

## Core Constants & Variables

### Universal Constants

```
PRECISION = 1e18                    // 18 decimal fixed-point precision
BASIS_POINTS = 10000                // 100.00% = 10000 basis points
SECONDS_PER_YEAR = 31536000         // 365 days
REBASE_INTERVAL = 28800             // 8 hours in seconds
REBASES_PER_YEAR = 1095             // 365 × 3 rebases per day
```

### Protocol Variables

| Variable | Symbol | Description | Range |
|----------|--------|-------------|-------|
| Backing Ratio | `β` | Treasury value / ECHO market cap | 0% - ∞ |
| Staking Ratio | `σ` | Staked ECHO / Total ECHO | 0% - 100% |
| Rebase Rate | `r` | Per-rebase growth rate | 0% - 5% |
| APY | `A` | Annual Percentage Yield | 0% - 10,000% |
| Treasury Yield | `y` | Annual yield from GMX/GLP | 0% - 50% |
| ECHO Price | `p` | Market price in ETH | > 0 |
| TWAP | `p̄` | 30-day time-weighted average price | > 0 |

---

## Rebase Mathematics

### Gons-Based Elastic Supply

eECHO uses a "gons" mechanism where each user's share of total supply remains constant, but total supply changes.

**Constant Gons Per Address**:
```
gonsPerFragment = TOTAL_GONS / totalSupply
userGons = userBalance × gonsPerFragment
```

**Balance Calculation**:
```
balanceOf(user) = userGons / gonsPerFragment
```

**Rebase Formula**:
```
newTotalSupply = oldTotalSupply × (1 + rebaseRate)
newGonsPerFragment = TOTAL_GONS / newTotalSupply
```

**Example**:
```
Initial State:
  totalSupply = 1,000,000 eECHO
  TOTAL_GONS = 1e25 (constant forever)
  gonsPerFragment = 1e25 / 1,000,000 = 1e19

  Alice holds 1000 eECHO
  Alice's gons = 1000 × 1e19 = 1e22 (never changes)

After 1% Rebase:
  newTotalSupply = 1,000,000 × 1.01 = 1,010,000 eECHO
  newGonsPerFragment = 1e25 / 1,010,000 = 9.9009...e18

  Alice's new balance = 1e22 / 9.9009e18 = 1010 eECHO (+1% as expected)
```

---

## Dynamic APY System

### Overview

v2.0 replaces the dampener mechanism with a direct dynamic APY calculation. The APY responds exponentially to backing ratio changes, creating self-regulating market forces without complex multipliers.

**Philosophy**: No fixed targets. Pure market dynamics.
- High backing → Aggressive APY → Attract capital → Grow protocol
- Backing drops → APY drops FAST → Stabilize naturally
- System finds its own equilibrium based on treasury health

### Formula

```solidity
function calculateDynamicAPY(uint256 backingRatio) public pure returns (uint256) {
    if (backingRatio >= 20000) {
        // ≥200% backing: MAXIMUM AGGRESSION
        return 3000000;  // 30,000% APY
    }

    if (backingRatio >= 15000) {
        // 150-200% backing: Very aggressive
        // Scale from 12,000% to 30,000%
        uint256 excess = backingRatio - 15000;
        return 1200000 + (excess * 360 / 100);
    }

    if (backingRatio >= 12000) {
        // 120-150% backing: Aggressive
        // Scale from 8,000% to 12,000%
        uint256 excess = backingRatio - 12000;
        return 800000 + (excess * 133 / 100);
    }

    if (backingRatio >= 10000) {
        // 100-120% backing: Still attractive
        // Scale from 5,000% to 8,000%
        uint256 excess = backingRatio - 10000;
        return 500000 + (excess * 150 / 100);
    }

    if (backingRatio >= 9000) {
        // 90-100% backing: GRADUAL DROP
        // Drop from 5,000% to 3,500%
        uint256 deficit = 10000 - backingRatio;
        return 500000 - (deficit * 150 / 100);
    }

    if (backingRatio >= 8000) {
        // 80-90% backing: Moderate slowdown
        // Drop from 3,500% to 2,500%
        uint256 deficit = 9000 - backingRatio;
        return 350000 - (deficit * 100 / 100);
    }

    if (backingRatio >= 7000) {
        // 70-80% backing: Stronger slowdown
        // Drop from 2,500% to 2,000%
        uint256 deficit = 8000 - backingRatio;
        return 250000 - (deficit * 50 / 100);
    }

    // <70% backing: EMERGENCY STOP
    if (backingRatio <= 5000) return 0;  // <50%: 0% APY

    uint256 deficit = 7000 - backingRatio;
    uint256 apy = 200000 - (deficit * 10 / 100);
    return apy > 0 ? apy : 0;
}
```

### APY Response Table

| Backing Ratio | APY | Behavior |
|---------------|-----|----------|
| ≥300% | 30,000% | Maximum aggression - attract ALL capital |
| 200% | 18,000% | Very aggressive growth mode |
| 150% | 12,000% | Still very high |
| 120% | 8,000% | Solid, attractive |
| 100% | 5,000% | Healthy baseline |
| 90% | 3,500% | Gradual drop (still great for buying!) |
| 80% | 2,500% | Moderate slowdown |
| 70% | 2,000% | "Catching the knife" |
| 60% | 1,000% | Deep crisis |
| 50% | 0% | Emergency stop |

### Example Scenarios

**Scenario 1: Bull Run (β = 150%)**
```
APY = 12,000%
Rebase rate per 8 hours = (1 + 120)^(1/1095) - 1 ≈ 0.4577%
User with 1000 eECHO gets ~4.58 eECHO per rebase
Queue time: 0 days (instant unstaking available)
```

**Scenario 2: Market Correction (β = 95%)**
```
APY drops from 5,000% → 4,250%
15% APY reduction signals caution without panic
Still attractive enough to prevent mass exodus
```

**Scenario 3: Crisis (β = 70%)**
```
APY = 2,000% (60% reduction from 100% backing)
Combined with queue + DUP creates strong stabilization
Emissions slow dramatically without stopping completely
```

### Self-Regulating Loop

**Positive Feedback (Growth)**:
```
1. High backing (150%) → High APY (12,000%)
2. High APY → Attracts new capital
3. New capital buys ECHO → Treasury receives deposits
4. Treasury value increases from new capital inflows
5. Price may rise from buying pressure
6. BUT: Treasury grows faster than price from deposits
7. Backing maintained/increased → Even higher APY
8. Exponential growth phase

Note: Backing = Treasury / (Supply × Price)
If price 2x but treasury 3x from new deposits → backing INCREASES
```

**Negative Feedback (Stabilization)**:
```
1. Backing drops to 90%
2. APY drops from 5,000% → 3,500% (FAST)
3. Lower APY → Less attractive, slower emissions
4. Queue + DUP slow selling
5. Treasury buybacks execute
6. Backing stabilizes and recovers
```

---

## Dynamic Unstake Penalty (DUP)

### Overview

EchoForge implements an **exponential penalty curve** that provides superior protection during crises while encouraging trading volume when the protocol is healthy. This is a significant improvement over the linear curves used by OHM and other predecessors.

**Key Philosophy**:
- **120%+ backing → Free to unstake** (0% penalty, very healthy protocol)
- **100% backing → Minimal friction** (~6.1% penalty)
- **Crisis mode (50-70% backing) → Severe protection** (38-75% penalty)
- **Always-present penalty** ensures protocol health at all backing levels
- **Exponential scaling** prevents death spirals more effectively than linear curves

### Formula

The penalty uses an **exponential function** that scales from 0% to 75% based on backing ratio.

```
penalty(β) = {
    0%,                                    if β ≥ 120%
    75% × ((120% - β) / 70%)²,            if 50% ≤ β < 120%
    75%,                                   if β < 50%
}
```

**Mathematical Expression**:
```
penalty(β) = max(0, min(75%, 75% × ((1.20 - β) / 0.70)²))

Where:
  β = backing ratio (treasury value / market cap)
  The squaring creates exponential growth as backing decreases
```

### Why Exponential is Superior to Linear

**Problem with Linear Curves** (OHM v1, TIME):
```
Linear: penalty increases uniformly across all backing levels
- 100% backing → 0% penalty
- 90% backing → 14.3% penalty
- 80% backing → 28.6% penalty
- 70% backing → 42.9% penalty
- 60% backing → 57.1% penalty
- 50% backing → 71.4% penalty

Issues:
✗ Too aggressive at healthy levels (90-95% backing)
✗ Kills trading volume when protocol is still strong
✗ Not aggressive enough during real crisis (60-70% backing)
✗ Death spirals happen in the 60-80% range
```

**EchoForge's Exponential Curve**:
```
Exponential: penalty grows slowly when healthy, aggressively when in crisis
- 120% backing → 0.0% penalty   (FREE EXIT - very healthy protocol)
- 110% backing → 1.5% penalty   (minimal friction)
- 100% backing → 6.1% penalty   (reasonable protection)
- 95% backing → 9.6% penalty    (moderate protection)
- 90% backing → 13.8% penalty   (increasing protection)
- 80% backing → 24.5% penalty   (warning zone)
- 70% backing → 38.3% penalty   (crisis protection kicks in)
- 60% backing → 55.1% penalty   (severe crisis)
- 50% backing → 75.0% penalty   (maximum protection)

Benefits:
✓ Always-present penalty ensures protocol health
✓ Minimal friction when very healthy (120%+ = 0% penalty)
✓ Reasonable protection at standard backing (100% = 6.1%)
✓ Exponentially increases protection during actual crisis
✓ Prevents death spirals in the critical 60-80% zone
✓ Superior game theory - users can exit when protocol is strong
```

### Complete Penalty Curve Data

| Backing Ratio | Penalty | Distance from 100% | Penalty Formula |
|---------------|---------|-------------------|-----------------|
| ≥100% | 0.0% | 0% | Free exit zone |
| 99% | 0.038% | 1% | (1/50)² × 75% |
| 98% | 0.15% | 2% | (2/50)² × 75% |
| 97% | 0.34% | 3% | (3/50)² × 75% |
| 96% | 0.60% | 4% | (4/50)² × 75% |
| 95% | 0.94% | 5% | (5/50)² × 75% |
| 94% | 1.35% | 6% | (6/50)² × 75% |
| 93% | 1.84% | 7% | (7/50)² × 75% |
| 92% | 2.40% | 8% | (8/50)² × 75% |
| 91% | 3.04% | 9% | (9/50)² × 75% |
| 90% | 3.75% | 10% | (10/50)² × 75% |
| 85% | 8.44% | 15% | (15/50)² × 75% |
| 80% | 15.0% | 20% | (20/50)² × 75% |
| 75% | 23.4% | 25% | (25/50)² × 75% |
| 70% | 33.8% | 30% | (30/50)² × 75% |
| 65% | 45.9% | 35% | (35/50)² × 75% |
| 60% | 60.0% | 40% | (40/50)² × 75% |
| 55% | 75.9% | 45% | (45/50)² × 75% |
| 50% | 93.8% | 50% | (50/50)² × 75% |
| <50% | 75.0% | >50% | Maximum cap |

**Note**: The exponential formula can technically exceed 75%, so we cap it at 75% maximum.

### Penalty Distribution

When user unstakes and pays penalty:

```
totalPenalty = unstakeAmount × penalty(β)

burnAmount = totalPenalty × 50%
treasuryAmount = totalPenalty × 50%

userReceives = unstakeAmount - totalPenalty
```

**Examples**:

**Example 1: Healthy Protocol (95% backing)**
```
User unstakes 10,000 ECHO when β = 95%

penalty(95%) = 75% × ((100% - 95%) / 50%)² = 75% × (5/50)² = 75% × 0.01 = 0.75%
totalPenalty = 10,000 × 0.0075 = 75 ECHO

burnAmount = 75 × 0.5 = 37.5 ECHO (removed from supply)
treasuryAmount = 75 × 0.5 = 37.5 ECHO (added to treasury)

userReceives = 10,000 - 75 = 9,925 ECHO

Effect: Minimal friction, encourages trading volume when healthy
```

**Example 2: Warning Zone (80% backing)**
```
User unstakes 10,000 ECHO when β = 80%

penalty(80%) = 75% × ((100% - 80%) / 50%)² = 75% × (20/50)² = 75% × 0.16 = 12%
totalPenalty = 10,000 × 0.12 = 1,200 ECHO

burnAmount = 1,200 × 0.5 = 600 ECHO (removed from supply)
treasuryAmount = 1,200 × 0.5 = 600 ECHO (added to treasury)

userReceives = 10,000 - 1,200 = 8,800 ECHO

Effect: Moderate penalty, signals caution but still allows exits
```

**Example 3: Crisis Mode (70% backing)**
```
User unstakes 10,000 ECHO when β = 70%

penalty(70%) = 75% × ((100% - 70%) / 50%)² = 75% × (30/50)² = 75% × 0.36 = 27%
totalPenalty = 10,000 × 0.27 = 2,700 ECHO

burnAmount = 2,700 × 0.5 = 1,350 ECHO (removed from supply)
treasuryAmount = 2,700 × 0.5 = 1,350 ECHO (added to treasury)

userReceives = 10,000 - 2,700 = 7,300 ECHO

Effect on backing:
  ECHO supply decreases by 1,350 (burned)
  Treasury value increases by 1,350 ECHO
  Result: Backing ratio improves significantly
```

**Example 4: Severe Crisis (60% backing)**
```
User unstakes 10,000 ECHO when β = 60%

penalty(60%) = 75% × ((100% - 60%) / 50%)² = 75% × (40/50)² = 75% × 0.64 = 48%
totalPenalty = 10,000 × 0.48 = 4,800 ECHO

burnAmount = 4,800 × 0.5 = 2,400 ECHO (removed from supply)
treasuryAmount = 4,800 × 0.5 = 2,400 ECHO (added to treasury)

userReceives = 10,000 - 4,800 = 5,200 ECHO

Effect: Severe penalty protects protocol during deep crisis
```

---

## Redemption Queue Length

### Formula

Queue waiting time scales from 0 to 10 days based on backing ratio.

```
queueDays(β) = {
    0 days,                       if β ≥ 100%
    10 days,                      if β ≤ 50%
    10 × (100% - β) / 50%,        if 50% < β < 100%
}
```

**Continuous Formula**:
```
queueDays(β) = 10 × max(0, min(1, (1.00 - β) / 0.50))

Simplified: (10000 - backing) / 500

Examples:
  β = 100% → 0 days (instant unstaking when healthy)
  β = 95%  → 10 × (100% - 95%) / 50% = 1 day
  β = 90%  → 10 × (100% - 90%) / 50% = 2 days
  β = 80%  → 10 × (100% - 80%) / 50% = 4 days
  β = 70%  → 10 × (100% - 70%) / 50% = 6 days
  β = 60%  → 10 × (100% - 60%) / 50% = 8 days
  β = 50%  → 10 days (maximum)
  β < 50%  → 10 days (capped)
```

### Queue Position Calculation

```
availableTime = requestTime + (queueDays(β) × 86400)

canClaim = currentTime ≥ availableTime
```

**Example Timeline**:
```
Day 0: User requests unstake of 5,000 ECHO
  Backing ratio = 90%
  Queue length = 10 × (1.00 - 0.90) / 0.50 = 2 days
  Available time = Day 0 + 2 days

Day 1: User tries to claim
  currentTime < availableTime
  Result: Cannot claim yet (1 day remaining)

Day 2: User tries to claim
  currentTime ≥ availableTime
  Result: Can claim, subject to DUP penalty at current β
  Current penalty at 90% backing = 75% × ((100%-90%)/50%)² = 3%
```

---

## Time-Based Unlock Penalty

### Overview

When users lock tokens in tiers (30, 90, 180, or 365 days), they receive multiplier bonuses. If they choose to unlock early, they face a time-based penalty that decreases linearly based on time served.

### Formula

```
penalty(timeServed, totalDuration) = 90% - (80% × timeServed / totalDuration)
```

**Range**: 90% (at start) → 10% (at completion)

### Mathematical Expression

```
MAX_EARLY_UNLOCK_PENALTY = 9000 basis points (90%)
MIN_EARLY_UNLOCK_PENALTY = 1000 basis points (10%)

penaltyReduction = (8000 × timeServed) / totalDuration
penalty = MAX_EARLY_UNLOCK_PENALTY - penaltyReduction

Examples:
  0% time served   → penalty = 9000 - 0 = 9000 (90%)
  25% time served  → penalty = 9000 - 2000 = 7000 (70%)
  50% time served  → penalty = 9000 - 4000 = 5000 (50%)
  75% time served  → penalty = 9000 - 6000 = 3000 (30%)
  100% time served → penalty = 9000 - 8000 = 1000 (10%)
```

### Example Scenarios

**Scenario 1: 365-Day Lock, Early Exit After 100 Days**
```
Total duration: 365 days
Time served: 100 days
Time ratio: 100 / 365 = 27.4%

Penalty = 90% - (80% × 0.274) = 90% - 21.9% = 68.1%

User locked: 10,000 eECHO
Penalty amount: 10,000 × 0.681 = 6,810 eECHO
User receives: 10,000 - 6,810 = 3,190 eECHO

Penalty is burned, improving backing ratio
```

**Scenario 2: 90-Day Lock, Exit After 80 Days**
```
Total duration: 90 days
Time served: 80 days
Time ratio: 80 / 90 = 88.9%

Penalty = 90% - (80% × 0.889) = 90% - 71.1% = 18.9%

User locked: 5,000 eECHO
Penalty amount: 5,000 × 0.189 = 945 eECHO
User receives: 5,000 - 945 = 4,055 eECHO

Much smaller penalty since user served most of the duration
```

**Scenario 3: 180-Day Lock, Exit After 1 Day**
```
Total duration: 180 days
Time served: 1 day
Time ratio: 1 / 180 = 0.56%

Penalty = 90% - (80% × 0.0056) = 90% - 0.44% = 89.6%

User locked: 8,000 eECHO
Penalty amount: 8,000 × 0.896 = 7,168 eECHO
User receives: 8,000 - 7,168 = 832 eECHO

Severe penalty for immediate exit
```

### Key Properties

1. **Linear Decrease**: Penalty reduces smoothly over time, no sudden jumps
2. **Fair**: Rewards users who serve significant portions of lock period
3. **Punitive Early**: Discourages immediate unlocks (near 90% penalty)
4. **Never Zero**: Minimum 10% penalty even at completion to encourage natural expiry
5. **Deflationary**: All penalties are burned, improving backing ratio

---

## Adaptive Transfer Tax with Auto-Swap

### Formula

Tax rate scales from 4% to 15% based on staking ratio.

```
taxRate(σ) = {
    4%,                          if σ ≥ 90%
    15%,                         if σ ≤ 0%
    4% + 11% × (90% - σ) / 90%,   if 0% < σ < 90%
}
```

**Mathematical Expression**:
```
taxRate(σ) = 4% + 11% × max(0, min(1, (0.90 - σ) / 0.90))

Examples:
  σ = 95%  → taxRate = 4%      (at or above target)
  σ = 90%  → taxRate = 4%      (at target)
  σ = 80%  → taxRate = 5%
  σ = 70%  → taxRate = 6.25%
  σ = 50%  → taxRate = 8.75%
  σ = 20%  → taxRate = 12.5%
  σ = 0%   → taxRate = 15%     (maximum)
```

### Tax Distribution with Auto-Swap

```
taxAmount = transferAmount × taxRate(σ)

On All Transfers (auto-swap when threshold met, >1000 ECHO accumulated):
  echoToTreasury = taxAmount × 50%
  echoToSwap = taxAmount × 50%
  ethFromSwap = swap(echoToSwap) via DEX
  Treasury receives: echoToTreasury + ethFromSwap

recipientReceives = transferAmount - taxAmount
```

**Auto-Swap Mechanism**:
```
if (accumulatedTax ≥ 1000 ECHO) {
    echoToKeep = accumulatedTax × 50%
    echoToSwap = accumulatedTax × 50%

    // Swap via DEX router
    ethReceived = dexRouter.swapExactTokensForETH(
        echoToSwap,
        minETHOut,
        path: [ECHO, WETH],
        to: treasury
    )

    // Send ECHO portion to treasury
    ECHO.transfer(treasury, echoToKeep)

    // ETH already sent to treasury via swap
}
```

**Example - Transfer**:
```
Transfer 1000 ECHO when σ = 70%

taxRate(70%) = 6.25%
taxAmount = 1000 × 0.0625 = 62.5 ECHO

If swap threshold met (>1000 ECHO accumulated):
  echoToTreasury = 62.5 × 0.5 = 31.25 ECHO
  echoToSwap = 62.5 × 0.5 = 31.25 ECHO
  ethFromSwap = ~0.031 ETH (assuming 1 ECHO = $1, ETH = $1000)

Treasury receives: 31.25 ECHO + 0.031 ETH

recipientReceives = 1000 - 62.5 = 937.5 ECHO

Effect:
  - Treasury gains diversified assets (ECHO + ETH)
  - Improved backing ratio from ETH
  - Reduced ECHO sell pressure (31.25 swapped to ETH instead of circulating)
  - Lower circulation → incentivizes staking → σ increases → tax decreases
```

---

## Treasury Buyback Engine

### Trigger Condition

```
buybackActivates = (p < buybackFloor × p̄) AND (β > 100%) AND (liquidAssets > minLiquidity)

where:
  buybackFloor = 75%
  p = current ECHO price
  p̄ = 30-day TWAP
```

**Example**:
```
TWAP (p̄) = 0.001 ETH
Current price (p) = 0.0007 ETH
Backing ratio (β) = 120%
Liquid treasury = $500,000

Check conditions:
  1. p < 0.75 × p̄?
     0.0007 < 0.75 × 0.001
     0.0007 < 0.00075
     ✅ TRUE

  2. β > 100%?
     120% > 100%
     ✅ TRUE

  3. liquidAssets > minLiquidity?
     $500k > $100k
     ✅ TRUE

Result: BUYBACK ACTIVATES
```

### Buyback Amount Calculation

```
maxBuyback = min(
    targetAmount,
    liquidAssets × maxBuybackPercent,
    maxBuybackPerRebase
)

where:
  targetAmount = (p̄ - p) / p × circulatingSupply × 0.1  // Buy 10% of gap
  maxBuybackPercent = 5%  // Max 5% of liquid assets per buyback
  maxBuybackPerRebase = 10,000 ECHO
```

**Example**:
```
TWAP = 0.001 ETH
Current price = 0.0007 ETH
Price gap = 30%
Circulating supply = 1,000,000 ECHO
Liquid treasury = $500,000
ECHO price in USD = $1.40

Target to buy 10% of gap:
  targetAmount = 1,000,000 × 0.30 × 0.10 = 30,000 ECHO

Max from treasury (5% of liquid):
  maxFromTreasury = $500,000 × 0.05 = $25,000
  In ECHO = $25,000 / $1.40 = 17,857 ECHO

Max per rebase: 10,000 ECHO

finalBuyback = min(30,000, 17,857, 10,000) = 10,000 ECHO

Treasury spends: 10,000 × $1.40 = $14,000
Buys and burns: 10,000 ECHO
```

### Price Impact on Backing

Buybacks affect backing ratio through two mechanisms: reducing treasury value and reducing circulating supply.

**Key Formula**:
```
Backing ratio (β) = Treasury Value / Market Cap
Market Cap = Circulating Supply × Current Price
```

**Example Scenario**:
```
Initial state:
  Price dropped to $0.90 (from $1.20 TWAP)
  Treasury value: $1,200,000
  Supply: 1,000,000 ECHO
  Market cap: 1,000,000 × $0.90 = $900,000
  Backing ratio: $1,200,000 / $900,000 = 133%

Buyback execution:
  Treasury spends: $14,000
  Buys at market price $0.90: 15,556 ECHO
  Burns purchased tokens: 15,556 ECHO

After buyback:
  Treasury value: $1,200,000 - $14,000 = $1,186,000 (-1.17%)
  Supply: 1,000,000 - 15,556 = 984,444 ECHO (-1.56%)
  Price: $0.90 × 1.0156 = $0.914 (+1.56% from scarcity)
  Market cap: 984,444 × $0.914 = $899,782 (-0.02%)
  New backing ratio: $1,186,000 / $899,782 = 131.8%
```

**Impact Analysis**:
- Treasury decreased: 1.17%
- Market cap decreased: 0.02%
- Backing ratio decreased: from 133% to 131.8% (-1.2 percentage points)

The buyback's primary goals are:
1. ✓ Support price floor (prevented further decline)
2. ✓ Reduce circulating supply (deflationary pressure)
3. ✓ Signal protocol strength (defensive action)
4. ✓ Prepare for recovery (less supply to overcome)

---

## Lock Tier Multipliers

### Tier Structure

| Tier | Lock Duration | Multiplier | Early Unlock Penalty |
|------|--------------|------------|---------------------|
| 0 | No lock | 1.0× | N/A |
| 1 | 30 days | 1.2× | Time-based (90% → 10%) |
| 2 | 90 days | 2.0× | Time-based (90% → 10%) |
| 3 | 180 days | 3.0× | Time-based (90% → 10%) |
| 4 | 365 days | 4.0× | Time-based (90% → 10%) |

### Reward Calculation

```
baseReward = rebaseAmount × userStake / totalStaked

lockedReward = baseReward × lockMultiplier(tier)

Examples:
  User has 10,000 eECHO locked in Tier 4 (365 days, 4× multiplier)
  Rebase distributes 1% growth
  Total staked = 500,000 eECHO

  baseReward = 0.01 × 10,000 = 100 eECHO
  lockedReward = 100 × 4.0 = 400 eECHO

  User receives 4× the rewards of unlocked stakers
```

### Early Unlock Penalty

Early unlock penalties are now time-based, decreasing linearly from 90% to 10% as the user serves their lock duration. See [Time-Based Unlock Penalty](#time-based-unlock-penalty) for detailed mathematics.

```
Quick reference:
  penalty(timeServed, totalDuration) = 90% - (80% × timeServed / totalDuration)

Example:
  User locked 10,000 eECHO for 365 days
  After 100 days (27.4% of duration), user unlocks early

  penalty = 90% - (80% × 0.274) = 68.1%
  penaltyAmount = 10,000 × 0.681 = 6,810 eECHO (burned)
  userReceives = 3,190 eECHO

  Benefit to protocol: 6,810 ECHO burned (increases backing)
```

---

## Referral Bonus Distribution

### Overview

v2.0 simplifies the referral system by removing tier and lock multipliers. Referrers receive a simple percentage of the stake amount based on their level in the referral tree.

### Bonus Structure

The referral system distributes bonuses across 10 levels of the referral tree:

```
Level 1 (Direct):     4%
Level 2:              2%
Levels 3-10:          1% each (8 levels × 1% = 8%)

Total:                14% of stake amount
```

**Implementation** (from Referral.sol):
```solidity
uint256[10] public bonusRates = [400, 200, 100, 100, 100, 100, 100, 100, 100, 100];
// Base rates in basis points: 4%, 2%, 1%, 1%, 1%, 1%, 1%, 1%, 1%, 1%
```

### Distribution Formula

```
For each level i (1 to 10):
  bonusAmount[i] = stakeAmount × bonusRate[i] / 10000

  // Mint ECHO for referral bonus
  mint(bonusAmount[i])

  // Wrap to eECHO and transfer to referrer
  eEchoAmount = wrap(bonusAmount[i])
  transfer(referrer[i], eEchoAmount)
```

**Key Changes from v1.0**:
- No tier multipliers based on lifetime volume
- No lock multipliers based on referrer's lock status
- Simple, predictable percentage distribution
- No echo-back calculations

### Complete Example

**Scenario**:
```
Alice stakes 10,000 ECHO
Bob (L1) referred Alice
Carol (L2) referred Bob
Dave (L3) referred Carol
Eve (L4) referred Dave
```

**Calculation**:

**Level 1 - Bob**:
```
bonusAmount = 10,000 × 0.04 = 400 ECHO
Bob receives: 400 eECHO (wrapped from 400 ECHO)
```

**Level 2 - Carol**:
```
bonusAmount = 10,000 × 0.02 = 200 ECHO
Carol receives: 200 eECHO
```

**Level 3 - Dave**:
```
bonusAmount = 10,000 × 0.01 = 100 ECHO
Dave receives: 100 eECHO
```

**Level 4 - Eve**:
```
bonusAmount = 10,000 × 0.01 = 100 ECHO
Eve receives: 100 eECHO
```

**Total Bonuses**: 400 + 200 + 100 + 100 + ... = up to 1,400 ECHO (14% of stake)

### Example with Full Tree

```
Alice stakes 100,000 ECHO

If full 10-level referral tree exists:
  L1: 100,000 × 4% = 4,000 eECHO
  L2: 100,000 × 2% = 2,000 eECHO
  L3-L10: 100,000 × 1% × 8 = 8,000 eECHO

  Total distributed: 14,000 eECHO (14% of stake)

These are freshly minted, increasing total supply
Protocol benefits from network growth and stickiness
```

### Properties

1. **Simple**: No complex multiplier calculations
2. **Predictable**: Users know exactly what they'll earn
3. **Fair**: All referrers get same rate regardless of status
4. **Sustainable**: Fixed 14% maximum prevents runaway emissions
5. **Growth-Oriented**: Incentivizes building referral networks

---

## Bonding Curve Pricing

### Exponential Curve Formula

```
price(supply) = initialPrice × (1 + supply / maxSupply)²

where:
  initialPrice = 0.0001 ETH
  maxSupply = 10,000,000 ECHO
```

**Mathematical Expression**:
```
p(s) = 0.0001 × (1 + s / 10,000,000)²

Examples:
  s = 0        → p = 0.0001 × 1² = 0.0001 ETH
  s = 1,000,000 → p = 0.0001 × 1.1² = 0.000121 ETH
  s = 5,000,000 → p = 0.0001 × 1.5² = 0.000225 ETH
  s = 10,000,000 → p = 0.0001 × 2² = 0.0004 ETH
```

### Integral for Total Cost

To buy from supply s₁ to s₂:

```
cost = ∫[s₁ to s₂] p(s) ds
     = ∫[s₁ to s₂] 0.0001 × (1 + s/10,000,000)² ds

Let u = 1 + s/10,000,000, du = ds/10,000,000

cost = 0.0001 × 10,000,000 × ∫ u² du
     = 1000 × [u³/3] from u₁ to u₂
     = 1000/3 × (u₂³ - u₁³)

where:
  u₁ = 1 + s₁/10,000,000
  u₂ = 1 + s₂/10,000,000
```

**Example - Buy First 100,000 ECHO**:
```
s₁ = 0
s₂ = 100,000

u₁ = 1 + 0/10,000,000 = 1.0
u₂ = 1 + 100,000/10,000,000 = 1.01

cost = 1000/3 × (1.01³ - 1.0³)
     = 333.33 × (1.030301 - 1.0)
     = 333.33 × 0.030301
     = 10.10 ETH

Average price = 10.10 / 100,000 = 0.000101 ETH per ECHO
```

### Anti-Bot Protection

First 24 hours:
```
maxPurchasePerTx = 10,000 ECHO

If amount > maxPurchasePerTx:
  revert("Exceeds first day limit")
```

After 24 hours:
```
No limit on purchase size
```

---

## Appendix: Example Calculations

### Scenario A: Bull Market (High Backing)

```
Market conditions:
  ECHO price pumping
  Treasury value $2M
  ECHO market cap $1M
  Backing ratio: 200%
  Staking ratio: 95%

Mechanism responses:
  1. Dynamic APY: 18,000%
     Direct calculation from backing ratio
     Rebase rate: ~0.77% per 8 hours

  2. Unstake penalty: 0% (EXPONENTIAL - free to exit)
     100%+ backing = 0% penalty (free exit philosophy)
     Clean exits encourage volume when healthy

  3. Queue length: 0 days
     Instant unstaking when protocol is healthy (≥100% backing)

  4. Transfer tax: 4% (minimum)
     Low friction for healthy market activity

  5. Buyback: INACTIVE (price above floor)
     No need for support at high backing

User experience:
  ✅ Massive 18,000% APY (directly from backing)
  ✅ Can unstake freely with ZERO penalty (exponential curve benefit)
  ✅ No queue (instant unstaking)
  ✅ Low transfer costs
  ✅ System rewards strong treasury position
  ✅ High volume encouraged - not killed by penalties
```

### Scenario B: Bear Market (Low Backing)

```
Market conditions:
  ECHO price dropping
  Treasury value $800K
  ECHO market cap $1M
  Backing ratio: 80%
  Staking ratio: 75%

Mechanism responses:
  1. Dynamic APY: 2,500%
     APY responds directly to backing drop
     Still attractive but significantly reduced

  2. Unstake penalty: 12% (EXPONENTIAL)
     penalty = 75% × ((100% - 80%) / 50%)²
     penalty = 75% × (20/50)² = 75% × 0.16 = 12%
     Much lower than linear curve (would be ~29%)
     Still allows exits but discourages panic selling

  3. Queue length: 4 days
     Moderate wait during stress
     queue = 10 × (100% - 80%) / 50% = 4 days

  4. Transfer tax: 5.83%
     Moderately expensive selling

  5. Buyback: ACTIVE if price < 75% TWAP
     Treasury buying back and burning ECHO

User experience:
  ⚠️ Reduced APY (2,500% vs 5,000% at 100% backing)
  ⚠️ 12% penalty for unstaking (but better than linear 29%)
  ⚠️ 4 day queue to exit
  ✅ Still 2,500% APY - attractive for new capital
  ✅ Exponential curve allows strategic exits
  ✅ Multiple mechanisms actively defending protocol
```

### Scenario C: Death Spiral Attempt (Critical Backing)

```
Market conditions:
  Major FUD, coordinated dump attempt
  Treasury value $500K
  ECHO market cap $1M
  Backing ratio: 50%
  Staking ratio: 60%

Mechanism responses:
  1. Dynamic APY: 0%
     Emergency stop - no emissions below 50% backing

  2. Unstake penalty: 75% (EXPONENTIAL MAX)
     penalty = 75% × ((100% - 50%) / 50%)² = 75% × 1.0 = 75%
     Exponential curve hits maximum at 50% backing
     Users only get 25% of their stake back
     Compare to linear: would also be 75% at this level

     At 60% backing: 48% penalty (exponential) vs 57% (linear)
     At 70% backing: 27% penalty (exponential) vs 43% (linear)
     Exponential provides graduated protection

  3. Queue length: 10 days (maximum)
     All unstakes delayed
     queue = 10 × (100% - 50%) / 50% = 10 days

  4. Transfer tax: 15% (maximum)
     Selling costs 15%

  5. Buyback: ACTIVE (aggressive)
     Treasury using all available liquidity to buy

  6. Insurance vault: ACTIVATABLE
     Emergency funds can be deployed

  7. Time-based unlock: Still applies
     Locked users face 90% → 10% penalties based on time served

Coordinated attack:
  Whales try to unstake 100,000 ECHO

  Immediate barriers:
    1. 75% penalty = 75,000 ECHO lost
    2. 10-day wait period
    3. 37,500 ECHO to treasury
    4. 37,500 ECHO burned (increases backing)

  After penalties:
    ECHO supply: 1M - 37.5K burned = 962.5K
    Treasury: $500K + 37.5K ECHO value
    New backing ratio: significantly improved

  During 10-day queue:
    - Zero emissions (0% APY)
    - Buyback buying cheap ECHO
    - Community has time to rally
    - FUD likely to fade

  Result:
    ❌ Death spiral PREVENTED
    ✅ Protocol survived
    ✅ Backing ratio improved from penalties
    ✅ Attackers lost 75%
    ✅ Treasury strengthened from penalty distribution
    ✅ Exponential curve allowed earlier strategic exits (60-80% range)
```

---

## Formula Quick Reference

| Mechanism | Formula | Range |
|-----------|---------|-------|
| Dynamic APY | Piecewise exponential (see section) | 0% - 30,000% |
| Unstake Penalty | `p(β) = 75% × ((100% - β) / 50%)²` | 0% - 75% (exponential) |
| Queue Length | `q(β) = 10 × (100% - β) / 50%` | 0 - 10 days |
| Early Unlock Penalty | `90% - (80% × timeServed / totalDuration)` | 10% - 90% |
| Transfer Tax | `t(σ) = 4% + 11% × (90% - σ) / 90%` | 4% - 15% |
| Buyback Trigger | `p < 75% × TWAP` | Boolean |
| Lock Multiplier | `m ∈ {1.0, 1.2, 2.0, 3.0, 4.0}` | Discrete |
| Referral Bonus | `b = stake × rate / 10000` | 4%, 2%, 1%×8 |
| Bonding Price | `p(s) = 0.0001 × (1 + s/1e7)²` | > 0.0001 ETH |

---

## Mathematical Properties

### Monotonicity

All penalty/reward functions are monotonic:
- ↑ Backing ratio → ↑ APY, ↓ Penalties, ↓ Queue time
- ↑ Staking ratio → ↓ Transfer tax
- ↑ Lock duration → ↑ Multipliers
- ↑ Time served → ↓ Early unlock penalty

### Continuity

All functions are continuous or piecewise continuous:
- Smooth transitions between states within ranges
- No sudden jumps (except at discrete tier boundaries)
- Predictable behavior for users
- Dynamic APY uses piecewise function with smooth segments

### Boundedness

All values have hard caps:
- APY ∈ [0%, 30,000%]
- Unstake penalty ≤ 75%
- Early unlock penalty ∈ [10%, 90%]
- Transfer tax ≤ 15%
- Queue ∈ [3, 10] days

### Self-Regulation

The v2.0 system creates natural equilibrium:
- High backing → High APY → Attracts capital → Potential backing dilution
- Low backing → Low APY → Slows emissions → Backing recovery
- System finds balance without manual intervention

### Symmetry

Key symmetric relationships:
- APY responds exponentially to backing (up and down)
- Penalties increase as backing decreases
- Tax punishes low staking, rewards high staking
- Time-based penalties reward patience

---

**Document Version**: 2.0
**Last Updated**: 2025-11-19
**Complexity Level**: Advanced
**Audit Status**: v2.0 updates pending external review

**Major Changes in v2.0**:
- Replaced backing-linked dampener with direct dynamic APY calculation
- Updated redemption queue from 7-30 days to 0-10 days
- Introduced time-based unlock penalty (90% → 10%)
- Simplified referral bonuses (removed tier/lock multipliers)
- Removed NFT/node tier mechanics
- Updated DUP distribution (50% burn, 50% treasury instead of top-100)
- Removed excess emission burn mechanism

**Note**: All formulas have been verified against smart contract implementations. Any discrepancies should be reported to the development team.
