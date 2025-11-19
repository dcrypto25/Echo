# Treasury Backing

The EchoForge Treasury (Forge Reserve) is a DAO-controlled asset pool that backs every ECHO token with real value, providing a fundamental floor price and revenue source independent of token emissions.

## Overview

Unlike algorithmic stablecoins with no backing or reserve currencies that lost their backing during death spirals, EchoForge maintains **treasury-first economics** where backing ratio directly controls emissions through the Dynamic APY system.

**Core Principle**: Every ECHO token is backed by treasury assets. The backing ratio determines protocol health and all economic parameters.

## Backing Ratio Formula

```
backingRatio = (treasuryValue / marketCap) × 100%

Where:
treasuryValue = liquidAssets + yieldAssets + protocolOwnedLiquidity
marketCap = totalSupply × currentPrice
```

### Precise Calculation

```solidity
function getBackingRatio() public view returns (uint256) {
    // Calculate treasury value
    uint256 ethValue = address(treasury).balance;
    uint256 usdcValue = USDC.balanceOf(treasury);
    uint256 daiValue = DAI.balanceOf(treasury);
    uint256 usdtValue = USDT.balanceOf(treasury);

    // Yield strategy values
    uint256 gmxValue = gmxStrategy.getTotalValue();
    uint256 glpValue = glpStrategy.getTotalValue();
    uint256 aaveValue = aaveStrategy.getTotalValue();
    uint256 curveValue = curveStrategy.getTotalValue();

    // POL value
    uint256 lpValue = uniswapV3Strategy.getTotalValue();

    uint256 totalTreasuryValue = ethValue + usdcValue + daiValue + usdtValue +
                                  gmxValue + glpValue + aaveValue + curveValue + lpValue;

    // Calculate market cap
    uint256 totalSupply = ECHO.totalSupply();
    uint256 currentPrice = oracle.getPrice();  // In USD, 18 decimals
    uint256 marketCap = (totalSupply * currentPrice) / 1e18;

    // Return backing ratio in basis points (10000 = 100%)
    return (totalTreasuryValue * 10000) / marketCap;
}
```

## Treasury Composition

### Target Allocation

```
┌─────────────────────────────────────┐
│       Treasury Allocation            │
├─────────────────────────────────────┤
│                                      │
│  Productive Assets: 60%              │
│  ├── GMX Staking: 20%               │
│  ├── GLP: 25%                       │
│  ├── Curve Pools: 10%               │
│  └── Aave Lending: 5%               │
│                                      │
│  Liquid Reserves: 30%                │
│  ├── ETH: 15%                       │
│  ├── USDC: 10%                      │
│  └── DAI/USDT: 5%                   │
│                                      │
│  Protocol Owned Liquidity: 10%      │
│  └── ECHO/ETH LP: 10%               │
│                                      │
└─────────────────────────────────────┘
```

### Asset Rationale

**Productive Assets (60%)**:
- Generate 15-30% APY
- Provide sustainable revenue independent of new deposits
- Grow treasury automatically
- Diversified across DeFi blue chips

**Liquid Reserves (30%)**:
- Available for immediate needs
- Fund buybacks
- Cover unstake redemptions
- Maintain operational flexibility

**Protocol Owned Liquidity (10%)**:
- Ensures ECHO tradability
- Earns LP fees
- Reduces reliance on external liquidity
- Cannot be withdrawn

## Revenue Sources

### 1. Transfer Tax

```
Tax rate: 4-15% (adaptive based on staking ratio)

taxRate = 4% + 11% × max(0, (90% - stakingRatio) / 90%)
```

**Collection**:
```
On each ECHO transfer:
- Tax calculated on amount
- 50% sold for ETH via auto-swap
- 50% kept as ECHO
- Both sent to treasury

Example on $100,000 transfer at 8% tax:
- Tax collected: $8,000
- Auto-swap: $4,000 ECHO → $4,000 ETH
- Result: Treasury receives $4,000 ETH + $4,000 ECHO
```

**Projected Revenue**:
```
Daily volume: $500,000
Average tax: 8%
Daily revenue: $40,000
Annual: $14.6M
```

### 2. Unstake Penalties

```
Penalty: 0-75% (dynamic, exponential curve)
Distribution: 50% burned, 50% to treasury
```

**Collection**:
```
User unstakes 10,000 eECHO at 90% backing:
- Penalty: 13.8% = 1,380 eECHO
- To treasury: 690 eECHO (50%)
- Burned: 690 eECHO (50%)

Treasury value increases by 690 ECHO worth
```

**Projected Revenue**:
```
Daily unstakes: $50,000
Average penalty: 15%
To treasury: 50% of penalty
Daily revenue: $3,750
Annual: $1.37M
```

### 3. Early Unlock Penalties

```
Penalty: 90% to 10% (linear based on time served)
Distribution: 100% burned
```

**Note**: Early unlock penalties do NOT go to treasury - they are fully burned for deflationary effect.

### 4. Protocol Bonds

```
Discount: 5% below market price
Vesting: 1 day
Revenue: 100% to treasury
```

**Collection**:
```
User bonds $10,000 USDC:
- Market price: $0.50 per ECHO
- Bond price: $0.475 per ECHO (5% discount)
- User receives: 21,053 ECHO (vested as eECHO over 1 day)
- Treasury receives: $10,000 USDC

Treasury gains full deposit
User gets discounted ECHO
Win-win
```

**Projected Revenue**:
```
Daily bonds: $25,000
Annual: $9.1M
```

### 5. Bonding Curve (One-Time)

```
Launch mechanism: Exponential price curve
Supply: 1,000,000 ECHO
Revenue: ~$9,500 (all to treasury)
```

**Note**: Bonding curve is launch only, not recurring revenue.

### 6. DeFi Yield Strategies

```
GMX Staking: 15-20% APY
GLP: 20-30% APY
Aave Lending: 3-8% APY
Curve Pools: 10-20% APY
```

**Projected Revenue**:
```
Treasury productive assets: $1M
Blended APY: 20%
Annual revenue: $200,000

As treasury grows to $10M:
Annual revenue: $2M
```

### Total Revenue Projection

```
At Maturity ($5M treasury):

Transfer tax: $14.6M/year
Unstake penalties: $1.37M/year
Protocol bonds: $9.1M/year
DeFi yield: $1M/year

Total: $26.07M/year

Backing ratio support: Very strong
```

## Backing Ratio Zones

### Overcollateralized (≥200%)

**Characteristics**:
- Treasury worth 2× market cap
- Maximum safety margin
- Enables aggressive growth

**Parameters**:
- APY: 30,000% (maximum)
- Unstake penalty: 0%
- Queue: 1 day

**Example**:
```
Market cap: $5M
Treasury: $10M
Backing: 200%

Protocol can afford high emissions
Users can exit freely (no penalty)
System incentivizes staking via high APY
```

### Healthy (100-200%)

**Characteristics**:
- Full backing with buffer
- Sustainable growth zone
- Target equilibrium range

**Parameters**:
- APY: 5,000-30,000% (linear scaling)
- Unstake penalty: 0-5.8%
- Queue: 1-4 days

**Example**:
```
Market cap: $5M
Treasury: $6M
Backing: 120%

Moderate APY (10,000%)
Slight unstake friction (1.3% penalty)
Balanced incentives
```

### Undercollateralized (80-100%)

**Characteristics**:
- Below full backing but stable
- Caution zone
- Recovery mechanisms activate

**Parameters**:
- APY: 3,000-5,000%
- Unstake penalty: 5.8-23.3%
- Queue: 4-6 days

**Example**:
```
Market cap: $5M
Treasury: $4.5M
Backing: 90%

Lower APY (4,000%) reduces emissions
Higher penalty (13.8%) discourages unstaking
Penalty proceeds rebuild backing
```

### Crisis (<80%)

**Characteristics**:
- Significant undercollateralization
- Emergency measures active
- Protocol survival mode

**Parameters**:
- APY: 0-3,000%
- Unstake penalty: 23.3-75%
- Queue: 6-7 days

**Example**:
```
Market cap: $5M
Treasury: $3M
Backing: 60%

Very low APY (800%) minimal emissions
Severe penalty (54.3%) prevents bank run
Buyback engine activates
Focus on treasury rebuild
```

## Treasury Growth Mechanisms

### Compounding Growth

Treasury grows through multiple channels:

```
Month 0: $1M treasury, $2M market cap, 50% backing

Revenue sources:
- Transfer tax: +$40k/day
- Unstake penalties: +$3.75k/day
- DeFi yield: +$550/day
- Bonds: +$685/day
Total: ~$45k/day = $1.35M/month

Month 1:
Treasury: $2.35M
Market cap: $2.5M (some growth from APY)
Backing: 94%

Month 3:
Treasury: $5M (compounding yield)
Market cap: $4M (controlled growth via lower APY)
Backing: 125%
```

### Yield Compounding

DeFi strategies auto-compound:

```
GMX Staking:
- Stake 100 GMX ($5,000)
- Earn 18% APY in ETH + esGMX
- Reinvest ETH → more GMX
- Vest esGMX → more GMX
- After 1 year: 135 GMX ($6,750)
- Effective APY: 35% with compounding
```

### Auto-Swap Accumulation

Transfer tax accumulates before swapping:

```
Minimum threshold: 10,000 ECHO
When reached:
- Swap 50% ECHO for ETH via Uniswap V3
- Send ETH + remaining ECHO to treasury

Benefits:
- Reduces gas costs (batch swaps)
- Minimizes price impact
- Maintains balanced reserves
```

## Buyback Engine

### Trigger Conditions

```solidity
function shouldExecuteBuyback() public view returns (bool) {
    uint256 currentPrice = oracle.getPrice();
    uint256 twap30day = oracle.getTWAP(30 days);
    uint256 backingRatio = getBackingRatio();

    // Trigger if price <75% of TWAP AND backing >100%
    return (currentPrice < twap30day * 75 / 100) && (backingRatio >= 10000);
}
```

### Execution

```solidity
function executeBuyback(uint256 maxETH) external {
    require(shouldExecuteBuyback(), "Conditions not met");

    // Swap ETH for ECHO on Uniswap V3
    uint256 echoBought = swapRouter.exactInputSingle(
        ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: ECHO,
            fee: 3000,  // 0.3% pool
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: maxETH,
            amountOutMinimum: 0,  // Protected by TWAP check
            sqrtPriceLimitX96: 0
        })
    );

    // Burn purchased ECHO
    ECHO.burn(echoBought);

    emit Buyback(maxETH, echoBought);
}
```

### Economic Effect

```
Scenario: Price drops to $0.30, TWAP is $0.50

Trigger: $0.30 < $0.50 × 75% ($0.375) ✓
Backing: 120% ✓

Buyback executes:
- Treasury spends $100k ETH
- Buys 333,333 ECHO at $0.30
- Burns all 333,333 ECHO

Result:
- Supply reduced by 333,333
- Price pressure upward (buying + burning)
- Support at 75% TWAP floor
- Backing ratio improves (lower supply)
```

## Runway Calculation

Runway measures sustainability without new revenue:

```
runway (days) = treasury / daily_net_emissions

Where:
daily_net_emissions = daily_rebase_emissions - daily_revenue
```

### Formula

```solidity
function calculateRunway() public view returns (uint256) {
    // Daily emissions from rebases
    uint256 stakedSupply = eECHO.totalSupply();
    uint256 dailyAPY = currentAPY / 365;
    uint256 dailyEmissions = (stakedSupply * dailyAPY) / 10000;

    // Daily revenue
    uint256 dailyRevenue = _getDailyRevenue();  // From tax, penalties, yield

    // Net burn rate
    if (dailyRevenue >= dailyEmissions) {
        return type(uint256).max;  // Infinite runway (self-sustaining)
    }

    uint256 netBurn = dailyEmissions - dailyRevenue;
    uint256 treasuryValue = getTreasuryValue();

    // Runway in days
    return treasuryValue / netBurn;
}
```

### Scenario Analysis

**Healthy Protocol**:
```
Treasury: $10M
Daily emissions: $150k (at 5,000% APY)
Daily revenue: $120k (tax + penalties + yield)
Net burn: $30k/day

Runway: $10M / $30k = 333 days ✓
```

**Stressed Protocol**:
```
Treasury: $5M
Daily emissions: $50k (at 1,000% APY, reduced)
Daily revenue: $60k (high penalties during stress)
Net burn: -$10k (treasury growing!)

Runway: Infinite ✓
```

**Crisis Scenario**:
```
Treasury: $2M
Daily emissions: $20k (at 500% APY)
Daily revenue: $10k (minimal activity)
Net burn: $10k/day

Runway: $2M / $10k = 200 days
Action: Further reduce APY, increase penalties
```

## Risk Management

### Diversification

Treasury must diversify across:

**Asset Types**:
- 30% stablecoins (USDC/DAI/USDT)
- 30% ETH
- 30% blue-chip DeFi positions
- 10% ECHO LP

**Yield Strategies**:
- 20% GMX (high yield, moderate risk)
- 25% GLP (very high yield, higher risk)
- 10% Curve (moderate yield, low risk)
- 5% Aave (low yield, very low risk)

**Rationale**: Prevents single point of failure

### Liquidity Management

```
Maintain minimum liquid reserves:

If backing ≥150%: 20% liquid
If backing 100-150%: 30% liquid
If backing <100%: 40% liquid

Liquid = ETH + stablecoins (not in yield strategies)
```

**Purpose**: Fund redemptions without forced yield withdrawals

### Yield Strategy Limits

```
Maximum allocation per strategy: 30%
Maximum new strategy allocation: 10% (trial period)
Minimum strategy APY: 10% (otherwise move to Aave)
Maximum strategy risk rating: B (use protocol risk assessments)
```

### Oracle Redundancy

```
Primary: Chainlink ETH/USD and ECHO/ETH
Backup: Uniswap V3 TWAP
Fallback: Manual DAO override

If primary fails → use backup
If both fail → halt operations until manual intervention
```

## Governance

### DAO Control

The multisig (9-of-15) can:

**Asset Management**:
- Deploy treasury to approved yield strategies
- Rebalance asset allocation
- Withdraw from yield strategies
- Execute buybacks

**Strategy Approval**:
- Approve new yield strategies
- Set strategy allocation limits
- Emergency pause/withdraw

**Parameter Adjustment**:
- Adjust transfer tax bounds (within 4-15%)
- Modify buyback thresholds
- Update oracle sources

### Restrictions

The DAO **cannot**:

- Mint unbacked ECHO
- Transfer treasury to external addresses
- Change core formulas (APY, penalty curves)
- Bypass 2-day timelock on major actions

**Immutable Rules**:
- Backing ratio always calculated honestly
- No backdoors or escape hatches
- All actions on-chain and transparent

### Emergency Powers

If backing <50%, DAO can:

- Halt rebases temporarily
- Pause staking/unstaking
- Force-migrate to emergency yield strategies
- Execute coordinated buybacks

**Requires**: 9-of-15 multisig + no timelock

## Monitoring

### Key Metrics Dashboard

```
Treasury Health:
├── Backing Ratio: 125.3%
├── Treasury Value: $6.265M
├── Market Cap: $5M
├── Runway: 487 days
│
Revenue (24h):
├── Transfer Tax: $34,567
├── Unstake Penalties: $2,341
├── Protocol Bonds: $8,900
├── DeFi Yield: $1,876
├── Total: $47,684
│
Allocation:
├── Productive: 58.2% ($3.65M)
├── Liquid: 31.8% ($2M)
└── POL: 10% ($615k)
```

### Historical Tracking

```
Backing Ratio Trend (30 days):
Day 1: 110%
Day 7: 115%
Day 14: 120%
Day 21: 118%
Day 30: 125%

Trend: Improving ✓
```

---

**Last updated**: November 2025
**Related**: [Dynamic APY](./dynamic-apy.md) | [Unstake Penalty](./unstake-penalty.md)
