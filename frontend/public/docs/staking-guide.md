# EchoForge Staking Guide

Complete guide to staking ECHO tokens, earning eECHO rewards, and maximizing your returns.

---

## Staking Overview

Staking is the core mechanism for earning rewards in EchoForge. When you stake ECHO, you receive eECHO (rebasing token) that automatically grows your balance every 8 hours.

### Benefits of Staking

- **Dynamic APY (0-30,000%)**: Scales with treasury backing
- **Automatic Compounding**: Balance increases every 8 hours
- **Referral Bonuses**: Earn eECHO from referrals' stakes (4% of L1)
- **Governance Power**: Voting power proportional to stake
- **Lock Multipliers**: Up to 4× bonus for time-locking
- **Treasury Support**: Unstake penalties go to treasury (50%) and burn (50%)

---

## How Staking Works

### The Staking Process

```
1. You deposit ECHO
         ↓
2. ECHO wrapped to eECHO (1:1)
         ↓
3. Referral relationship recorded on-chain
         ↓
4. You start earning rebases
         ↓
5. Balance grows automatically
```

**What You Receive**:
- eECHO tokens (equal to ECHO staked initially)
- Access to rebase rewards at dynamic APY
- Referral capabilities
- Governance voting power

**No Lock Period**:
- Can unstake anytime (0-10 day redemption queue)
- Optional lock for bonus multipliers
- Penalty applies based on treasury backing (0-75%)

---

## eECHO Rebasing Explained

### What is Rebasing?

Rebasing means your token balance increases automatically without claiming or compounding actions.

**Traditional Staking**:
```
Stake: 1,000 tokens
After 1 month: Still 1,000 tokens
Rewards: 50 tokens (must claim)
Total: 1,050 tokens
```

**Rebasing (eECHO)**:
```
Stake: 1,000 eECHO
After 1 month: 3,500 eECHO (auto-increased)
Rewards: Already in balance
Total: 3,500 eECHO
```

### How Rebasing Works

**Rebase Schedule**:
- **Frequency**: Every 8 hours
- **Times per day**: 3
- **Annual rebases**: 1,095

**Rebase Mechanics**:
```solidity
Your internal shares (gons) stay constant
Total supply increases
Your balance = your_gons / (TOTAL_GONS / new_total_supply)
Balance increases proportionally
```

**Example Rebase**:
```
Before Rebase:
- Your balance: 1,000 eECHO
- Total supply: 100,000 eECHO
- Your share: 1%

Rebase Event (7.3% increase):
- Total supply: 107,300 eECHO
- Your share: Still 1%
- Your new balance: 1,073 eECHO
- Gain: 73 eECHO
```

**Key Point**: All holders receive the same % increase, proportional to their holdings.

---

## APY Calculations

### Dynamic APY System (0-30,000%)

**APY scales with backing ratio** (eECHO.sol lines 189-244):

```
Backing Ratio → APY
200% → 30,000%
100% → 5,000%
90% → 3,500% (gradual decline zone)
70% → 2,000% (knife catch zone)
Below 70% → Continues scaling down
```

**What This Means**:
- High backing = High APY rewards
- Low backing = Lower APY for sustainability
- Automatic adjustment each rebase

### APY Impact Examples

**Dynamic APY at Different Backing Levels**:

| Backing | APY | 1-Year Result (1K stake) |
|---------|-----|--------------------------|
| 200% | 30,000% | ~300,000 eECHO |
| 150% | ~15,000% | ~150,000 eECHO |
| 100% | 5,000% | ~50,000 eECHO |
| 90% | 3,500% | ~35,000 eECHO |
| 70% | 2,000% | ~20,000 eECHO |

**Real-World Scenario**:

Most protocols stabilize around 100-150% backing:
```
Average backing: 120%
Dynamic APY: ~7,500%
1-year result: ~75× multiplier
Adjusts automatically with backing changes
```

### Compounding Effect

Rebasing compounds automatically every 8 hours.

**Example at 200% Backing (30,000% APY)**:
```
Start: 1,000 eECHO
Per rebase: ~27.4% increase
After 1 day (3 rebases): ~2,070 eECHO
After 1 week: ~18,500 eECHO
After 1 month: ~1,500,000+ eECHO
```

**Example at 100% Backing (5,000% APY)**:
```
Start: 1,000 eECHO
Per rebase: ~4.6% increase
After 1 day (3 rebases): ~1,145 eECHO
After 1 week: ~2,300 eECHO
After 1 month: ~18,000 eECHO
```

**Important**: Actual returns depend on real-time backing ratio. APY adjusts automatically.

---

## Dynamic APY Mechanics

### Why Dynamic APY?

The dynamic APY system prevents death spirals by automatically adjusting rewards based on treasury health.

**Problem With Fixed APY**:
```
Low backing → Fixed high emissions → More selling → Lower backing → Death spiral
```

**Solution With Dynamic APY**:
```
Low backing → Lower APY → Reduced emissions → Less selling → Backing stabilizes
High backing → Higher APY → Rewards protocol health → Sustainable
```

### APY Zones

**Zone 1: Maximum (≥200% backing)**
- APY: 30,000%
- Protocol thriving
- Maximum rewards
- No concerns

**Zone 2: Strong (150-200% backing)**
- APY: ~15,000-30,000%
- High rewards
- Protocol healthy
- Sustainable

**Zone 3: Healthy (100-150% backing)**
- APY: ~5,000-15,000%
- Moderate rewards
- Protocol balanced
- Expected range

**Zone 4: Gradual Decline (90-100% backing)**
- APY: ~3,500-5,000%
- Reduced rewards
- Protocol adjusting
- Conservation mode

**Zone 5: Knife Catch (70-90% backing)**
- APY: ~2,000-3,500%
- Lower rewards
- Protocol stressed
- Survival mode

**Below 70% backing**:
- APY continues scaling down
- Minimal emissions
- Recovery needed

---

## Dynamic Unstake Penalty (DUP)

### How the Penalty Works

The unstake penalty protects the treasury during stress by discouraging mass exits.

**Penalty Range**: 0% to 75%
**Calculation**: Based on treasury backing ratio

**Formula**:
```solidity
if (backing >= 120%) {
    penalty = 0%; // No penalty
}
else if (backing <= 50%) {
    penalty = 75%; // Maximum penalty
}
else {
    // Linear scale between 0% and 75%
    range = 120% - 50% = 70%
    distance = 120% - backing
    penalty = (distance / range) × 75%
}
```

### Penalty Examples

| Backing | Penalty | On 10K Unstake | You Receive |
|---------|---------|----------------|-------------|
| ≥120% | 0% | 0 | 10,000 ECHO |
| 100% | 21.4% | 2,140 | 7,860 ECHO |
| 85% | 37.5% | 3,750 | 6,250 ECHO |
| 70% | 53.6% | 5,360 | 4,640 ECHO |
| 60% | 64.3% | 6,430 | 3,570 ECHO |
| 50% | 75% | 7,500 | 2,500 ECHO |

**Penalty Distribution**:
```
Total Penalty: 3,750 ECHO
    ├── 1,875 ECHO → Burned (deflationary)
    └── 1,875 ECHO → Treasury (protocol sustainability)
```

### When to Unstake

**Best Times** (0% penalty):
- Backing ≥120%
- Protocol healthy
- Maximum returns

**Acceptable Times** (0-30% penalty):
- Backing 95-120%
- Moderate penalty
- Personal needs

**Avoid If Possible** (30-75% penalty):
- Backing <95%
- High penalty
- Wait for recovery if can

**Strategy**:
- Monitor backing ratio daily
- Unstake during healthy periods
- Consider opportunity cost vs penalty
- Long-term holders avoid penalty entirely

---

## Redemption Queue System

### Queue Mechanics

Unstakes have a time delay based on backing to prevent bank runs.

**Queue Duration**: 0-10 days (based on backing)

**Formula**:
```solidity
queue_days = 10 × (120% - β) / 50%

Where β = backing ratio
```

**Queue Examples**:

| Backing | Queue Time | Calculation |
|---------|-----------|-------------|
| ≥120% | 0 days | 10 × (120% - 120%) / 50% = 0 |
| 95% | 5 days | 10 × (120% - 95%) / 50% = 5 |
| 82.5% | 7.5 days | 10 × (120% - 82.5%) / 50% = 7.5 |
| 70% | 10 days | 10 × (120% - 70%) / 50% = 10 |

**Purpose**:
- Prevents simultaneous mass exits
- Gives treasury time to rebalance
- Protects remaining stakers
- Reduces panic selling
- No wait when healthy (≥120% backing)

---

## Compounding vs Claiming

### Auto-Compounding (Default)

eECHO automatically compounds through rebasing:

**Advantages**:
- No gas fees for compounding
- Happens every 8 hours automatically
- Maximum growth potential
- Set and forget

**Process**:
```
Your balance increases
→ Next rebase uses higher balance
→ Exponential growth
→ No action needed
```

### Manual Claiming (Optional)

You can claim accrued rewards if needed:

**When to Claim**:
- Need liquidity
- Want to take profits
- Diversify holdings
- Pay expenses

**Process**:
```
1. Call claimRewards()
2. Rewards tracked for reporting
3. Balance remains in eECHO
4. Continue earning rebases
```

**Note**: Since eECHO auto-compounds, "claiming" is mainly for accounting/tracking purposes. To actually receive ECHO, you must unstake.

### Optimal Strategy

**For Maximum Growth**:
- Never claim/unstake
- Let rebasing compound
- Wait for 150%+ backing before unstaking
- Lock for multipliers

**For Regular Income**:
- Unstake small portions when backing ≥120%
- Leave majority staked
- Time unstakes for 0% penalty periods
- Consider lock multipliers for remaining stake

**For Risk Management**:
- Take initial investment out when 2× (if backing allows)
- Let profits run
- Diversify large positions
- Monitor backing ratio

---

## Maximizing Returns

### 1. Lock for Multipliers

Voluntarily lock your eECHO for bonus rewards:

**Lock Tiers**:

| Duration | Multiplier | Example at 100% Backing |
|----------|-----------|------------------------|
| 30 days | 1.2× | 5,000% → 6,000% APY |
| 90 days | 2× | 5,000% → 10,000% APY |
| 180 days | 3× | 5,000% → 15,000% APY |
| 365 days | 4× | 5,000% → 20,000% APY |

**Impact on APY**:
```
Base APY at 200% backing: 30,000%
With 365-day lock: 120,000% APY
Theoretical maximum!
```

**Considerations**:
- Funds locked until expiry
- Can extend lock to higher tier
- Time-based unlock penalty (90% declining to 10%)
- Multiplies ALL rewards (rebases + referrals)

### 2. Build Referral Network

Earn eECHO from up to 10 levels:

**Referral Structure**:
- L1 (Direct): 4% of their stake as eECHO
- L2: 2% as eECHO
- L3-L10: 1% each as eECHO

**How It Works**:
- Receive eECHO instantly when referral stakes
- Your eECHO rebases alongside their stake
- Protected by transfer tax (gaming is unprofitable)
- With 365d lock: Referral bonuses get 4× multiplier!

**Strategy**:
- Share referral link widely
- Create valuable content
- Build community
- Help referrals succeed

### 3. Time Your Actions

**Stake When**:
- Bonding curve price is low (early)
- Backing ratio is healthy
- Before major marketing campaigns

**Lock When**:
- You're confident in long-term
- Backing >150% (healthy)
- Want maximum multipliers

**Unstake When**:
- Backing >150% (0% penalty)
- After reaching goals
- Need liquidity

---

## Step-by-Step Staking Guide

### First-Time Staking

**Prerequisites**:
- ECHO tokens in wallet
- Arbitrum network selected
- Some ETH for gas fees

**Process**:

1. **Navigate to Stake Page**
   - Go to app.echoforge.xyz/stake
   - Connect wallet

2. **Enter Amount**
   - Input ECHO amount to stake
   - See expected eECHO received (1:1)

3. **Add Referrer** (Optional)
   - Paste referrer's address
   - Or leave blank

4. **Approve ECHO**
   - Click "Approve"
   - Confirm transaction
   - Wait for confirmation

5. **Stake**
   - Click "Stake ECHO"
   - Confirm transaction
   - Receive eECHO

6. **Verify**
   - Check eECHO balance
   - View staking position on dashboard
   - Monitor next rebase countdown

### Additional Staking

Already staking? Just stake more:

1. **Navigate to Stake Page**
2. **Enter Additional Amount**
3. **Approve & Stake**
4. **eECHO Added to Balance**

Your staking position updates with new amount.

### Locking Your Stake

**Process**:

1. **Navigate to Lock Page**
2. **Choose Duration** (30/90/180/365 days)
3. **Enter Amount to Lock**
4. **Approve eECHO**
5. **Execute Lock**
6. **Multiplier Activated**

**Note**: Can extend lock to higher tier, but can't reduce duration.

---

## Unstaking Process

### Request Unstake

1. **Navigate to Unstake Page**
2. **Enter Amount to Unstake**
3. **Check Current Penalty**
4. **Click "Request Unstake"**
5. **7-Day Cooldown Starts**

### Execute Unstake

After queue time (0-10 days):

1. **Return to Unstake Page**
2. **Click "Execute Unstake"**
3. **Penalty Applied**
4. **Receive Net ECHO**

**What Happens**:
```
Request: 10,000 eECHO
Penalty (115% backing): 37.5%
Penalty amount: 3,750 ECHO
    ├── 1,875 → Burned
    └── 1,875 → Treasury
You receive: 6,250 ECHO
```

---

## Monitoring Your Position

### Key Metrics to Track

**Your Dashboard**:
- eECHO balance (grows every 8 hours)
- Next rebase countdown
- Current backing ratio
- Current APY (dynamic based on backing)
- Unstake penalty (if unstaking today)
- Redemption queue time
- Referral count and volume

**Protocol Health**:
- Treasury backing ratio
- Total staked (staking ratio)
- Current tax rate
- Runway days

**Optimize Based On**:
- If backing ≥120%: Safe to unstake
- If backing 100-150%: Normal operations
- If backing <100%: Consider holding

---

## Common Scenarios

### Scenario 1: Long-Term Holder

**Strategy**:
- Stake early from bonding curve
- Lock for 365 days (4× multiplier)
- Build referral network
- Never unstake
- Hold through backing fluctuations

**Potential Returns**:
```
Initial: 10,000 ECHO
Lock: 365 days (4× all rewards)
Base APY at 100% backing: 5,000%
With lock: 20,000% APY
Referrals: 4% of downline as eECHO × 4
1-year result: Massive returns
```

### Scenario 2: Active Trader

**Strategy**:
- Stake moderate amount
- No lock (flexibility)
- Build small referral network
- Unstake when backing ≥120% (0% penalty, no queue)
- Reinvest profits

**Potential Returns**:
```
Initial: 5,000 ECHO
No lock
APY varies with backing (0-30,000%)
Periodic unstakes for profits
Sustainable strategy
```

### Scenario 3: Risk-Averse

**Strategy**:
- Stake after bonding curve complete
- 90-day lock (2× multiplier)
- Minimal referrals
- Unstake 2× initial when backing optimal
- Let remainder compound

**Potential Returns**:
```
Initial: 3,000 ECHO
Conservative lock
Wait for 0% penalty
Recover initial + profit
Reduced risk
```

---

## Risk Considerations

### Rebase Risks

- **Dynamic APY reduces** when backing low
- **Ranges 0-30,000%** based on backing
- **Not guaranteed** returns

**Mitigation**: Monitor backing ratio, diversify

### Unstake Penalty Risks

- **Up to 75% penalty** if backing low (50% to treasury, 50% burned)
- **Locks value** during stress
- **0-10 day queue** based on backing

**Mitigation**: Only invest what you can lock long-term

### Lock Risks

- **Time-based penalty** for early unlock (90% declining to 10%)
- **Can't reduce duration**
- **Opportunity cost** if better options emerge

**Mitigation**: Only lock amount you won't need

### Smart Contract Risks

- **Code vulnerabilities** (mitigated by audits)
- **Admin key risks** (mitigated by multisig)
- **Oracle failures** (mitigated by redundancy)

**Mitigation**: Start with small amounts, verify contracts

---

## FAQ

**Q: When do I receive rebases?**
A: Automatic every 8 hours. No action needed.

**Q: Can I lose my staked ECHO?**
A: No, but unstake penalty can be up to 75% if backing is low (50% to treasury, 50% burned).

**Q: What if I need funds urgently?**
A: Can unstake anytime, but face 0-10 day queue and potential penalty based on backing.

**Q: Can I stake more later?**
A: Yes, any amount, anytime. Adds to existing position.

**Q: Do I have to lock?**
A: No, locking is optional for bonus multipliers.

**Q: How does governance work?**
A: Voting power is proportional to your staked amount - more stake equals more influence.

---

## Conclusion

Staking in EchoForge offers:
- Dynamic APY (0-30,000% based on backing)
- Automatic compounding via rebasing
- Sustainability through dynamic adjustments
- Multiple ways to maximize returns
- Flexible lock options

**Keys to Success**:
1. Stake early for best pricing
2. Lock for multipliers (up to 4×)
3. Build referral network (earn eECHO)
4. Monitor backing ratio for optimal APY
5. Think long-term

Welcome to dynamic, sustainable DeFi yields!
