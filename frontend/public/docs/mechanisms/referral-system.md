# Referral System

EchoForge's 10-level referral system rewards network builders with eECHO emissions, creating viral growth incentives while maintaining economic sustainability.

## Overview

The referral system allows users to earn commissions on stakes made by their referrals across 10 hierarchical levels, with total emissions capped at 14% per stake.

**Key Feature**: Commissions are paid in eECHO (rebasing token), meaning referral earnings continue to compound through rebases.

## Commission Structure

### Level-Based Rates

```
Level 1 (Direct referrals):     4% of stake
Level 2 (2nd tier):              2% of stake
Levels 3-10 (remaining tiers):   1% each

Total maximum per stake: 14%
```

**Example Tree**:
```
You (L0)
├── Alice (L1) → stakes 10,000 ECHO → you earn 400 eECHO (4%)
│   └── Bob (L2) → stakes 5,000 ECHO → you earn 100 eECHO (2%)
│       └── Carol (L3) → stakes 20,000 ECHO → you earn 200 eECHO (1%)
│           └── Dave (L4) → stakes 8,000 ECHO → you earn 80 eECHO (1%)
│               └── [L5-L10 continue at 1% each]
```

## Mechanics

### Stake Flow with Referral

When a user stakes with a referral code:

```solidity
function stake(uint256 amount, address referrer) external {
    // 1. Transfer ECHO from user
    ECHO.transferFrom(msg.sender, address(this), amount);

    // 2. Mint eECHO to user (1:1)
    eECHO.mint(msg.sender, amount);

    // 3. Process referral bonuses
    if (referrer != address(0)) {
        _distributeReferralBonuses(msg.sender, amount, referrer);
    }

    emit Stake(msg.sender, amount, referrer);
}

function _distributeReferralBonuses(
    address staker,
    uint256 amount,
    address referrer
) internal {
    address current = referrer;

    for (uint256 level = 1; level <= 10; level++) {
        if (current == address(0)) break;

        // Calculate commission
        uint256 commission;
        if (level == 1) {
            commission = amount * 400 / 10000;  // 4%
        } else if (level == 2) {
            commission = amount * 200 / 10000;  // 2%
        } else {
            commission = amount * 100 / 10000;  // 1%
        }

        // Mint ECHO for commission
        ECHO.mint(address(this), commission);

        // Wrap to eECHO
        eECHO.wrap(commission);

        // Transfer eECHO to referrer
        eECHO.transfer(current, commission);

        emit ReferralBonus(current, staker, level, commission);

        // Move up the tree
        current = referrals[current].referrer;
    }
}
```

### Registration

Users register their referral relationship on first stake:

```solidity
mapping(address => Referral) public referrals;

struct Referral {
    address referrer;        // Who referred this user
    address[] referees;      // Who this user has referred
    uint256 totalEarned;     // Total eECHO earned from referrals
    uint256 totalReferees;   // Count of direct referrals
}
```

**Rules**:
- Referral relationship is permanent (cannot change)
- Cannot refer yourself
- Cannot create circular references
- Can be referred by only one address
- Can refer unlimited addresses

## Economic Impact

### Emission Analysis

Referral bonuses create inflationary pressure:

```
User stakes 10,000 ECHO with full 10-level tree
Direct stake mints: 10,000 eECHO (1:1 with deposited ECHO)

Referral bonuses mint:
L1: 400 eECHO (4%)
L2: 200 eECHO (2%)
L3: 100 eECHO (1%)
L4: 100 eECHO (1%)
L5: 100 eECHO (1%)
L6: 100 eECHO (1%)
L7: 100 eECHO (1%)
L8: 100 eECHO (1%)
L9: 100 eECHO (1%)
L10: 100 eECHO (1%)
Total referral: 1,400 eECHO (14%)

Total minted: 11,400 eECHO
Backing: 10,000 ECHO
Dilution: 14% if full tree
```

### Sustainability

The 14% dilution is sustainable because:

1. **Most stakes don't have full trees**:
```
Average referral depth: 3-4 levels
Average dilution: 6-7% (not 14%)
```

2. **Treasury mechanisms compensate**:
```
Transfer tax: 4-15% on all trades
Unstake penalties: 0-75% on exits
Yield strategies: 15-30% APY on treasury
```

3. **Referral earnings stay in ecosystem**:
```
Referrers receive eECHO (not ECHO)
eECHO participates in rebases
Most referrers stake long-term
Selling pressure minimal
```

## Viral Growth Mechanics

### Incentive Alignment

The multi-level structure creates aligned incentives:

**Level 1 (4%)**:
- Highest commission encourages direct outreach
- Users actively seek people to refer
- Quality over quantity (want them to stake more)

**Level 2 (2%)**:
- Encourages helping L1 referrals succeed
- Users teach their direct referrals how to refer others
- Network expansion becomes collaborative

**Levels 3-10 (1% each)**:
- Passive earnings from deep network growth
- Rewards early participants as network scales
- Creates long-term retention

### Growth Scenarios

**Scenario 1: Active Networker**
```
You refer 10 people (L1)
Each refers 5 people (L2 = 50 total)
Each L2 refers 2 people (L3 = 100 total)

Each person stakes average 5,000 ECHO

Your earnings:
L1: 10 × 5,000 × 4% = 2,000 eECHO
L2: 50 × 5,000 × 2% = 5,000 eECHO
L3: 100 × 5,000 × 1% = 5,000 eECHO
Total: 12,000 eECHO

At 5,000% APY, after 1 year: 612,000 eECHO
```

**Scenario 2: Whale Referrer**
```
You refer 1 whale who stakes 1,000,000 ECHO
You earn: 40,000 eECHO immediately

At 5,000% APY, after 1 year: 2,040,000 eECHO
From a single referral!
```

**Scenario 3: Organic Growth**
```
You refer 3 people who each stake 10,000 ECHO
You earn: 3 × 10,000 × 4% = 1,200 eECHO

They each refer 2 more (6 total L2)
You earn: 6 × 10,000 × 2% = 1,200 eECHO

Total: 2,400 eECHO base
After 1 year at 5,000% APY: 122,400 eECHO
```

## User Strategies

### Maximizing Referral Income

**Strategy 1: Target High-Value Referrals**
```
10 referrals × $1,000 each = $10,000 volume
→ $400 in eECHO (4%)

vs.

1 referral × $10,000 = $10,000 volume
→ $400 in eECHO (4%)

Same commission, less effort
Quality > quantity for L1
```

**Strategy 2: Build Depth, Not Width**
```
Shallow tree:
You → 100 L1 referrals
Income: 100 × stake × 4% = 4× stake
Depth: 1 level

Deep tree:
You → 5 L1 → each gets 5 L2 → each gets 3 L3
Income:
  L1: 5 × stake × 4% = 0.2× stake
  L2: 25 × stake × 2% = 0.5× stake
  L3: 75 × stake × 1% = 0.75× stake
  Total: 1.45× stake

But L2 and L3 continue growing organically
Deep tree has compounding growth
```

**Strategy 3: Educate Referrals**
```
Teach your L1 referrals to:
- Understand the protocol
- Build their own referral networks
- Use lock tiers for multipliers

Educated referrals:
- Stake more
- Stay longer
- Refer better quality users
- Create sustainable network
```

### Referral Tracking

Users can monitor referral performance:

```javascript
// Dashboard metrics
{
  directReferrals: 12,           // L1 count
  totalNetwork: 347,             // All levels
  totalEarned: "45,234 eECHO",  // Lifetime earnings
  pendingEarnings: "234 eECHO",  // From recent stakes
  topReferral: "Alice (23,400 eECHO generated)"
}
```

## Technical Implementation

### Anti-Circular Validation

The contract prevents circular referrals:

```solidity
function _validateReferral(address user, address referrer) internal view {
    require(referrer != address(0), "Invalid referrer");
    require(referrer != user, "Cannot refer self");
    require(referrals[user].referrer == address(0), "Already referred");

    // Check for circular reference by walking up tree
    address current = referrer;
    uint256 depth = 0;

    while (current != address(0) && depth < 10) {
        require(current != user, "Circular referral detected");
        current = referrals[current].referrer;
        depth++;
    }
}
```

### Gas Optimization

Distributing across 10 levels is gas-intensive:

**Gas Costs**:
```
Stake without referral: ~150k gas
Stake with 1-level referral: ~200k gas (+50k)
Stake with full 10-level tree: ~400k gas (+250k)

On Arbitrum: ~$0.10 → ~$0.40 (negligible)
```

**Optimization Techniques**:
- Early loop termination when address(0) found
- Minimal storage writes per iteration
- Batch commission calculations

### Claiming vs Automatic

Commissions are **automatically distributed**:

```
User stakes → referral bonuses immediately minted and sent
No claiming required
Instant eECHO delivery to all 10 levels
```

This is superior to claim-based systems:
- No forgotten rewards
- No additional gas costs
- Immediate participation in rebases

## Economic Simulations

### Network Growth Impact

```
Month 1: 100 stakers, average 5,000 ECHO
- Direct stakes: 500,000 ECHO
- Referral bonuses: ~35,000 eECHO (7% avg dilution)
- Backing ratio: 450% → 420% (healthy)

Month 3: 1,000 stakers (10× growth)
- Direct stakes: 5,000,000 ECHO
- Referral bonuses: ~350,000 eECHO
- Backing ratio: 420% → 380% (still healthy)

Month 6: 5,000 stakers
- Direct stakes: 25,000,000 ECHO
- Referral bonuses: ~1,750,000 eECHO
- Backing ratio: 380% → 320% (adjustment needed)
- APY reduces from 30,000% to 25,000%

Month 12: Network maturity
- New staking slows (mature market)
- Referral dilution decreases
- Treasury yield catches up
- Equilibrium at 150-200% backing
```

### Worst-Case Scenario

**Sybil Attack Attempt**:
```
Attacker creates 1,000 addresses
Each refers the next in chain
All stake 100 ECHO each

Attack earnings:
L1-L10 on 100 addresses deepest in chain
Max: 14× 100 = 1,400 eECHO

Attack cost:
1,000 × 100 = 100,000 ECHO locked
Gas: 1,000 × $0.20 = $200

Not economically rational
Better to just stake the 100,000 ECHO
```

## Comparison to Other Referral Systems

### Traditional Referral Programs

**CeFi Exchange Referrals**:
- Typical: 20% of trading fees
- One-time or recurring on fees
- Fiat payouts
- KYC required

**EchoForge Advantage**:
- 4-14% of stake principal (not just fees)
- Paid in rebasing eECHO
- Permissionless
- Compounds automatically

### DeFi Ponzi Schemes

**Red Flags EchoForge Avoids**:
```
Typical Ponzi:
- Referral bonuses: 20-50% (unsustainable)
- Infinite levels or very deep (10-20 levels)
- No revenue model besides new deposits
- Exit scams common

EchoForge:
- Referral bonuses: 4-14% (sustainable)
- Capped at 10 levels
- Multiple revenue: tax, penalties, yield
- Decentralized, no exit possibility
```

### Legitimate DeFi Referrals

**PancakeSwap Referrals**:
- 5% of friend's trading fees
- 2 levels only
- Paid in CAKE

**GMX Referrals**:
- 5% fee discount for referee
- 5% of fees to referrer
- Tier system based on volume

**EchoForge Position**:
- Middle ground on generosity (14% total)
- Deeper tree (10 levels) for viral growth
- Rebasing token multiplies value
- Higher upside than competitors

## Monitoring Referral Health

### Protocol-Level Metrics

```
Total referral emissions: 2.4M eECHO
Total staked: 18M ECHO
Dilution: 13.3%

Average tree depth: 3.7 levels
Average commission per stake: 7.2%
Active referrers: 12,340
Inactive stakers (no referrals): 45,600

Emissions within sustainable range ✓
```

### User-Level Dashboard

```
Your Referral Stats:
├── Direct referrals: 8
├── Total network: 124
├── Network stake: 1.2M ECHO
├── Your earnings: 34,500 eECHO
├── Current value: $172,500
└── Next rebase: +127 eECHO
```

## Future Enhancements

**Planned**:
- Referral NFTs for top performers
- Bonus multipliers for milestone achievement
- Referral leaderboards
- Analytics dashboard for network visualization

**Under Consideration**:
- Optional referral code vanity names
- Partial referral donation to treasury
- Dynamic commission rates based on protocol health
- Cross-chain referral tracking

---

**Last updated**: November 2025
**Related**: [Dynamic APY](./dynamic-apy.md) | [Lock Tiers](./lock-tiers.md)
