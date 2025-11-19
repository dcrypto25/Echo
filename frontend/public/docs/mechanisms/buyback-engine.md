# Buyback Engine

The Buyback Engine is an automated price support mechanism that uses treasury funds to purchase and burn ECHO tokens when the price falls significantly below its time-weighted average, creating a dynamic floor price.

## Overview

Unlike protocols that allow unrestricted price collapse, EchoForge's Buyback Engine activates automatically during severe price drops to:
- Provide price support
- Reduce circulating supply
- Improve backing ratio
- Demonstrate treasury strength

**Key Innovation**: Buybacks are automated, triggered by on-chain oracles, with no manual intervention required.

## Trigger Conditions

### Price Threshold

```
Buyback activates if:
currentPrice < TWAP_30day × 0.75

AND

backingRatio ≥ 100%
```

**Rationale**:

**75% TWAP Threshold**:
- TWAP smooths out short-term volatility
- 25% drop is significant, not noise
- Indicates genuine distress
- Rare enough to preserve treasury

**100% Backing Requirement**:
- Only buyback when treasury is healthy
- Prevents treasury depletion
- Ensures protocol sustainability
- Protects long-term viability

### Implementation

```solidity
function shouldExecuteBuyback() public view returns (bool) {
    // Get current spot price from Uniswap V3 pool
    uint256 currentPrice = _getSpotPrice();

    // Get 30-day TWAP from Chainlink + Uniswap
    uint256 twap30 = oracle.getTWAP(30 days);

    // Get current backing ratio
    uint256 backingRatio = treasury.getBackingRatio();

    // Check conditions
    bool priceBelowThreshold = currentPrice < (twap30 * 75) / 100;
    bool healthyBacking = backingRatio >= 10000;  // 10000 = 100%

    return priceBelowThreshold && healthyBacking;
}
```

## Execution Mechanism

### Buyback Process

```solidity
function executeBuyback(uint256 maxETH) external {
    require(shouldExecuteBuyback(), "Conditions not met");
    require(maxETH <= maxBuybackAmount, "Exceeds limit");

    // Withdraw ETH from treasury
    uint256 ethAmount = treasury.withdrawForBuyback(maxETH);

    // Swap ETH for ECHO on Uniswap V3
    uint256 echoBought = _swapETHForECHO(ethAmount);

    // Burn all purchased ECHO
    ECHO.burn(echoBought);

    // Record buyback
    totalBuybackETH += ethAmount;
    totalBuybackBurned += echoBought;

    emit Buyback(ethAmount, echoBought, block.timestamp);
}

function _swapETHForECHO(uint256 ethAmount) internal returns (uint256) {
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: address(WETH),
        tokenOut: address(ECHO),
        fee: 3000,  // 0.3% fee tier
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: ethAmount,
        amountOutMinimum: 0,  // Protected by TWAP check
        sqrtPriceLimitX96: 0
    });

    return swapRouter.exactInputSingle{value: ethAmount}(params);
}
```

### Execution Limits

**Maximum Per Buyback**:
```
maxBuybackAmount = treasuryValue × 5%

Example:
Treasury: $10M
Max buyback: $500k per execution
```

**Frequency Limit**:
```
Minimum time between buybacks: 24 hours

Prevents:
- Rapid treasury depletion
- Market manipulation attempts
- Gas wastage on small increments
```

**Daily Limit**:
```
maxDailyBuyback = treasuryValue × 10%

Example:
Treasury: $10M
Max daily: $1M across all buybacks
```

## Economic Impact

### Price Support

**Scenario**: Severe market dump

```
Initial state:
- TWAP_30: $1.00
- Current price: $0.70 (30% drop)
- Trigger: $0.70 < $1.00 × 0.75 ($0.75) ✓
- Backing: 120% ✓

Buyback executes:
- Treasury spends: $100k ETH
- Buys: 142,857 ECHO at $0.70
- Burns: 142,857 ECHO

Immediate effects:
1. Buy pressure: Price increases from buying
2. Supply reduction: 142,857 tokens removed
3. Psychological: Demonstrates treasury strength
4. Floor established: Market knows $0.75 is defended

New price: $0.78 (11.4% recovery)
```

### Backing Ratio Improvement

Buybacks paradoxically **improve** backing:

```
Before buyback:
- Market cap: $10M
- Treasury: $12M
- Backing: 120%

Buyback:
- Spend: $1M from treasury
- Burn: 1,333,333 ECHO (at $0.75)

After buyback:
- Market cap: $8.67M (reduced supply)
- Treasury: $11M (spent $1M)
- Backing: 126.8% (improved!)

Result: Stronger backing despite spending treasury
```

**Why**: Supply reduction exceeds treasury reduction when price is depressed.

### Supply Deflation

```
Total supply: 10,000,000 ECHO
Buyback burns: 500,000 ECHO (5%)

New supply: 9,500,000 ECHO

Per-token metrics:
- Treasury per ECHO: $12M / 9.5M = $1.26 (was $1.20)
- Backing improved
- Scarcity increased
- Long-term holders benefited
```

## Scenarios

### Major Dump Scenario

```
Day 1:
- TWAP: $1.00
- Price: $1.10 (healthy)

Day 15: Large holder dumps 2M ECHO
- Price crashes to $0.65
- TWAP: $0.95 (slowly adjusting)
- Trigger: $0.65 < $0.95 × 0.75 ($0.7125) ✓

Buyback #1:
- Spend: $500k ETH
- Buy: 769,230 ECHO at $0.65
- Burn: 769,230 ECHO
- Price: $0.72 (recovery)

24 hours later, if still triggered:

Buyback #2:
- Spend: $500k ETH
- Buy: 694,444 ECHO at $0.72
- Burn: 694,444 ECHO
- Price: $0.78 (further recovery)

Total:
- Spent: $1M ETH
- Burned: 1,463,674 ECHO
- Price recovered: $0.65 → $0.78 (20%)
```

### Prolonged Bear Market

```
Month 1: Price gradually declines
- TWAP adjusts downward slowly
- Buybacks inactive (price near TWAP)

Month 3: Price 30% below peak
- TWAP: $0.60
- Price: $0.40
- Trigger: $0.40 < $0.60 × 0.75 ($0.45) ✓

Buyback series:
- Day 1: Buy $500k, burn at $0.40
- Day 2: Buy $500k, burn at $0.42
- Day 3: Buy $500k, burn at $0.44
- ... continues until price >$0.45 or backing <100%

Result: Floor established at 75% TWAP
Even in bear market, price supported
```

### Failed Buyback Scenario

```
Severe crisis:
- TWAP: $0.50
- Price: $0.30
- Trigger threshold: $0.375
- Backing: 85% ❌

Buyback DOES NOT execute:
- Backing below 100% requirement
- Treasury preservation prioritized
- Protocol focuses on rebuilding backing

Alternative actions:
- APY reduces (Dynamic APY)
- Penalties increase (DUP)
- Focus on treasury growth
- Buyback resumes when backing >100%
```

## Strategy Considerations

### Versus Other Mechanisms

**Buybacks vs No Floor**:
```
Without buybacks:
- Price can collapse indefinitely
- No support during panic
- Death spiral accelerates
- User confidence destroyed

With buybacks:
- Floor at 75% TWAP
- Panic moderated
- Treasury demonstrates strength
- User confidence maintained
```

**Buybacks vs Fixed Floor**:
```
Fixed floor (e.g., always defend $1):
- Can drain treasury completely
- No adjustment to market reality
- May defend unsustainable price

Dynamic floor (75% TWAP):
- Adjusts to market conditions
- Preserves treasury
- Defends relative drops, not absolute price
- Sustainable long-term
```

### Treasury Trade-offs

**Benefits of Buybacks**:
- Price support
- Supply reduction
- Backing improvement
- User confidence

**Costs of Buybacks**:
- Reduces liquid reserves
- May need to withdraw from yield strategies
- Opportunity cost (could have earned yield)
- Doesn't prevent future dumps

**Optimal Policy**: Balance buybacks with treasury preservation

## Monitoring

### Buyback Dashboard

```
Buyback Engine Status:
├── Status: ACTIVE
├── Current Price: $0.72
├── 30-day TWAP: $0.95
├── Trigger Price: $0.7125 (75% of TWAP)
├── Price vs Trigger: +1.1% (above threshold, no buyback)
│
Parameters:
├── Backing Ratio: 118%
├── Treasury Value: $5.9M
├── Max Single Buyback: $295k (5% of treasury)
├── Max Daily Buyback: $590k (10% of treasury)
│
History (Last 30 days):
├── Total Buybacks: 3
├── Total ETH Spent: $1.2M
├── Total ECHO Burned: 1,687,423
├── Average Price Paid: $0.71
```

### Historical Performance

```
Buyback Event Log:

Event #1:
- Date: Nov 5, 2026
- Price: $0.68
- TWAP: $0.92
- ETH Spent: $400k
- ECHO Burned: 588,235
- Price 24h later: $0.76 (+11.8%)

Event #2:
- Date: Nov 6, 2026
- Price: $0.71
- TWAP: $0.91
- ETH Spent: $400k
- ECHO Burned: 563,380
- Price 24h later: $0.79 (+11.3%)

Event #3:
- Date: Nov 10, 2026
- Price: $0.66
- TWAP: $0.88
- ETH Spent: $400k
- ECHO Burned: 606,061
- Price 24h later: $0.74 (+12.1%)
```

## Governance Controls

### DAO Parameters

The DAO can adjust (via timelock):

**Trigger Threshold** (within bounds):
```
Minimum: 60% of TWAP (more aggressive)
Maximum: 85% of TWAP (more conservative)
Current: 75% of TWAP
```

**Maximum Buyback Size**:
```
Minimum: 2% of treasury
Maximum: 10% of treasury
Current: 5% of treasury
```

**Frequency Limits**:
```
Minimum wait: 12 hours
Maximum wait: 72 hours
Current: 24 hours
```

**TWAP Period**:
```
Minimum: 7 days
Maximum: 90 days
Current: 30 days
```

### Emergency Controls

**Pause Buybacks**:
```
If backing <80%:
- DAO can pause buybacks
- Preserves treasury
- Focuses on recovery
- Resumes when backing >100%
```

**Force Execution**:
```
If price <50% TWAP and backing >150%:
- DAO can force larger buyback
- Up to 20% of treasury
- Requires 9-of-15 multisig
- Emergency price support
```

## Advanced Topics

### MEV Considerations

**Front-Running Risk**:
```
Buyback transaction in mempool:
→ Arbitrageur sees it
→ Buys ECHO before buyback
→ Sells to buyback at higher price
→ Profits from price impact

Mitigation:
- Use private mempool (Flashbots)
- Implement slippage limits
- Execute in multiple smaller txs
- Use TWAP price protection
```

**Sandwich Attacks**:
```
Attacker:
1. Front-run: Buy ECHO
2. Buyback executes: Price increases
3. Back-run: Sell ECHO

Mitigation:
- Minimum amount out based on TWAP
- Gas price limits
- Execution randomization
```

### Oracle Manipulation

**Attack Vector**:
```
Attacker manipulates TWAP:
→ TWAP artificially high
→ Trigger threshold inflated
→ Buybacks don't execute when they should

Or reverse:
→ TWAP artificially low
→ Trigger too sensitive
→ Excessive buybacks
```

**Defense**:
```
Multi-oracle setup:
- Primary: Chainlink price feed
- Secondary: Uniswap V3 TWAP
- Fallback: Manual DAO override

Require consensus across oracles
Alert on >10% divergence
Auto-pause on manipulation detection
```

### Economic Optimization

**Optimal Buyback Sizing**:
```
Too small ($50k):
- Minimal price impact
- Doesn't demonstrate strength
- Wastes gas relative to impact

Too large ($5M):
- Severe treasury depletion
- May not be sustainable
- Could trigger confidence crisis

Optimal (~5% treasury):
- Meaningful price impact
- Sustainable treasury usage
- Demonstrates strength without depletion
```

## Comparison to Competitors

### OlympusDAO (OHM)

**OHM Approach**:
- No automatic buybacks
- Relied on "backing floor" narrative
- Users could redeem but didn't
- Collapsed without support

**EchoForge Advantage**:
- Automatic execution
- Proven commitment
- Active price support
- Stronger confidence

### Terra (LUNA)

**Terra Approach**:
- Algorithmic stabilization
- Infinite mint/burn
- No treasury backing
- Collapsed

**EchoForge Difference**:
- Treasury-backed buybacks
- Limited to treasury capacity
- Won't defend unsustainable prices
- Survives crashes

### Frax (FXS)

**Frax Approach**:
- Algorithmic + collateral backing
- AMO operations manage supply
- Complex mechanisms

**EchoForge Similarity**:
- Both treasury-backed
- Both use buybacks
- Both automated

**EchoForge Simpler**:
- Clear trigger conditions
- Transparent execution
- Easier to understand

---

**Last updated**: November 2025
**Related**: [Treasury Backing](./treasury-backing.md) | [Dynamic APY](./dynamic-apy.md)
