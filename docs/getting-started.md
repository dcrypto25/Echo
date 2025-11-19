# Getting Started with EchoForge

Welcome to EchoForge, a next-generation DeFi protocol featuring an exponential bonding curve, adaptive tax system, and innovative staking mechanics with up to 30,000% APY.

## What is EchoForge?

EchoForge is a decentralized finance protocol built on Arbitrum that combines:

- **ECHO Token**: Main protocol token with adaptive transfer tax (4-15%)
- **eECHO Token**: Rebasing staking token that grows your balance automatically
- **Stake-Based Governance**: Voting power proportional to staked amount
- **10-Level Referral System**: Earn eECHO from your referrals' stakes
- **Treasury Backing**: 100%+ backing with automatic buyback engine

The protocol uses a fair-launch bonding curve and innovative game theory to create sustainable rewards while maintaining treasury health.

---

## Step 1: Connect Your Wallet

### Supported Wallets
- MetaMask
- WalletConnect
- Coinbase Wallet
- Rainbow Wallet

### Network Setup
**Network**: Arbitrum One
**Chain ID**: 42161
**RPC URL**: https://arb1.arbitrum.io/rpc

1. Visit [EchoForge App](https://app.echoforge.xyz)
2. Click "Connect Wallet" in the top right
3. Select your wallet provider
4. Approve the connection
5. Ensure you're connected to Arbitrum network

---

## Step 2: Buy ECHO via Bonding Curve

The bonding curve is the only way to acquire ECHO during the initial phase.

### How the Bonding Curve Works

The price follows an exponential formula:
```
price = $0.01 × (1 + supply/max_supply)²
```

This means:
- **Early buyers** get the best price (starting at $0.01)
- **Price increases** as more ECHO is purchased
- **Fair launch** - no pre-sale, no insider allocation
- **Initial bonding curve** mints 1,000,000 ECHO
- **Elastic supply** - additional ECHO minted through rebasing (eECHO) and referral rewards (up to 14% per stake)

### Accepted Payment Tokens
- ETH (Ethereum)
- WETH (Wrapped Ethereum)
- USDC (USD Coin)
- USDT (Tether)
- DAI (Dai Stablecoin)

### Purchase Process

1. Navigate to the "Buy" page
2. Select your payment token
3. Enter the amount you want to spend
4. Review the ECHO amount you'll receive
5. Click "Buy ECHO"
6. Approve the token spending (if using ERC20)
7. Confirm the transaction in your wallet

**Anti-Bot Protection**: During the first 24 hours, purchases are limited to 10,000 ECHO per transaction to ensure fair distribution.

### Price Discovery

Check current price anytime:
- View "Current Price" on the Buy page
- See the bonding curve chart showing price trajectory
- Total ECHO sold is displayed publicly

---

## Step 3: First Time Staking

Staking converts your ECHO into eECHO (rebasing token) and begins earning dynamic APY rewards.

### Benefits of Staking

1. **Dynamic APY (0-30,000%)**: Scales with treasury backing
   - 200% backing → 30,000% APY
   - 100% backing → 5,000% APY
   - 90% backing → 3,500% APY
   - 70% backing → 2,000% APY
2. **Earn Rebases**: Balance grows every 8 hours
3. **Voting Power**: Governance participation based on stake
4. **Referral Bonuses**: Earn eECHO from referrals' stakes (4% of L1)
5. **Lower Tax**: Whitelisted addresses pay no transfer tax

### How to Stake

1. Navigate to the "Stake" page
2. Enter the amount of ECHO to stake
3. (Optional) Enter a referrer's address
4. Click "Stake ECHO"
5. Approve ECHO spending
6. Confirm the transaction

**What Happens:**
- Your ECHO is converted to eECHO (1:1 initially)
- Your referral relationship is recorded on-chain
- If you used a referrer, they receive 4% of your stake as eECHO
- You start earning rebase rewards immediately

### Understanding eECHO

eECHO is a rebasing token that grows your balance automatically:

- **Rebases every 8 hours** (3 times per day)
- **Balance increases** based on dynamic APY linked to backing
  - 200% backing = 30,000% APY
  - 100% backing = 5,000% APY
  - 90% backing = 3,500% APY (gradual decline zone)
  - 70% backing = 2,000% APY (knife catch zone)
- **Always redeemable 1:1** for ECHO (minus unstake penalty if applicable)

---

## Step 4: Setting Up Your Referral Link

Once you've staked, you can earn from referrals.

### Creating Your Referral Link

Your referral link uses your wallet address:
```
https://app.echoforge.xyz?ref=YOUR_WALLET_ADDRESS
```

Example:
```
https://app.echoforge.xyz?ref=0x1234567890abcdef1234567890abcdef12345678
```

### How Referrals Work

When someone stakes using your link:

1. **They get** you as their referrer (recorded on-chain)
2. **You earn** 4% of their stake as eECHO instantly
3. **Your eECHO** rebases alongside their stake
4. **They can** build their own referral network

### Referral Bonus Structure

You earn bonuses from **10 levels** of referrals:

| Level | Bonus Rate | Example (on $1000 stake) |
|-------|-----------|-------------------------|
| L1 (Direct) | 4% | $40 |
| L2 | 2% | $20 |
| L3-L10 | 1% each | $10 each |

**Maximum**: Up to 11% total from a full referral tree

**Bonuses are**:
- Paid in eECHO tokens
- Sent automatically when downline stakes
- Rebase alongside referee's stake
- Protected by transfer tax (gaming is unprofitable)

### Sharing Your Link

Best practices:
- Share on social media (Twitter, Discord, Telegram)
- Create tutorial content with your link
- Explain the protocol benefits
- Build a community around your referral tree

---

## Next Steps

Now that you're set up:

1. **Check Dashboard**: Monitor your eECHO balance growth
2. **Claim/Compound**: Decide when to claim rewards or compound
3. **Build Referrals**: Share your link and grow your tree
4. **Lock Tokens**: Consider locking for multiplier bonuses
5. **Join Community**: Discord, Twitter, Telegram for updates

---

## Quick Tips

### Maximize Your Returns
- Lock your eECHO for higher multipliers
- Build a strong referral network
- Compound frequently for exponential growth
- Monitor treasury backing for optimal unstaking

### Understand the Risks
- **Dynamic APY**: Ranges from 0-30,000% based on treasury backing
- **Unstake Penalty**: 0-75% based on treasury health (50% to treasury, 50% burned)
- **Lock Penalty**: 90% declining to 10% over lock duration (time-based)
- **Redemption Queue**: 0-10 days based on backing ratio
- **Market Risk**: Price can fluctuate on secondary markets

### Stay Informed
- Treasury backing ratio (aim for >100%)
- Current APY and rebase rate
- Next rebase countdown
- Your referral tree performance

---

## Common Questions

**Q: When do I receive rebase rewards?**
A: Every 8 hours, automatically added to your eECHO balance.

**Q: Can I unstake anytime?**
A: Yes, but there's a 0-10 day redemption queue (based on backing) and potential 0-75% penalty.

**Q: How do referral bonuses work?**
A: You receive 4% of your L1 referral's stake as eECHO, which rebases alongside their stake.

**Q: How does governance work?**
A: Voting power is proportional to your staked amount - more stake equals more influence.

**Q: Can I stake more ECHO later?**
A: Yes, additional stakes add to your existing position.

---

## Need Help?

- **Documentation**: Read the full docs at `/docs`
- **Discord**: Join our community discord
- **Twitter**: Follow @EchoForge for updates
- **Support**: support@echoforge.xyz

Welcome to the EchoForge ecosystem!
