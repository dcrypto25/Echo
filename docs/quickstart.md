# Getting Started with EchoForge

This guide will help you start earning with EchoForge in under 10 minutes.

## Prerequisites

- **Wallet**: MetaMask or compatible Web3 wallet
- **Network**: Arbitrum One added to wallet
- **Assets**: ETH on Arbitrum for gas + ECHO purchase

## Step 1: Acquire ECHO

### Option A: Buy from DEX (Recommended)

1. Visit https://app.echoforge.xyz
2. Connect your wallet
3. Navigate to "Swap" tab
4. Enter ETH amount → receive ECHO estimate
5. Review price and slippage
6. Click "Swap" and confirm transaction

**Expected Cost**: ~$0.10 gas fee on Arbitrum

### Option B: Protocol Bonds (5% Discount)

1. Navigate to "Bonds" tab
2. Select payment token (ETH, USDC, USDT, DAI)
3. Enter amount → see discounted ECHO amount
4. Review 1-day vesting period
5. Click "Bond" and confirm
6. Receive vested eECHO after 24 hours

**Benefit**: 5% discount vs market price
**Tradeoff**: 1-day wait period

## Step 2: Stake ECHO

1. Navigate to "Stake" tab
2. Enter ECHO amount to stake
3. **Optional**: Enter referrer address (earn them 4%)
4. Click "Approve ECHO" (first time only)
5. Wait for approval transaction
6. Click "Stake" and confirm transaction

**Result**: Receive eECHO 1:1 immediately

### Understanding eECHO

Your eECHO balance automatically increases every 8 hours through rebasing:

```
Current balance: 1,000 eECHO
After 8 hours (at 5,000% APY): 1,009.4 eECHO
After 24 hours: 1,028.3 eECHO
After 7 days: 1,197 eECHO
After 30 days: 2,123 eECHO
After 365 days: ~51,000 eECHO
```

**Important**: APY changes based on backing ratio (0-30,000%)

## Step 3: Optional - Lock for Multipliers

Locking increases your APY up to 4×:

1. Navigate to "Lock" tab
2. Enter eECHO amount
3. Select duration:
   - 30 days → 1.2× APY
   - 90 days → 2.0× APY
   - 180 days → 3.0× APY
   - 365 days → 4.0× APY
4. Review early unlock penalty (90% → 10% based on time served)
5. Click "Lock" and confirm

**Example**:
```
Lock 1,000 eECHO for 365 days
Base APY: 5,000%
Your APY: 20,000% (4× multiplier)
After 1 year: ~204,000 eECHO (vs 51,000 unlocked)
```

**Caution**: Early unlock has time-based penalty. Only lock if committed.

## Step 4: Optional - Refer Friends

Earn 4-14% of referee stakes:

1. Navigate to "Referral" tab
2. Copy your referral link
3. Share with friends
4. When they stake using your link:
   - You earn 4% of their stake (as eECHO)
   - Your referrers earn 2% (L2) and 1% (L3-L10)

**Example**:
```
Friend stakes 10,000 ECHO using your link
You receive: 400 eECHO immediately
This eECHO rebases with your balance
At 5,000% APY, after 1 year: ~20,400 eECHO
```

## Step 5: Monitor Your Position

### Dashboard Metrics

**Your Balance**:
- Total eECHO (rebasing automatically)
- Locked eECHO (if using lock tiers)
- Current APY (changes with backing)
- Next rebase countdown

**Protocol Health**:
- Backing Ratio (target: 100-150%)
- Treasury Value
- Staking Ratio
- Current APY

### Key Indicators

**Healthy Protocol**:
- Backing ≥ 100%
- APY: 5,000-12,000%
- Unstake penalty: 0-15%
- Queue: 1-3 days

**Stressed Protocol**:
- Backing: 80-100%
- APY: 2,500-5,000%
- Unstake penalty: 15-40%
- Queue: 4-7 days

## Step 6: Unstaking (When Ready)

Unstaking has two steps due to the queue system:

### Request Unstake

1. Navigate to "Stake" tab
2. Click "Unstake" section
3. Enter eECHO amount
4. Review:
   - Current penalty (0-75% based on backing)
   - Queue time (1-7 days based on backing)
5. Click "Request Unstake" and confirm

### Claim After Queue

1. Wait for queue period to expire
2. Return to "Unstake" section
3. Click "Claim" button
4. Confirm transaction
5. Receive ECHO (minus penalty) to wallet

**Example**:
```
Backing ratio: 90%
Unstake 10,000 eECHO

Penalty: 13.8% (exponential curve)
Queue: 6.4 days

After queue:
Penalty: 1,380 eECHO
- 690 burned (deflationary)
- 690 to treasury (restores backing)
You receive: 8,620 ECHO
```

## Understanding Costs and Timing

### Gas Costs (Arbitrum)

- Approve: ~$0.05
- Stake: ~$0.10
- Request unstake: ~$0.08
- Claim unstake: ~$0.10
- Lock: ~$0.12

**Total to start**: ~$0.15 (approve + stake)

### Time Commitments

- Rebases: Every 8 hours automatically
- Lock periods: 30-365 days (optional)
- Unstake queue: 1-7 days based on backing
- No minimum hold time if not locked

## Strategies for Different Goals

### Maximum APY (High Risk)

```
1. Lock 100% for 365 days (4× multiplier)
2. Build referral network
3. Hold through volatility
4. Target: 20,000-40,000% effective APY

Risk: Severe early unlock penalty, market volatility
Timeframe: 1+ years
```

### Balanced Approach (Medium Risk)

```
1. Lock 50% for 90-180 days (2-3× multiplier)
2. Keep 50% unlocked for flexibility
3. Moderate referral activity
4. Target: 7,500-15,000% blended APY

Risk: Moderate penalty if unstaking during stress
Timeframe: 3-12 months
```

### Flexible Yield (Lower Risk)

```
1. No locks (1× base APY)
2. Can unstake anytime (subject to queue + penalty)
3. Minimal referral focus
4. Target: 2,000-8,000% APY

Risk: Lower returns, still subject to unstake penalties
Timeframe: 1-6 months
```

## Common Questions

**Q: When do I receive rebase rewards?**
A: Automatically every 8 hours. Your balance updates without any action.

**Q: Can I stake more ECHO later?**
A: Yes, stake additional ECHO anytime. Referral bonuses apply to each stake.

**Q: What if I need to unstake urgently?**
A: You can request unstake anytime, but will face queue (1-7 days) and penalty (0-75%) based on current backing ratio.

**Q: Do locked tokens still rebase?**
A: Yes, locked tokens rebase with the multiplier bonus. Lock 1,000 eECHO at 2× → rebases at double the base rate.

**Q: What happens if I miss a rebase?**
A: Nothing - rebases are automatic. Your balance grows whether you're online or not.

**Q: Can I transfer eECHO to another wallet?**
A: Yes, eECHO is transferable. However, locked eECHO cannot be transferred until unlocked.

## Safety Tips

1. **Verify URLs**: Only use official https://app.echoforge.xyz
2. **Check backing ratio**: Higher backing = healthier protocol
3. **Understand penalties**: Review unstake penalty before requesting
4. **Start small**: Test with small amount first
5. **Don't lock more than you can afford to lose**: Early unlock is expensive

## Next Steps

- **Learn mechanisms**: Read [Mechanisms](./mechanisms/) docs
- **Understand math**: Review [Mathematics](./mathematics.md) formulas
- **Join community**: Discord for updates and support
- **Track treasury**: Monitor backing ratio and runway

## Support

- **Documentation**: https://docs.echoforge.xyz
- **Discord**: https://discord.gg/echoforge
- **Twitter**: https://twitter.com/EchoForgeDAO

---

*Last updated: November 2025*
