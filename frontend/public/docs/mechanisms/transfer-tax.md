# Adaptive Transfer Tax

The Adaptive Transfer Tax is a dynamic fee on ECHO token transfers that automatically adjusts based on the staking ratio, funding the treasury while incentivizing long-term holding and staking.

## Overview

Unlike fixed transfer taxes that penalize all movement equally, EchoForge's tax rate scales from 4% (when staking is high) to 15% (when staking is low), creating automatic incentives to stake rather than trade.

**Key Innovation**: Tax rate responds to user behavior, creating a self-regulating system that encourages productive participation (staking) over speculative trading.

## Formula

```
taxRate = 4% + 11% × max(0, (90% - stakingRatio) / 90%)

Where:
stakingRatio = stakedSupply / totalSupply
```

### Breakdown

**Base Rate**: 4% (minimum)
- Applied when staking ≥90%
- Rewards high staking participation
- Still funds treasury even in ideal conditions

**Variable Component**: 0-11%
- Scales linearly from 90% staking (0%) to 0% staking (11%)
- Penalizes low staking
- Incentivizes moving tokens to staking

**Maximum Rate**: 15% (base 4% + max variable 11%)
- Applied when staking ≤0% (theoretical)
- Severe penalty for pure trading

### Implementation

```solidity
function _calculateTaxRate() internal view returns (uint256) {
    // Get staking ratio
    uint256 stakedSupply = eECHO.totalSupply();
    uint256 totalSupply = ECHO.totalSupply();
    uint256 stakingRatio = (stakedSupply * 10000) / totalSupply;  // In basis points

    // Base rate: 4%
    uint256 baseRate = 400;  // 400 basis points = 4%

    // Calculate variable component
    if (stakingRatio >= 9000) {  // ≥90%
        return baseRate;  // Only base 4%
    }

    // variable = 11% × (90% - stakingRatio) / 90%
    uint256 difference = 9000 - stakingRatio;  // In basis points
    uint256 variableRate = (difference * 1100) / 9000;  // Max 1100 bp = 11%

    return baseRate + variableRate;  // Total tax rate
}
```

## Tax Rate Examples

### High Staking (Healthy Protocol)

```
Staking ratio: 95%
stakingRatio = 9500 bp
difference = 9000 - 9500 = -500 (capped at 0)
variableRate = 0
taxRate = 4% + 0% = 4%
```

**Result**: Minimal tax when community is aligned (staking)

### Target Staking

```
Staking ratio: 90%
stakingRatio = 9000 bp
difference = 9000 - 9000 = 0
variableRate = 0
taxRate = 4% + 0% = 4%
```

**Result**: Target behavior = minimum tax

### Moderate Staking

```
Staking ratio: 70%
stakingRatio = 7000 bp
difference = 9000 - 7000 = 2000
variableRate = (2000 × 1100) / 9000 = 244 bp = 2.44%
taxRate = 4% + 2.44% = 6.44%
```

**Result**: Moderate penalty encourages more staking

### Low Staking (Stressed Protocol)

```
Staking ratio: 50%
stakingRatio = 5000 bp
difference = 9000 - 5000 = 4000
variableRate = (4000 × 1100) / 9000 = 489 bp = 4.89%
taxRate = 4% + 4.89% = 8.89%
```

**Result**: Higher penalty pushes users to stake

### Very Low Staking (Crisis)

```
Staking ratio: 20%
stakingRatio = 2000 bp
difference = 9000 - 2000 = 7000
variableRate = (7000 × 1100) / 9000 = 856 bp = 8.56%
taxRate = 4% + 8.56% = 12.56%
```

**Result**: Severe penalty makes trading expensive

### Minimal Staking (Extreme)

```
Staking ratio: 0%
stakingRatio = 0 bp
difference = 9000 - 0 = 9000
variableRate = (9000 × 1100) / 9000 = 1100 bp = 11%
taxRate = 4% + 11% = 15%
```

**Result**: Maximum penalty, almost prohibitive

## Tax Collection & Distribution

### Collection Mechanism

```solidity
function _transfer(address from, address to, uint256 amount) internal override {
    // Check if taxable
    if (_isTaxExempt(from) || _isTaxExempt(to)) {
        super._transfer(from, to, amount);
        return;
    }

    // Calculate tax
    uint256 taxRate = _calculateTaxRate();
    uint256 taxAmount = (amount * taxRate) / 10000;
    uint256 netAmount = amount - taxAmount;

    // Transfer net amount to recipient
    super._transfer(from, to, netAmount);

    // Transfer tax to tax collector
    super._transfer(from, address(taxCollector), taxAmount);

    // Accumulate for auto-swap
    taxCollector.accumulateTax(taxAmount);
}
```

### Auto-Swap System

Tax accumulates until threshold, then auto-swaps:

```solidity
function _accumulateTax(uint256 amount) internal {
    accumulatedTax += amount;

    // Check if threshold reached
    if (accumulatedTax >= AUTO_SWAP_THRESHOLD) {
        _executeAutoSwap();
    }
}

function _executeAutoSwap() internal {
    uint256 totalTax = accumulatedTax;
    uint256 halfTax = totalTax / 2;

    // Swap 50% for ETH
    uint256 ethReceived = _swapECHOForETH(halfTax);

    // Send to treasury
    treasury.deposit{value: ethReceived}();  // ETH
    ECHO.transfer(address(treasury), halfTax);  // ECHO

    // Reset accumulator
    accumulatedTax = 0;

    emit AutoSwap(halfTax, ethReceived);
}
```

**Distribution**:
```
Tax collected: 10,000 ECHO

Auto-swap executes:
├── 5,000 ECHO swapped for ETH (e.g., 2.5 ETH)
└── 5,000 ECHO sent directly

Treasury receives:
├── 2.5 ETH
└── 5,000 ECHO
```

### Tax Exemptions

**Exempt Addresses**:
```
- Staking contract (ECHO ↔ eECHO wrapping)
- Treasury (internal operations)
- Bonding contracts (minting to treasury)
- Liquidity pools (adding/removing liquidity)
- Referral contract (bonus distributions)
- Lock contract (lock/unlock operations)
```

**Why Exempt**: These are protocol operations, not speculative transfers.

## Economic Rationale

### Incentive Alignment

The adaptive tax creates aligned incentives:

**Scenario 1: High Staking**
```
Staking ratio: 92%
Tax rate: 4%

Users see:
- Low tax cost
- Community aligned
- Most supply staked
- Healthy protocol

Outcome: Positive reinforcement
```

**Scenario 2: Low Staking**
```
Staking ratio: 60%
Tax rate: 7.67%

Users see:
- Higher tax cost
- Trading expensive
- Staking becomes more attractive (avoid tax + earn APY)

Outcome: Incentive to stake rather than trade
```

**Scenario 3: Crisis Staking**
```
Staking ratio: 30%
Tax rate: 11.67%

Users see:
- Very high tax cost
- Nearly 12% cost to trade
- Staking is clearly superior

Outcome: Strong push toward staking
```

### Revenue Generation

Tax provides consistent treasury revenue:

```
Daily volume: $500,000
Average tax rate: 8%
Daily revenue: $40,000
Annual: $14.6M

Distribution (50/50 auto-swap):
- ETH to treasury: $20,000/day = $7.3M/year
- ECHO to treasury: $20,000/day = $7.3M/year
```

**Key**: Revenue independent of price action, based on activity.

### Comparison to Alternatives

**No Tax**:
```
Pros: No friction, pure free market
Cons: No treasury revenue, no staking incentive

Result: Likely low staking, high trading, weak treasury
```

**Fixed Tax (e.g., 5%)**:
```
Pros: Predictable, simple
Cons: Doesn't respond to protocol needs

Result: Same penalty whether staking is 95% or 50%
Missing optimization opportunity
```

**Adaptive Tax (EchoForge)**:
```
Pros: Self-regulating, optimal incentives
Cons: Slightly complex formula

Result: Tax low when protocol healthy, high when stressed
Automatic incentive correction
```

## Revenue Scenarios

### Launch Phase

```
Month 1:
- Total supply: 1,200,000 ECHO
- Staked: 1,080,000 (90%)
- Tax rate: 4%
- Daily volume: $100,000
- Daily revenue: $4,000
- Monthly: $120,000
```

### Growth Phase

```
Month 6:
- Total supply: 5,000,000 ECHO
- Staked: 4,000,000 (80%)
- Tax rate: 5.22%
- Daily volume: $300,000
- Daily revenue: $15,660
- Monthly: $469,800
```

### Maturity Phase

```
Month 12:
- Total supply: 20,000,000 ECHO
- Staked: 17,000,000 (85%)
- Tax rate: 4.61%
- Daily volume: $1,000,000
- Daily revenue: $46,100
- Monthly: $1,383,000
```

### Stress Phase

```
Bear market:
- Total supply: 15,000,000 ECHO
- Staked: 9,000,000 (60%)
- Tax rate: 7.67%
- Daily volume: $200,000 (reduced)
- Daily revenue: $15,340
- Monthly: $460,200

Note: Higher tax rate offsets lower volume
```

## User Impact

### Trading Costs

**Example Transfer**: 10,000 ECHO

```
At 4% tax (90%+ staking):
- Tax: 400 ECHO
- Received: 9,600 ECHO
- Cost: $200 (if ECHO = $0.50)

At 8% tax (65% staking):
- Tax: 800 ECHO
- Received: 9,200 ECHO
- Cost: $400

At 12% tax (35% staking):
- Tax: 1,200 ECHO
- Received: 8,800 ECHO
- Cost: $600
```

**Observation**: Tax cost triples from healthy to crisis.

### Buy vs Stake Decision

**Option A: Buy and Hold (unstaked)**
```
Buy 10,000 ECHO at $0.50 = $5,000
Hold for 1 year (unstaked)
Tax on eventual sell: 8% (assuming 65% staking)
Sell proceeds: 9,200 ECHO = $4,600
Loss: $400 (from tax)
```

**Option B: Buy and Stake**
```
Buy 10,000 ECHO at $0.50 = $5,000
Stake immediately (4% tax)
Earn 5,000% APY for 1 year
Balance: 510,000 eECHO
Unstake (penalty varies, assume 5.8% at 100% backing)
Receive: 480,420 ECHO
Sell (tax 4% if staking still high)
Proceeds: 461,203 ECHO = $230,601
Gain: $225,601

Even with unstake penalty + tax, massively better
```

**Conclusion**: Tax reinforces staking as optimal strategy.

### DEX Trading

**Uniswap Swaps**:
```
User swaps ETH for ECHO on Uniswap:
- Uniswap fee: 0.3%
- Transfer tax when ECHO leaves pool: 4-15%
- Total cost: 4.3-15.3%

Expensive compared to typical swaps
But this is intentional - encourages staking over trading
```

## Monitoring

### Tax Rate Dashboard

```
Current Transfer Tax: 6.2%
├── Base rate: 4.0%
└── Variable rate: 2.2%

Staking Ratio: 73.5%
├── Staked supply: 14.7M eECHO
└── Total supply: 20M ECHO

Tax Rate Calculation:
├── Target staking: 90%
├── Current staking: 73.5%
├── Deficit: 16.5%
└── Variable tax: 16.5% × (11% / 90%) = 2.2%

Revenue (24h):
├── Volume: $487,320
├── Tax collected: 60,234 ECHO
├── Auto-swapped: 30,117 ECHO → 15.06 ETH
├── To treasury: 15.06 ETH + 30,117 ECHO
└── USD value: ~$45,176
```

### Historical Trends

```
Tax Rate History (30 days):
Day 1: 5.8% (75% staking)
Day 7: 6.1% (72% staking)
Day 14: 5.5% (77% staking)
Day 21: 5.2% (79% staking)
Day 30: 4.9% (81% staking)

Trend: Improving (more staking) ✓
```

## Governance

### Parameter Adjustments

The DAO can adjust within bounds:

**Base Rate** (currently 4%):
```
Minimum: 2%
Maximum: 6%
Rationale: Always some revenue, never excessive
```

**Maximum Rate** (currently 15%):
```
Minimum: 10%
Maximum: 25%
Rationale: Must be punitive but not prohibitive
```

**Target Staking Ratio** (currently 90%):
```
Minimum: 75%
Maximum: 95%
Rationale: Realistic targets based on protocol maturity
```

**Auto-Swap Threshold** (currently 10,000 ECHO):
```
Minimum: 5,000 ECHO
Maximum: 50,000 ECHO
Rationale: Balance gas costs vs accumulation risk
```

### Restrictions

**Cannot**:
- Disable tax entirely
- Set tax >25%
- Bypass tax for specific users (except protocol contracts)
- Redirect tax away from treasury

**All changes**: 2-day timelock

## Advanced Topics

### Tax Arbitrage

**Potential Exploit**:
```
1. Notice staking ratio at 89% (4% tax)
2. Large unstake drops ratio to 85%
3. Tax increases to 4.61%
4. Frontrun the unstake, sell before tax increases

Mitigation:
- Tax recalculated every transfer
- No way to predict exact timing
- Unstake has queue, can't execute instantly
- Not economically significant (<1% difference)
```

### DEX Liquidity Impact

**Effect on Pools**:
```
ECHO/ETH Uniswap V3 pool:
- Every swap pays transfer tax
- Reduces liquidity provider profits
- May reduce pool liquidity

Mitigation:
- LP pools are tax-exempt for add/remove liquidity
- Only taxed on swaps
- High APY from staking compensates LPs
- Protocol-owned liquidity provides base
```

### Comparison to Reflection Tokens

**Reflection Tokens** (e.g., SafeMoon):
```
- Tax on transfers (similar)
- Redistributed to holders (different)
- Encourages holding, not staking
- No productive use of tax

EchoForge:
- Tax on transfers (similar)
- To treasury, not redistribution
- Encourages staking specifically
- Productive use (yield strategies)
```

---

**Last updated**: November 2025
**Related**: [Treasury Backing](./treasury-backing.md) | [Dynamic APY](./dynamic-apy.md)
