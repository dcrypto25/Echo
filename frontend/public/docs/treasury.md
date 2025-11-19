# EchoForge Treasury and Backing System

Complete documentation of the Forge Reserve treasury, backing calculations, buyback engine, and yield strategies.

---

## Treasury Overview

The Forge Reserve is EchoForge's DAO-controlled treasury that backs the ECHO token and ensures protocol sustainability.

### Core Functions

- **Backing ECHO Supply**: Maintains 100%+ backing ratio
- **Yield Generation**: Deploys assets to earn returns
- **Buyback Engine**: Supports price floor
- **Runway Management**: Ensures long-term sustainability
- **Risk Management**: Protects against volatility

**Key Principle**: Every ECHO is backed by real treasury assets.

---

## Backing Ratio Calculations

### What is Backing Ratio?

The backing ratio represents how much treasury value exists per ECHO token.

**Formula**:
```
backing_ratio = (total_treasury_value / total_ECHO_supply) × 100%

Where:
total_treasury_value = liquid_assets + yield_assets (in USD)
total_ECHO_supply = circulating supply
```

### Backing Examples

**Example 1: Healthy Protocol**
```
Treasury value: $2,000,000
ECHO supply: 1,000,000
Backing: $2.00 per ECHO

If market price = $1.50:
Backing ratio: ($2.00 / $1.50) × 100% = 133%
Status: Healthy (above 100%)
```

**Example 2: Stressed Protocol**
```
Treasury value: $800,000
ECHO supply: 1,000,000
Backing: $0.80 per ECHO

If market price = $1.00:
Backing ratio: ($0.80 / $1.00) × 100% = 80%
Status: Critical (below 100%)
```

**Example 3: Strong Protocol**
```
Treasury value: $3,000,000
ECHO supply: 1,000,000
Backing: $3.00 per ECHO

If market price: $1.00
Backing ratio: ($3.00 / $1.00) × 100% = 300%
Status: Very healthy (well above target)
```

### Backing Ratio Zones

| Ratio | Status | APY | Unstake Penalty | Actions |
|-------|--------|-----|----------------|---------|
| >200% | Excellent | 18,000-30,000% | 0% | Deploy to yield |
| 150-200% | Very Healthy | 12,000-18,000% | 0% | Normal operations |
| 100-150% | Healthy | 5,000-12,000% | 0-37.5% | Monitor closely |
| 80-100% | Stressed | 2,500-5,000% | 37.5-75% | Conservation mode |
| <80% | Critical | 0-2,500% | 75% | Emergency measures |

---

## Target Backing (100%+)

### Why 100% Matters

**Full Backing**:
- Every ECHO worth at least $1 in treasury
- Price floor established
- Redemption possible (theoretically)
- Sustainable protocol

**Above 100%**:
- Cushion for volatility
- Room for yield deployment
- Enables full rebases
- Confidence builder

**Below 100%**:
- Undercollateralized
- Risk of death spiral
- Reduced emissions
- High penalties

### Maintaining Target

**Revenue Sources**:
1. **Bonding curve sales** (one-time) - Fair launch, all proceeds to treasury
2. **Transfer taxes** (ongoing, 4-15% adaptive) - Auto-swaps 50% to ETH, continuous dual-asset revenue
3. **Protocol bonds** (ongoing) - Users deposit ETH/stablecoins for 5% discounted ECHO with 1-day vesting
4. **Unstake penalties** (0-75% based on backing) - 50% burned (deflationary), 50% to treasury
5. **Yield strategies** (ongoing) - GMX/GLP staking, productive treasury assets generate independent revenue
6. **Protocol fees** (future) - Additional revenue streams as protocol matures

**Strategies**:
1. Conservative yield deployment (GMX/GLP, low-risk strategies)
2. Strategic buybacks when backing ratio is strong
3. Emissions adjust automatically via dynamic APY (0-30,000%)
4. Penalty system protects treasury during stress (0-75% exponential curve)
5. Dual-asset treasury (ECHO + ETH) from auto-swap tax system
6. Supply contraction via burns (50% of penalties + emission balancer)

---

## Buyback Engine

### Buyback Mechanism

The treasury automatically buys and burns ECHO when price falls below floor.

**Trigger Conditions**:
```
1. Current price < 75% of 30-day TWAP
2. Treasury has liquid assets available
3. Weekly buyback limit not exceeded
```

### TWAP (Time-Weighted Average Price)

**What is TWAP?**:
- Average price over 30 days
- Smooths out volatility
- Prevents manipulation
- Fair reference point

**Calculation**:
```
TWAP = Σ(price_t × duration_t) / total_duration

Simplified:
- Track price every hour
- Average over 720 hours (30 days)
- Weight by time at each price
```

**Example**:
```
30-day TWAP: $1.50
Buyback floor: $1.50 × 75% = $1.125

If price drops to $1.10:
→ Buyback triggered
→ Treasury buys ECHO at market
→ Burns purchased ECHO
→ Supports price
```

### Buyback Triggers

**Price Floor Breach**:
```
if (current_price < TWAP × 0.75) {
    execute_buyback();
}
```

**Weekly Limits**:
```
max_buyback_per_week = treasury_value × 5%

Example:
Treasury: $2,000,000
Weekly max: $100,000

Prevents over-aggressive buying
Allows sustained support
```

### Buyback Process

**Step-by-Step**:
```
1. Price drops below floor ($1.10 vs $1.125 floor)
2. Buyback engine activates
3. Calculate max buyback ($100k this week)
4. Swap treasury assets for ECHO on DEX
5. Burn purchased ECHO
6. Price supported, supply reduced
7. Backing ratio improves
```

**Effects**:
- **Price**: Upward pressure from buying
- **Supply**: Reduced from burning
- **Backing**: Improved ratio (less supply)
- **Sentiment**: Confidence from protocol action

**Example Impact**:
```
Before:
Supply: 1,000,000 ECHO
Treasury: $2,000,000
Backing: 200%
Price: $1.10 (below $1.125 floor)

Buyback: $100,000
ECHO bought: ~90,909 ECHO (at $1.10)
ECHO burned: 90,909

After:
Supply: 909,091 ECHO
Treasury: $1,900,000
Backing: 209% (improved!)
Price: Supported upward
```

---

## Runway Calculations

### What is Runway?

Runway represents how long the treasury can sustain current emissions.

**Formula**:
```
runway_days = total_treasury_value / daily_emissions

Where:
daily_emissions = total_staked × (current_APY / 365)
```

### Example Calculation

**Scenario 1: Early Protocol**
```
Treasury: $1,000,000
Total staked: 500,000 ECHO @ $1 = $500,000 value
Backing: 200% → APY: 18,000%

Compound daily rate: (1 + 180)^(1/365) - 1 = 1.513% per day

Runway formula (compound growth): T = ln(1 + Treasury/Staked) / ln(1 + r)
T = ln(1 + 1,000,000/500,000) / ln(1.01513)
T = ln(3) / ln(1.01513)
T = 1.0986 / 0.01502
T ≈ 73 days

Status: Good runway, APY will auto-reduce as backing drops below 200%
```

**Scenario 2: Mature Protocol**
```
Treasury: $5,000,000
Total staked: 800,000 ECHO @ $1.50 = $1,200,000 value
Current APY: 4,000%

Compound daily rate: (1 + 40)^(1/365) - 1 = 1.034% per day

Runway formula: T = ln(1 + 5M/1.2M) / ln(1.01034)
T = ln(5.167) / ln(1.01034)
T = 1.642 / 0.01028
T ≈ 160 days

Status: Excellent runway (5+ months)
```

**Scenario 3: With Yield & Revenue**
```
Same as Scenario 2, but with:
- Treasury yield: 20% APY → +0.05% daily compound
- Transfer taxes: ~$2,000/day
- Protocol bonds: ~$1,500/day

Net emission rate: 1.034% - 0.05% ≈ 0.984% per day
Plus constant revenue offsets ~$3,500/day

Effective runway: 200+ days with revenue streams
Approaches indefinite with healthy bond sales and trading volume
```

### Runway Targets

| Runway | Status | Actions |
|--------|--------|---------|
| <30 days | Critical | Emergency measures, reduce APY |
| 30-60 days | Short | Monitor closely, optimize yield |
| 60-90 days | Acceptable | Normal operations |
| 90-180 days | Healthy | Deploy more to yield |
| >180 days | Excellent | Aggressive growth strategies |

### Extending Runway

**Methods**:
1. **Increase Revenue**:
   - More bonding curve sales
   - Higher transfer taxes (via low staking)
   - Deploy to higher-yield strategies
   - Add protocol fees

2. **Reduce Emissions**:
   - Dampener automatically adjusts
   - As backing drops, APY reduces
   - Self-regulating mechanism

3. **Balance Both**:
   - Optimal strategy
   - Sustainable equilibrium
   - Long-term thinking

---

## Yield Deployment

### Supported Strategies

**GMX Staking**:
- **Asset**: GMX tokens
- **Yield**: 15-20% APY in ETH + esGMX
- **Risk**: Low-medium (blue chip)
- **Liquidity**: Good
- **Status**: Approved

**GLP Staking**:
- **Asset**: GLP (GMX Liquidity Provider tokens)
- **Yield**: 20-30% APY in ETH + esGMX
- **Risk**: Medium (delta neutral but has IL)
- **Liquidity**: Excellent
- **Status**: Approved

**Aave Lending** (Future):
- **Asset**: Stablecoins, ETH
- **Yield**: 3-8% APY
- **Risk**: Very low
- **Liquidity**: Excellent
- **Status**: Planned

**Curve** (Future):
- **Asset**: LP tokens
- **Yield**: 10-20% APY
- **Risk**: Low-medium
- **Liquidity**: Good
- **Status**: Planned

### Allocation Strategy

**Target Allocation**:
```
30% Liquid (ETH, Stables)
├── Emergency reserves
├── Buyback capacity
└── Operational needs

60% Yield Strategies
├── 40% GLP (higher yield)
├── 15% GMX (medium yield)
└── 5% Aave (low risk)

10% ECHO Holdings
├── Buyback reserve
└── Market operations
```

**Dynamic Rebalancing**:
- Adjust based on market conditions
- Increase liquidity if backing drops
- Increase yield if backing strong
- DAO governance decisions

### Yield Example

**Treasury: $2,000,000**
```
Liquid: $600,000 @ 0% = $0
GLP: $800,000 @ 25% = $200,000/year
GMX: $300,000 @ 18% = $54,000/year
Aave: $100,000 @ 5% = $5,000/year
ECHO: $200,000 (no yield, buyback reserve)

Total yield: $259,000/year
= $709/day
= 13% average APY on treasury
```

**Impact on Runway**:
```
Daily emissions: $100,000
Daily yield: $709
Net daily cost: $99,291
Runway improvement: ~0.7%
```

While small %, compounds over time and increases with larger treasury.

---

## Insurance Vault

### Purpose

Separate insurance fund for extreme scenarios:

**Use Cases**:
- Smart contract exploit recovery
- Oracle manipulation
- Extreme market volatility
- DAO decisions for emergencies

**Funding**:
- 5% of transfer taxes (future)
- Protocol fees (future)
- Donations from community
- Grows independently

**Access**:
- Requires DAO vote
- Multi-sig controlled
- Documented usage
- Community transparency

**Target Size**:
- 10-20% of main treasury
- Grows over time
- Never touched unless emergency

---

## Treasury Management Process

### Regular Operations

**Daily**:
- Monitor backing ratio
- Track TWAP price
- Check yield performance
- Review pending transactions

**Weekly**:
- Rebalance if needed
- Deploy new funds to yield
- Withdraw matured positions
- Report to community

**Monthly**:
- Comprehensive treasury report
- Yield performance analysis
- Backing ratio trends
- Runway projections

**Quarterly**:
- Strategy review
- Allocation adjustments
- DAO governance votes
- Protocol improvements

### Emergency Procedures

**If Backing <100%**:
```
1. Pause new yield deployments
2. Increase liquid reserves
3. Reduce emissions via dampener
4. Analyze root cause
5. Communicate to community
6. Implement corrective measures
```

**If Backing <80%**:
```
1. Emergency DAO meeting
2. Halt all yield deployments
3. Prepare to withdraw from strategies
4. Maximum penalties activated
5. Consider emergency measures
6. Daily updates to community
```

**If Smart Contract Issue**:
```
1. Pause affected contracts
2. Assess damage
3. Deploy insurance vault if needed
4. Coordinate with auditors
5. Plan recovery
6. Compensate affected users
```

---

## Transparency and Reporting

### Public Metrics

**Always Visible**:
- Total treasury value
- Liquid vs yield allocation
- Current backing ratio
- TWAP price
- Buyback history
- Yield performance

**Real-Time**:
- On-chain data
- Block explorer
- Protocol dashboard
- Community tools

### Monthly Reports

**Contents**:
1. Treasury balance changes
2. Revenue sources breakdown
3. Yield strategy performance
4. Backing ratio history
5. Buyback activity
6. Runway projections
7. Upcoming changes

**Distribution**:
- Published on website
- Shared on social media
- Posted in Discord/Telegram
- Summarized in newsletters

---

## DAO Governance

### Treasury Control

**Multi-Sig Setup**:
- 5 of 7 signers required
- Community-elected members
- Geographic distribution
- Diverse backgrounds

**Powers**:
- Approve new yield strategies
- Adjust allocation percentages
- Execute buybacks (manual override)
- Emergency measures
- Update price oracles

**Restrictions**:
- Cannot steal funds
- Cannot mint ECHO
- Cannot change core parameters
- Time-locked for major changes

### Proposal Process

**For Treasury Changes**:
```
1. Community member proposes
2. Discussion period (7 days)
3. Formal proposal submitted
4. Voting period (3 days)
5. If passed: Implementation (2 days)
6. Total: ~12 days for changes
```

**Emergency Fast-Track**:
```
1. Multi-sig identifies emergency
2. Immediate action if unanimous
3. Community notified within 24h
4. Retroactive vote for validation
5. Explanation and transparency
```

---

## FAQ

**Q: Who controls the treasury?**
A: DAO via multi-sig (5 of 7). Eventually full DAO governance.

**Q: Can funds be stolen?**
A: No, multi-sig requires 5 signatures. No single point of failure.

**Q: What if yield strategies fail?**
A: Diversified across multiple protocols. Insurance vault for extreme cases.

**Q: How often are buybacks executed?**
A: Automatic when price < 75% TWAP. Max 5% treasury per week.

**Q: Can I see treasury composition?**
A: Yes, all on-chain and visible in dashboard.

**Q: What happens if backing goes to 0?**
A: Extremely unlikely. Dampener stops emissions at <80%. Insurance vault exists.

**Q: Who decides yield strategies?**
A: DAO governance with community input.

**Q: Is treasury yield guaranteed?**
A: No, DeFi yields fluctuate. Conservative strategies chosen.

---

## Conclusion

The EchoForge treasury provides:
- **100%+ backing** of ECHO supply
- **Sustainable yield** generation
- **Automatic buybacks** at price floor
- **Transparent operations** on-chain
- **DAO governance** for community control

**Result**: A well-managed, community-controlled treasury that ensures long-term protocol sustainability.

The Forge Reserve is the foundation of EchoForge's economic security.
