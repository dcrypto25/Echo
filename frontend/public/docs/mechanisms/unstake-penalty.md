# Dynamic Unstake Penalty (DUP)

The Dynamic Unstake Penalty is a critical defense mechanism that protects the treasury and prevents bank runs by imposing exponentially increasing penalties during periods of low backing.

## Overview

Unlike fixed unstake penalties that fail during stress, EchoForge's penalty scales with backing ratio using an exponential curve, creating a powerful incentive to maintain stakes during protocol stress while remaining negligible during healthy periods.

**Key Innovation**: Penalty severity automatically responds to treasury health, making mass unstaking economically prohibitive exactly when it would be most damaging to the protocol.

## Formula

The Dynamic Unstake Penalty uses an exponential curve based on backing ratio:

```
penalty(β) = 75% × ((120% - β) / 70%)²

Where:
- β = backing ratio (in percentage)
- Maximum penalty: 75% (at β ≤ 50%)
- Minimum penalty: 0% (at β ≥ 120%)
- Exponential growth as backing declines
```

### Precise Calculation

```solidity
function calculateUnstakePenalty(uint256 backingRatio) public pure returns (uint256) {
    // backingRatio in basis points (10000 = 100%)

    if (backingRatio >= 12000) {  // ≥120%
        return 0;  // No penalty
    }

    if (backingRatio <= 5000) {  // ≤50%
        return 7500;  // 75% maximum penalty
    }

    // Exponential curve between 50% and 120%
    // penalty = 0.75 × ((1.20 - β) / 0.70)²

    uint256 numerator = 12000 - backingRatio;  // (120% - β) in bp
    uint256 denominator = 7000;  // 70% in bp

    // Square the ratio
    uint256 ratio = (numerator * 10000) / denominator;
    uint256 ratioSquared = (ratio * ratio) / 10000;

    // Multiply by 75%
    uint256 penalty = (ratioSquared * 7500) / 10000;

    return penalty;  // Returns basis points (7500 = 75%)
}
```

## Penalty Distribution

When a penalty is applied, it is split 50/50:

```
Total penalty: X eECHO
├── 50% burned (deflationary)
└── 50% to treasury (restores backing)
```

**Example**:
```
Unstake 10,000 eECHO at 90% backing
Penalty: 13.8%

Penalty amount: 1,380 eECHO
├── 690 eECHO burned (reduces supply)
└── 690 eECHO to treasury (increases backing)

User receives: 8,620 eECHO
```

## Economic Rationale

### Exponential vs Linear

**Why Exponential Curve?**

Linear penalties fail to prevent bank runs:

```
Linear penalty (hypothetical):
100% backing → 0% penalty
90% backing → 10% penalty
80% backing → 20% penalty

Users see 20% penalty as acceptable cost to exit
Mass unstaking continues
Treasury depletes
Death spiral accelerates
```

**Exponential curve (actual)**:
```
120% backing → 0% penalty (free exit)
100% backing → 5.8% penalty (slight disincentive)
90% backing → 13.8% penalty (strong disincentive)
80% backing → 23.3% penalty (severe disincentive)
70% backing → 36.7% penalty (extreme disincentive)
60% backing → 54.3% penalty (prohibitive)
50% backing → 75% penalty (maximum)
```

The exponential growth creates a **psychological barrier** that becomes overwhelming as backing declines.

### Self-Stabilizing Feedback

The DUP creates a virtuous cycle during stress:

```
1. Backing drops to 85%
2. Penalty increases to 17.7%
3. Rational users delay unstaking
4. Less unstaking = slower backing decline
5. Penalty proceeds (50%) restore backing
6. Treasury recovers
7. Backing improves to 95%
8. Penalty decreases to 8.9%
9. More users willing to unstake at lower penalty
10. System finds equilibrium
```

### Preventing Bank Runs

During a bank run scenario:

```
Traditional model:
- Fixed 10% penalty
- Mass panic → everyone unstakes
- Each unstake pays 10% penalty
- Treasury grows temporarily from penalties
- But supply deflates faster than treasury grows
- Net: Backing ratio still declines
- Death spiral continues

EchoForge DUP model:
- Dynamic penalty starts at 13.8% (90% backing)
- First wave unstakes at 13.8%
- Backing drops to 85%
- Penalty increases to 17.7%
- Second wave sees 17.7% penalty and pauses
- Some wait, backing stabilizes
- Penalty proceeds rebuild treasury
- Backing improves, penalty decreases
- Controlled drain instead of bank run
```

## Penalty Scenarios

### Healthy Protocol (120%+ Backing)

**Conditions**:
- Backing ≥ 120%
- Penalty: 0%
- Queue: 1 day

**Example**:
```
Unstake: 10,000 eECHO
Penalty: 0 eECHO
Burned: 0 eECHO
To treasury: 0 eECHO
User receives: 10,000 ECHO (100%)

After 1 day queue, user claims full amount
```

**Economic Effect**: Free exit encourages unstaking, prevents overcollateralization

### Moderate Stress (90% Backing)

**Conditions**:
- Backing: 90%
- Penalty: 13.8%
- Queue: 6.4 days

**Example**:
```
Unstake: 10,000 eECHO
Penalty: 1,380 eECHO
Burned: 690 eECHO
To treasury: 690 eECHO
User receives: 8,620 ECHO (86.2%)

After 6.4 day queue, user claims reduced amount
```

**Economic Effect**: Significant disincentive, most users prefer to wait for backing improvement

### Severe Stress (70% Backing)

**Conditions**:
- Backing: 70%
- Penalty: 36.7%
- Queue: 7 days

**Example**:
```
Unstake: 10,000 eECHO
Penalty: 3,670 eECHO
Burned: 1,835 eECHO
To treasury: 1,835 eECHO
User receives: 6,330 ECHO (63.3%)

After 7 day queue, user claims heavily reduced amount
```

**Economic Effect**: Extremely prohibitive, nearly all users wait rather than accept 36.7% loss

### Crisis (50% Backing)

**Conditions**:
- Backing: 50%
- Penalty: 75% (maximum)
- Queue: 7 days

**Example**:
```
Unstake: 10,000 eECHO
Penalty: 7,500 eECHO
Burned: 3,750 eECHO
To treasury: 3,750 eECHO
User receives: 2,500 ECHO (25%)

After 7 day queue, user claims only 25%
```

**Economic Effect**: Catastrophic loss for unstakers, complete halt to voluntary unstaking

## Integration with Queue System

The DUP works in conjunction with the redemption queue to create a two-layer defense:

### Queue Length Formula

```
queueDays = (12000 - backingBasisPoints) / 500

Range: 1-7 days
```

**Examples**:
- 120% backing: (12000 - 12000) / 500 = 0 → 1 day minimum
- 100% backing: (12000 - 10000) / 500 = 4 days
- 80% backing: (12000 - 8000) / 500 = 8 → 7 day maximum
- 50% backing: (12000 - 5000) / 500 = 14 → 7 day maximum

### Combined Effect

```
User Decision Matrix:

At 120% backing:
- Penalty: 0%
- Queue: 1 day
- Decision: Easy exit, no cost

At 100% backing:
- Penalty: 5.8%
- Queue: 4 days
- Decision: Moderate cost, wait a few days

At 85% backing:
- Penalty: 17.7%
- Queue: 6 days
- Decision: High cost + long wait = strong disincentive

At 70% backing:
- Penalty: 36.7%
- Queue: 7 days
- Decision: Extreme cost + max wait = stay staked
```

The combination creates a **graduated resistance** to unstaking.

## Treasury Impact

### Penalty Proceeds

The 50% treasury portion directly restores backing:

```
Scenario: 90% backing, $900k treasury, $1M market cap

User unstakes $100k worth (10,000 eECHO)
Penalty: 13.8% = $13,800
To treasury: $6,900 (50%)

New treasury: $906,900
New market cap: $986,200 (after 6,900 burn)
New backing: 91.9%

Result: Backing improved by unstake!
```

### Burn Deflation

The 50% burn reduces supply:

```
Initial supply: 1,000,000 ECHO
eECHO staked: 900,000

User unstakes: 10,000 eECHO
Penalty burn: 690 eECHO converted to ECHO and burned

New supply: 999,310 ECHO
Remaining staked: 889,310 eECHO

Supply deflation: 0.069%
```

Combined with price stability, this improves backing ratio.

### Self-Healing Mechanism

Large unstakes actually improve backing when penalty is high:

```
At 80% backing (23.3% penalty):

Unstake $1M worth (100,000 eECHO)
Penalty: $233,000
├── Burn: $116,500 (supply deflation)
└── Treasury: $116,500 (backing increase)

Treasury increases by $116,500
Supply deflates by 116,500 tokens

If price holds:
New market cap: $883,500 (reduced supply)
New treasury: $716,500 (increased from penalty)
New backing: 81.1%

Backing improved despite large unstake!
```

## User Strategies

### Optimal Timing

Users can minimize penalty by timing unstakes:

**Strategy 1: Wait for High Backing**
```
Current: 85% backing, 17.7% penalty
Wait for backing to recover to 110%
New penalty: 1.3%

Savings: 16.4% by waiting
```

**Strategy 2: Partial Unstaking**
```
Instead of unstaking 100% at once:

Option A: Unstake 100,000 eECHO at 90% backing
- Penalty: 13,800 eECHO
- Receive: 86,200 ECHO

Option B: Unstake 25,000 eECHO four times as backing recovers
- First 25k at 90%: penalty 3,450, receive 21,550
- Wait for backing recovery...
- Second 25k at 95%: penalty 2,225, receive 22,775
- Third 25k at 100%: penalty 1,450, receive 23,550
- Fourth 25k at 105%: penalty 725, receive 24,275
- Total received: 92,150 ECHO

Savings: 5,950 ECHO by being patient
```

### Penalty Avoidance

Users seeking to avoid penalties have alternatives:

**1. Sell eECHO on DEX**
```
Instead of unstaking:
- List eECHO for sale on Uniswap
- Accept market discount (e.g., 5% below ECHO)
- Avoid unstake penalty (e.g., 13.8%)
- Net benefit: 8.8%

This creates arbitrage opportunity for buyers
```

**2. Use eECHO as Collateral**
```
Instead of unstaking for liquidity:
- Deposit eECHO in lending protocol
- Borrow against eECHO collateral
- Maintain exposure to rebases
- Avoid penalty entirely
```

**3. Wait Out Queue**
```
If backing trending upward:
- Request unstake at 90% (13.8% penalty)
- During 6-day queue, backing recovers to 100%
- Penalty recalculated at claim: 5.8%
- Savings: 8% by queue timing
```

Note: Penalty is calculated at REQUEST time, not claim time (this prevents gaming).

## Risk Considerations

### Penalty Lock-In

Once requested, penalty is locked:

```
User requests unstake: 10,000 eECHO at 90% backing
Penalty locked at request: 13.8%

During queue, backing drops to 80%
New penalty would be: 23.3%

User still only pays: 13.8% (locked at request)

This protects users from penalty increases during queue
```

### Maximum Loss Scenario

Worst-case unstake:

```
Unstake during crisis: β = 50%
Penalty: 75%
User keeps only: 25%

This is catastrophic but intentional
It prevents unstaking during crisis
Forces users to hold through recovery
Protects protocol survival
```

### Locked eECHO Penalties

Locked tokens have additional early unlock penalty:

```
User has 10,000 eECHO locked for 365 days
Served 100 days (27.4%)

Early unlock penalty: 90% - (80% × 27.4%) = 68.1%

If also unstaking at 90% backing:
- Early unlock penalty: 68.1%
- Unstake penalty: 13.8%
- Both applied sequentially!

After early unlock: 10,000 × (1 - 0.681) = 3,190 eECHO
After unstake penalty: 3,190 × (1 - 0.138) = 2,750 ECHO

Total loss: 72.5%

Strong incentive to honor lock commitment
```

## Comparison to Other Protocols

### Fixed Penalty Models

**Uniswap V2 LP Tokens**:
- No unstake penalty
- Result: Free exit creates no protection against runs

**Traditional Staking**:
- Fixed unbonding period (7-21 days)
- No economic penalty
- Result: Minimal disincentive to unstake during crisis

### Adaptive Models

**EchoForge DUP**:
- Exponentially scaled penalty
- Scales with threat level (low backing)
- Heavy penalty exactly when needed
- Result: Mathematically prevents bank runs

**Olympus V2 (post-collapse)**:
- Introduced fixed 10% penalty
- Better than nothing
- Still failed to prevent selling during stress
- Result: Not sufficient

## Monitoring

### Key Metrics

Users should track:

**Current Penalty**:
```
Dashboard display:
"Current Unstake Penalty: 13.8%"
"If you unstake 10,000 eECHO now, you will receive ~8,620 ECHO"
```

**Penalty Trend**:
```
24h ago: 17.2%
12h ago: 15.4%
Now: 13.8%
Trend: Improving (backing recovering)
```

**Break-Even Analysis**:
```
Unstake now: 13.8% penalty = 8,620 ECHO
vs.
Wait for 110% backing: 1.3% penalty = 9,870 ECHO
Benefit of waiting: 1,250 ECHO (14.5% improvement)

But factor in opportunity cost of 6-day queue...
```

## Advanced Topics

### Penalty vs APY Trade-Off

Users must weigh penalty against continuing to earn:

```
Current APY: 5,000%
Current penalty: 13.8%
Queue: 6 days

If unstake now:
- Pay 13.8% penalty
- Receive 86.2% immediately (after 6-day queue)

If stay staked:
- Earn 5,000% APY ≈ 0.37% per 8h rebase
- Over 6 days: 9 rebases ≈ 3.3% growth
- Net: 103.3% after 6 days

Decision: Staying 6 more days recovers penalty cost!

Break-even: penalty / daily_APY = 13.8% / 0.37% ≈ 37 days

If backing recovers in <37 days, better to wait
```

### Penalty as Insurance

The DUP acts as insurance premium for protocol stability:

```
Users who unstake during stress:
- Pay high premiums (penalties)
- Get immediate exit (after queue)
- Protect their capital

Users who stay during stress:
- Avoid premiums (no penalty)
- Continue earning (rebases)
- Benefit from penalty proceeds (backing improvement)
- Higher risk, higher reward

This creates balanced incentives
```

---

**Last updated**: November 2025
**Related**: [Dynamic APY](./dynamic-apy.md) | [Treasury Backing](./treasury-backing.md)
