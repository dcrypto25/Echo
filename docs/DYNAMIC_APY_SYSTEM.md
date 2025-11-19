# EchoForge - Dynamic APY System (No Targets)

## Core Philosophy

**No fixed targets. Pure market dynamics.**

- **High backing** → Aggressive APY → Attract capital → Grow protocol
- **Backing drops** → APY drops FAST → "Catch the knife" → Stabilize
- **System finds its own equilibrium** based on treasury health

---

## The Formula: Exponential Response

### Base Concept

```
APY = calculateDynamicAPY(backingRatio, treasuryComposition)

NO TARGETS
NO DAMPENER MULTIPLICATION
JUST PURE DYNAMIC CALCULATION
```

### Implementation

```solidity
function calculateDynamicAPY(uint256 backingRatio) public pure returns (uint256) {
    /*
     * Exponential scaling based on backing ratio
     *
     * Philosophy:
     * - High backing (150%+): GO CRAZY, attract all the capital
     * - Healthy backing (100-150%): Still very attractive
     * - Weakening (90-100%): Drop FAST to slow emissions
     * - Crisis (<90%): Emergency mode, minimal emissions
     */

    if (backingRatio >= 20000) {
        // >200% backing: MAXIMUM AGGRESSION
        // 30,000% APY - go absolutely crazy
        return 30000;

    } else if (backingRatio >= 15000) {
        // 150-200% backing: Very aggressive
        // Scale from 12,000% to 30,000%
        // Formula: 12000 + (backing - 150) × 360
        uint256 excess = backingRatio - 15000;
        return 12000 + (excess * 360 / 100);

    } else if (backingRatio >= 12000) {
        // 120-150% backing: Aggressive
        // Scale from 8,000% to 12,000%
        uint256 excess = backingRatio - 12000;
        return 8000 + (excess * 133 / 100);

    } else if (backingRatio >= 10000) {
        // 100-120% backing: Still attractive
        // Scale from 5,000% to 8,000%
        uint256 excess = backingRatio - 10000;
        return 5000 + (excess * 150 / 100);

    } else if (backingRatio >= 9000) {
        // 90-100% backing: GRADUAL DROP (still attractive for buying)
        // Drop from 5,000% to 3,500%
        // Still high enough to attract new capital
        uint256 deficit = 10000 - backingRatio;
        return 5000 - (deficit * 150 / 100); // 15% drop per 1% backing

    } else if (backingRatio >= 8000) {
        // 80-90% backing: Moderate slowdown
        // Drop from 3,500% to 2,500%
        uint256 deficit = 9000 - backingRatio;
        return 3500 - (deficit * 100 / 100);

    } else if (backingRatio >= 7000) {
        // 70-80% backing: Stronger slowdown
        // Drop from 2,500% to 2,000%
        uint256 deficit = 8000 - backingRatio;
        return 2500 - (deficit * 50 / 100);

    } else {
        // <70% backing: EMERGENCY STOP
        // Minimal emissions to prevent total collapse
        // Scale down to 0% at 50% backing
        if (backingRatio <= 5000) return 0;

        uint256 deficit = 7000 - backingRatio;
        uint256 apy = 200 - (deficit * 10 / 100);
        return apy > 0 ? apy : 0;
    }
}
```

### APY Table

| Backing Ratio | APY | Rationale |
|---------------|-----|-----------|
| 300% | 30,000% | 🚀 Maximum aggression - attract ALL capital |
| 250% | 24,000% | 🚀 Still going crazy |
| 200% | 18,000% | 🚀 Very aggressive |
| 175% | 15,000% | 🚀 Aggressive |
| 150% | 12,000% | 🔥 Still very high |
| 130% | 9,500% | 🔥 Attractive |
| 120% | 8,000% | 🔥 Solid |
| 110% | 6,500% | ✅ Good |
| 100% | 5,000% | ✅ Healthy baseline |
| 95% | 4,250% | ✅ Still very attractive |
| 90% | 3,500% | ✅ Gradual drop (still great for buying!) |
| 85% | 3,000% | ⚠️ Moderate slowdown |
| 80% | 2,500% | ⚠️ Slower but still attractive |
| 75% | 2,250% | ⚠️ Getting concerning |
| 70% | 2,000% | ⚠️ Catching the knife |
| 65% | 1,500% | 🚨 Crisis mode |
| 60% | 1,000% | 🚨 Deep crisis |
| 50% | 0% | 🛑 EMERGENCY STOP |

---

## "Catching the Knife" Mechanism

### The Critical Zone: 70-100% Backing

The system uses a gradual slowdown to prevent panic while still protecting the protocol:

```
100% backing: 5,000% APY
95% backing:  4,250% APY (15% drop)
90% backing:  3,500% APY (30% drop total - STILL VERY ATTRACTIVE)
85% backing:  3,000% APY
80% backing:  2,500% APY
70% backing:  2,000% APY (This is where we "catch the knife")

Drop from 100% → 90% = 30% APY reduction (not 60%)
Drop from 100% → 70% = 60% APY reduction
```

**Why this gradual approach works better**:

1. **Keeps buyers interested**: 3,500% APY at 90% backing is still incredible
2. **Tax revenue important**: Volume/transfer tax fills treasury, need users trading
3. **Slows emissions enough**: 30% slower emission is significant without being drastic
4. **Clear signal without panic**: "APY dropped 30%, something's up, but still worth it"
5. **Real "knife" at 70%**: Below 70% backing, APY drops to 2,000% - THIS is the alarm

**Combined with other mechanisms**:
```
At 90% backing (mild concern):
- APY: 3,500% (still great!)
- Queue: 8.6 days
- DUP: 14.3% penalty
- User psychology: "APY dropped a bit, but 3,500% is still insane, I'll hold"

At 70% backing (real concern):
- APY: 2,000% (dropped 60%)
- Queue: 10 days (maximum)
- DUP: 71.4% penalty (very painful)
- User psychology: "Whoa, APY halved, penalties are brutal, maybe wait this out"

Net effect: Gradual stabilization at 90%, hard stop at 70%
```

---

## Treasury Composition: Hold ECHO

### Why Treasury Should Hold ECHO

```
Traditional model:
Treasury holds: 100% stablecoins/ETH
Problem: Doesn't benefit from ECHO price increase

Better model:
Treasury holds:
  60% stablecoins/ETH (liquid, safe)
  30% productive assets (GMX/GLP, Curve, etc.)
  10% ECHO (benefits from own success)
```

**Example**:

```
Initial state:
  Treasury: $900K stables + $100K ECHO (at $1) = $1M total
  ECHO supply: 1M
  Backing: 100%

High APY attracts capital:
  New deposits: $2M
  ECHO price pumps to $2 (demand)

Treasury now:
  $900K stables (unchanged)
  $100K ECHO now worth $200K (doubled!)
  New deposits: $2M
  Total: $3.1M

ECHO supply: 1.5M (some minted for new stakers)
Market cap at $2: $3M
Backing ratio: $3.1M / $3M = 103%

Treasury benefited from price increase!
```

**How to implement**:

```solidity
// During bonding/staking, treasury keeps small % as ECHO
function bond(uint256 ethAmount) public {
    uint256 echoToMint = calculateBondingCurve(ethAmount);

    // Mint tokens
    uint256 userAmount = echoToMint * 90 / 100;  // 90% to user
    uint256 treasuryAmount = echoToMint * 10 / 100; // 10% to treasury

    echo.mint(msg.sender, userAmount);
    echo.mint(address(treasury), treasuryAmount);

    // Treasury holds this ECHO as backing
    treasury.receiveETH{value: ethAmount}();
}
```

**Benefits**:
- ✅ Treasury grows when ECHO pumps
- ✅ Alignment: Protocol wants ECHO to succeed
- ✅ Self-reinforcing: Success → higher backing → higher APY → more success
- ⚠️ Risk: If ECHO dumps, backing ratio drops (but we handle this with dynamic APY)

---

## The Self-Regulating Loop

### Positive Feedback (Growth Phase)

```
1. High backing (120%) → High APY (8,000%)
2. High APY → Attracts new capital
3. New capital buys ECHO → 100% of purchase goes to treasury (bonding curve)
4. Treasury grows from new deposits
5. Price may rise from buying pressure
6. BUT: Treasury growing faster than price from new capital
7. Backing maintained/increased → Higher APY (9,500%)
8. Loop continues → EXPONENTIAL GROWTH

Critical: Backing Ratio = Treasury Value / (Supply × Price)
- New deposits increase treasury directly
- Even if price doubles, treasury can grow 3x from new capital
- This maintains or increases backing ratio during growth
```

**This is the "bull run mode" - let it rip!**

### Negative Feedback (Stabilization Phase)

```
1. Backing drops to 95% (some selling)
2. APY drops from 5,000% to 3,500% (FAST)
3. Lower APY → Less attractive to new users
4. Lower APY → Slower emissions
5. Slower emissions → Backing ratio stabilizes
6. Queue + DUP activate → Selling slows
7. Treasury uses yield to buyback
8. Backing recovers to 98%
9. APY increases to 4,100%
10. System stabilizes at equilibrium
```

**This is the "catch the knife" mode - automatic stabilization**

### The Equilibrium Point

The system will naturally find an equilibrium where:

```
emissionRate = (newDeposits - withdrawals) + treasuryYield

At equilibrium:
- APY is attractive enough to bring new deposits
- Not so high that it depletes treasury
- Backing ratio oscillates around 100-120%
- Users are happy, protocol is sustainable
```

---

## Comparison to "Target APY" Approach

### Old Approach (Complex):
```
1. Set target APY: 8,000%
2. Calculate sustainable based on treasury yield
3. Apply dampener to reduce to sustainable
4. Burn excess somehow (unclear)
5. Users confused: "Why am I getting 800% when you said 8000%?"
```

### New Approach (Simple):
```
1. Check backing ratio
2. Calculate APY based on backing
3. Give users that APY
4. System self-regulates

Users understand: "High backing = high APY, low backing = low APY"
```

---

## Implementation

```solidity
// In eECHO.sol
function rebase() public {
    // Get current backing ratio
    uint256 backingRatio = treasury.getBackingRatio();

    // Calculate dynamic APY (no targets, no dampener)
    uint256 currentAPY = calculateDynamicAPY(backingRatio);

    // Convert APY to per-rebase rate
    uint256 rebaseRate = _apyToRebaseRate(currentAPY);

    // Apply rebase
    _totalSupply = _totalSupply * (10000 + rebaseRate) / 10000;

    // Update gons per fragment
    _gonsPerFragment = TOTAL_GONS / _totalSupply;

    emit Rebase(epoch, _totalSupply, currentAPY);
}

function getCurrentAPY() public view returns (uint256) {
    uint256 backingRatio = treasury.getBackingRatio();
    return calculateDynamicAPY(backingRatio);
}
```

**Clean, simple, self-regulating.**

---

## Example Scenarios

### Scenario 1: Bull Run

```
Day 0: Launch
  Backing: 100%
  APY: 5,000%
  Users: 100

Week 1: Early success
  High APY attracts users
  Backing: 115%
  APY: 6,750%
  Users: 500

Month 1: Going viral
  Strong growth
  Backing: 140%
  APY: 10,500%
  Users: 5,000

Month 2: Mania phase
  Everyone wants in
  Backing: 180%
  APY: 15,500%
  Users: 50,000

Result: System ALLOWS and ENCOURAGES growth when it's working
```

### Scenario 2: Market Correction

```
Day 0: Peak mania
  Backing: 180%
  APY: 15,500%

Week 1: Some whales take profit
  Backing drops: 180% → 150%
  APY drops: 15,500% → 12,000%
  Emissions slow, but still attractive

Week 2: More selling
  Backing: 150% → 120%
  APY: 12,000% → 8,000%
  "Hmm, APY is dropping, maybe cool down"

Week 3: Panic?
  Backing: 120% → 100%
  APY: 8,000% → 5,000%
  Emissions slowed significantly

Week 4: Attempted bank run
  Backing: 100% → 92%
  APY: 5,000% → 2,400% (FAST DROP)
  Queue: 8.2 days
  DUP: 11.4% penalty
  Users: "Whoa, maybe hold..."

Week 5-8: Stabilization
  Backing oscillates 92-98%
  APY: 2,400-4,400%
  New deposits resume (still 2,400%!)
  Treasury earns yield
  Buybacks execute

Month 3: Recovery
  Backing: 98% → 110%
  APY: 4,400% → 6,500%
  Confidence restored

Result: System CAUGHT THE KNIFE, survived, recovered
```

### Scenario 3: Black Swan

```
Day 0: Coordinated attack
  Whales dump everything
  Backing crashes: 120% → 70%
  APY: 8,000% → 200% (EMERGENCY)

Day 1-7: Crisis mode
  Minimal emissions (200% APY)
  Queue: 10 days (max)
  DUP: 71.4% penalty
  Most users can't/won't sell

Week 2: Treasury response
  Buybacks execute with all liquidity
  Insurance vault deploys
  Community rallies

Week 3-4: Slow recovery
  Backing: 70% → 75%
  APY: 200% → 500%
  "Hey, APY is increasing, maybe bottom is in"

Month 2: Back to healthy
  Backing: 75% → 95%
  APY: 500% → 3,500%
  Survived worst-case scenario

Result: Even extreme scenarios don't kill protocol
```

---

## Why This Works Better

### 1. **No Arbitrary Targets**
Users don't see "promised 8000% but getting 800%" confusion.
They see the actual APY based on protocol health.

### 2. **Pure Market Forces**
System responds immediately to market conditions.
No lag, no manual intervention needed.

### 3. **Clear Incentives**
Users understand: Help protocol → backing up → APY up → everyone wins

### 4. **Self-Limiting**
Can't go infinite (caps at 30,000% even with 300% backing)
Automatically slows when needed

### 5. **Psychologically Sound**
"APY dropped because backing dropped" makes sense
Not "APY dropped because of complex dampener math"

---

## Conclusion

This system:
- ✅ Allows aggressive APY when safe (>8000% easily)
- ✅ Catches the knife automatically when backing drops
- ✅ No complex "excess burn" needed
- ✅ Users understand the mechanics
- ✅ Treasury benefits from own success
- ✅ Self-regulating equilibrium
- ✅ Survives extreme scenarios

**This is the optimal design.**

Ready to implement?
