# EchoForge FAQ

Frequently Asked Questions covering all aspects of the EchoForge protocol.

---

## General Questions

### What is EchoForge?

EchoForge is a DeFi protocol on Arbitrum featuring:
- **ECHO token** with adaptive transfer tax
- **eECHO rebasing token** with dynamic APY (0-30,000%)
- **Fair-launch bonding curve** for distribution
- **10-level referral system** for growth
- **Stake-based governance** for protocol control
- **Treasury backing** with automatic buybacks

**Goal**: Sustainable high yields backed by real treasury assets.

### Why should I trust EchoForge?

- **100% fair launch** (no presale, no team allocation)
- **Open source code** (verified on Arbiscan)
- **Professional audits** (planned/completed)
- **Treasury-backed** (every ECHO has real value)
- **Automatic safeguards** (dynamic APY, penalties, buybacks)
- **Community governance** (DAO controlled)

### How is the dynamic APY system sustainable?

The APY ranges from 0-30,000% based on treasury backing ratio.

**How it works**:
1. **200% backing** → 30,000% APY (maximum rewards)
2. **100% backing** → 5,000% APY (healthy baseline)
3. **90% backing** → 3,500% APY (gradual decline)
4. **70% backing** → 2,000% APY (knife catch zone)
5. Below 70% → APY continues scaling down

**Key**: APY automatically adjusts based on treasury health, creating sustainable rewards aligned with backing.

---

## Getting Started

### How do I buy ECHO?

**During Bonding Curve Phase**:
1. Connect wallet to app.echoforge.xyz
2. Go to "Buy" page
3. Choose payment token (ETH, USDC, USDT, DAI)
4. Enter amount
5. Confirm transaction
6. Receive ECHO instantly

**After Bonding Curve**:
- Buy on DEXs (Uniswap, Sushiswap)
- ECHO/ETH pairs
- Market-driven pricing

### What wallet should I use?

**Recommended**:
- **Ledger** (hardware - most secure)
- **Trezor** (hardware - most secure)
- **MetaMask** (software - most popular)
- **Rainbow** (software - mobile friendly)

**Requirements**:
- Supports Arbitrum network
- Can interact with dApps
- You control private keys

### What network is EchoForge on?

**Arbitrum One** (Layer 2)

**Why Arbitrum?**:
- Low gas fees (<$0.01 typically)
- Fast transactions
- Ethereum security
- Growing ecosystem
- GMX/GLP availability

**To Add Arbitrum**:
- Network: Arbitrum One
- Chain ID: 42161
- RPC: https://arb1.arbitrum.io/rpc
- Explorer: https://arbiscan.io

### Do I need ETH on Arbitrum?

**Yes**, for gas fees:
- Staking: ~$0.01-0.05
- Unstaking: ~$0.01-0.05
- Claiming: ~$0.01
- Transfers: ~$0.005

**How to Get**:
- Bridge from Ethereum mainnet
- Buy on exchange and withdraw to Arbitrum
- Use fiat on-ramp (some support Arbitrum directly)

---

## Staking Questions

### How does staking work?

1. **Stake ECHO** → Receive eECHO (1:1 initially)
2. **eECHO rebases** every 8 hours (balance grows)
3. **Referral relationship** recorded on-chain
4. **Earn rewards** automatically (no claiming needed)
5. **Unstake anytime** (subject to penalty and queue time)

### When do I receive rewards?

**Every 8 hours automatically**:
- 12:00 AM UTC
- 8:00 AM UTC
- 4:00 PM UTC

**No claiming needed** - your eECHO balance just increases.

### Do I have to compound?

**No!** eECHO automatically compounds.

**Traditional Staking**:
- Earn rewards
- Must claim
- Must compound
- Pay gas each time

**eECHO (Rebasing)**:
- Balance grows automatically
- No claiming
- No compounding
- No gas fees
- Set and forget

### Can I unstake anytime?

**Yes, but**:
1. **Redemption queue** (0-10 days based on backing)
2. **Dynamic penalty** (0-75% based on backing)
3. **Formula**: Queue = 10 × (120% - β) / 50%

**Best time to unstake**:
- When backing ≥120% (0% penalty)
- When you need funds
- After reaching goals

**Avoid unstaking**:
- When backing <95% (high penalty)
- During market panic
- If you can wait for better conditions

### What is the unstake penalty?

**Ranges from 0% to 75%** based on treasury backing:

| Backing | Penalty | Example (10K unstake) |
|---------|---------|----------------------|
| ≥120% | 0% | Receive 10,000 ECHO |
| 100% | 21.4% | Receive 7,860 ECHO |
| 85% | 37.5% | Receive 6,250 ECHO |
| 70% | 53.6% | Receive 4,640 ECHO |
| 50% | 75% | Receive 2,500 ECHO |

**Penalty Distribution**:
- 50% burned (deflationary)
- 50% to treasury (protocol sustainability)

**Why?**:
- Protects treasury during stress
- Prevents bank runs
- Rewards long-term holders

---

## Referral Questions

### How do referrals work?

**When someone uses your link to stake**:
1. They become your direct referral (Level 1)
2. You earn 4% of their stake in eECHO (instant)
3. Your eECHO rebases alongside their stake
4. When they refer others, you earn from levels 2-10
5. Protected by transfer tax (gaming is unprofitable)

**10 Levels Deep**:
- L1: 4%
- L2: 2%
- L3-L10: 1% each
- Total possible: 11% from full tree

### How do I get my referral link?

**Simple format**:
```
https://app.echoforge.xyz?ref=YOUR_WALLET_ADDRESS
```

**Example**:
```
https://app.echoforge.xyz?ref=0x1234567890abcdef1234567890abcdef12345678
```

**Share**:
- Social media
- Discord/Telegram
- YouTube/content
- Friends and family

### How are referral bonuses paid?

- **Currency**: eECHO tokens
- **Timing**: Instant (when downline stakes)
- **Delivery**: Directly to your wallet
- **Action needed**: None, automatic
- **Rebasing**: Your bonus rebases alongside their stake

**Example**:
```
Your L1 referral stakes: 10,000 ECHO
You instantly receive: 400 eECHO (4%)
This eECHO rebases as their stake grows
Protected by transfer tax
```

### Can I change my referrer?

**No** - referral relationships are permanent.

**Choose carefully**:
- Use trusted referrer's link
- Or use no referrer (allowed)
- Cannot change later

**Why permanent?**:
- Prevents gaming system
- Ensures stable tree structure
- Protects referrer's investment in helping you

### How does referral tracking work without NFTs?

**Referrals are recorded on-chain**:
- Your address linked to referrer's address
- Permanent relationship stored in contract
- No NFT needed for tracking
- Rewards distributed automatically

**Governance is stake-based**:
- Voting power = staked amount
- No tiers or NFT-based multipliers
- Direct democracy based on holdings
- Simple and transparent

### Can referrals be gamed?

**No, protected by design**:

1. **Transfer tax (4-15%)**: Moving tokens to game system is expensive
2. **eECHO rebasing**: Rewards tied to actual stake performance
3. **On-chain verification**: All relationships permanently recorded
4. **No NFT trading**: Can't buy/sell referral positions

**Result**: Gaming referrals costs more than honest participation.

---

## Tokenomics Questions

### What's the difference between ECHO and eECHO?

**ECHO**:
- Main protocol token
- Fixed balance (doesn't grow)
- 4-15% transfer tax
- Used for buying, selling, transfers
- ERC20 standard

**eECHO**:
- Staking/rebasing token
- Balance grows every 8 hours
- No transfer tax (stakers whitelisted)
- Represents your staked position
- ERC20 with elastic supply

**Relationship**:
- Stake ECHO → Get eECHO (1:1)
- eECHO rebases → Balance increases
- Unstake eECHO → Get ECHO (1:1, minus penalty)

### Why does ECHO have a transfer tax?

**Purpose**:
- Discourages selling (especially when staking is low)
- Incentivizes staking (stakers are whitelisted)
- Funds treasury with mixed assets (ECHO + ETH)
- Improves backing ratio through ETH acquisition

**Tax Rate** (4-15%):
- Low when staking is high (4%)
- High when staking is low (15%)
- Automatically adjusts based on staking ratio

**Tax Distribution**:
- **On all transfers**: 50% ECHO kept, 50% swapped to ETH (both to treasury)
- **Triggers when**: >1000 ECHO accumulated

**Whitelisted** (no tax):
- Staking contract
- Treasury
- Bonding curve
- Approved DEXs (for liquidity operations)

### How does the bonding curve work?

**Formula**:
```
price = $0.01 × (1 + supply/max_supply)²
```

**Example**:
- 0 ECHO sold: $0.01
- 250K sold: $0.0156
- 500K sold: $0.0225
- 1M sold: $0.04

**Properties**:
- Exponential growth
- Rewards early buyers
- 100% to treasury
- Fair distribution
- Transparent pricing

### What is backing ratio?

**Definition**:
```
backing_ratio = total_treasury_value / total_ECHO_supply
```

**Example**:
```
Treasury: $2,000,000
Supply: 1,000,000 ECHO
Backing: $2.00 per ECHO
= 200% (if price is $1.00)
```

**Importance**:
- Affects rebase rate (dynamic APY)
- Affects unstake penalty
- Shows protocol health
- Guides buyback engine

**Targets**:
- <80%: Critical
- 80-100%: Stressed
- 100-150%: Healthy
- >150%: Excellent

### Does ECHO have a max supply or hard cap?

**No - ECHO has an elastic supply model with no hard cap.**

**Initial Supply**:
- 1,000,000 ECHO minted via bonding curve (fair launch)
- 100% to public, 0% team allocation

**Supply Expansion** (Inflationary):
1. **eECHO Rebasing**: Mints new ECHO at 0-30,000% APY (based on backing ratio)
2. **Referral Rewards**: Protocol mints up to 14% of stake amount for referrals across 10 levels

**Supply Reduction** (Deflationary):
1. **Unstake penalties**: 50% of penalties burned (0-75% penalty based on backing)
2. **Transfer tax burns**: 50% of transfer tax burned
3. **Early unlock penalties**: Time-based penalties burned
4. **Buyback burns**: Treasury buybacks burned
5. **Manual burns**: Users can burn their ECHO

**Result**:
- Supply grows with protocol adoption through rebasing and referrals
- Deflationary mechanisms offset inflation
- Net supply depends on protocol activity and health
- This creates sustainable tokenomics aligned with treasury backing

---

## Economic Questions

### How does the dynamic APY system work?

**APY scales with backing ratio** (eECHO.sol lines 189-244):

```
200% backing → 30,000% APY
100% backing → 5,000% APY
90% backing → 3,500% APY (gradual drop)
70% backing → 2,000% APY (knife catch)
Below 70% → Continues scaling down
```

**Example**:
```
Current backing: 120%
Formula calculates: ~7,500% APY
Your stake grows at this rate
Adjusts automatically each rebase
```

**Why?**:
- Prevents death spiral
- Ensures sustainability
- Automatic adjustment
- Rewards high backing with high APY

### What prevents a death spiral?

**Multiple safeguards**:

1. **Dynamic APY**: Reduces emissions when backing low
2. **Unstake Penalty**: Discourages selling during stress (50% to treasury, 50% burned)
3. **Redemption Queue**: 0-10 days delays mass exits
4. **Buyback Engine**: Supports price floor
5. **Transfer Tax**: Funds treasury, discourages selling

**All automatic** - no governance needed.

**Result**: Protocol self-regulates to sustainable state.

### What is the buyback engine?

**Automatic price support**:

**Triggers when**:
- Price < 75% of 30-day average

**Process**:
1. Treasury detects low price
2. Swaps assets for ECHO on DEX
3. Burns purchased ECHO
4. Supports price, reduces supply

**Limits**:
- Max 5% of treasury per week
- Sustained support, not one-time

**Benefits**:
- Price floor protection
- Supply reduction
- Backing ratio improvement

### How long will high APY last?

**Dynamic based on backing**:

**Timeline expectations**:
- **High backing (>150%)**: 10,000-30,000% APY
- **Healthy backing (100-150%)**: 5,000-10,000% APY
- **Moderate backing (90-100%)**: 3,500-5,000% APY
- **Lower backing (70-90%)**: 2,000-3,500% APY

**Why it varies**:
- Directly tied to treasury backing ratio
- Not time-based degradation
- Maintains sustainability
- Rewards protocol health

**Key**: APY reflects real-time protocol health!

---

## Yield and Treasury Questions

### Where does the yield come from?

**Sources**:

1. **Bonding Curve Sales** (one-time):
   - 100% to treasury
   - Initial backing

2. **Transfer Taxes** (ongoing):
   - 4-15% of all transfers
   - 50% to treasury

3. **Treasury Yield** (ongoing):
   - GMX staking: 15-20% APY
   - GLP staking: 20-30% APY
   - Average: ~20% APY

4. **Protocol Fees** (future):
   - Potential additional revenue

### What does the treasury invest in?

**Target Allocation**:
```
30% Liquid (ETH, Stables)
├── Emergency reserves
├── Buyback capacity
└── Operational needs

60% Yield Strategies
├── 40% GLP (20-30% APY)
├── 15% GMX (15-20% APY)
└── 5% Aave (3-8% APY)

10% ECHO
└── Buyback reserve
```

**All DAO approved** strategies only.

### Who controls the treasury?

**Multi-Sig (5 of 7)**:
- 2 core team
- 2 community elected
- 2 technical advisors
- 1 legal/compliance

**Powers**:
- Approve yield strategies
- Execute buybacks
- Withdraw for operations
- Emergency measures

**Cannot**:
- Steal funds
- Mint ECHO
- Bypass timelock
- Unilateral actions

**Eventually**: Full DAO governance.

### How can I verify treasury holdings?

**All on-chain**:
- View multi-sig address on Arbiscan
- See all holdings
- Track all transactions
- Verify yield positions

**Dashboard** (app.echoforge.xyz):
- Real-time treasury value
- Asset breakdown
- Backing ratio
- Historical data

**Monthly Reports**:
- Detailed breakdown
- Yield performance
- Changes explained

---

## Lock Tier Questions

### What are lock tiers?

**Optional time-locks** for bonus multipliers:

| Duration | Multiplier | Benefits |
|----------|-----------|----------|
| 30 days | 1.2× | All rewards × 1.2 |
| 90 days | 2× | All rewards × 2 |
| 180 days | 3× | All rewards × 3 |
| 365 days | 4× | All rewards × 4 |

**Applies to**:
- Rebase rewards
- Referral bonuses
- Pool share
- Everything!

### Should I lock my tokens?

**Pros**:
- Massive multiplier bonuses
- Maximize earnings
- Commitment shows conviction
- Potential tier progression

**Cons**:
- 90% penalty for early unlock
- Cannot access for duration
- Opportunity cost
- Market changes

**Consider**:
- Your time horizon
- Liquidity needs
- Risk tolerance
- Conviction level

**Strategy**: Lock amount you won't need.

### Can I unlock early?

**Yes, with time-based penalty**:

**Penalty decreases over time**:
- Formula: 90% - (80% × timeServed / totalDuration)
- Start: 90% penalty
- End: 10% penalty
- Linear decline throughout lock

**Examples**:
```
365-day lock, unlocked at day 183 (50%):
Penalty = 90% - (80% × 0.5) = 50%

365-day lock, unlocked at day 274 (75%):
Penalty = 90% - (80% × 0.75) = 30%
```

**Better**:
- Only lock amount you can afford
- Keep some unlocked
- Plan for contingencies

### Can I extend my lock?

**Yes!** Can upgrade to higher tier:
- 30d → 90d, 180d, or 365d
- 90d → 180d or 365d
- 180d → 365d

**Cannot**:
- Reduce duration
- Unlock without penalty
- Change to lower tier

**Why extend?**:
- Gain higher multiplier
- New unlock date starts
- Maximize long-term gains

---

## Technical Questions

### Are the contracts audited?

**Status**: Pending

**Planned**:
- CertiK (Tier 1 auditor)
- Trail of Bits
- OpenZeppelin

**When**:
- Q1 2024: First audit
- Q2 2024: Follow-up
- Ongoing: Bug bounty

**Current**:
- Internal security review
- Automated testing
- Community review
- Best practices followed

### Are contracts upgradeable?

**No** - completely immutable.

**Pros**:
- Maximum decentralization
- No rug pull possible
- Code is final
- Trust minimized

**Cons**:
- Cannot fix bugs easily
- Must deploy new versions
- Less flexible

**Mitigation**:
- Extensive testing
- Multiple audits
- Bug bounty program
- Insurance vault

### Can I see the code?

**Yes!** Fully open source:

**GitHub**: [Repository URL]
**Arbiscan**: All contracts verified
**Documentation**: Detailed inline comments

**Check**:
- Contract addresses in docs
- Verify on Arbiscan
- Review before using
- Ask questions in Discord

### What if there's a bug?

**Report it**:
- security@echoforge.xyz
- Bug bounty rewards
- Responsible disclosure

**Protocol Response**:
1. Assess severity
2. Develop fix
3. Deploy solution
4. Compensate affected (if possible)
5. Transparent communication

**Insurance Vault**:
- Exists for emergencies
- Community controlled
- Last resort option

---

## Misc Questions

### How do I get support?

**Channels**:
- **Discord**: [Link] - fastest response
- **Telegram**: [Link] - community chat
- **Twitter**: @EchoForge - announcements
- **Email**: support@echoforge.xyz

**Documentation**:
- Full docs at /docs
- Video tutorials
- Community guides

**Common Issues**:
- Search Discord first
- Read FAQ (you're here!)
- Ask in #support channel

### Is EchoForge a Ponzi scheme?

**No**:
- All funds backed by treasury
- Transparent operations
- Sustainable model
- Automatic safeguards
- Open source code

**Key Differences**:
- Ponzi uses new money to pay old
- EchoForge pays from treasury yield
- Backing ratio maintained
- Dynamic APY ensures sustainability

**Still risky**:
- DeFi has risks
- Smart contracts can have bugs
- Markets can crash
- Only invest what you can afford to lose

### Can I lose money?

**Yes, multiple ways**:

1. **Price drops**: ECHO value decreases
2. **Unstake penalty**: Up to 75% if backing low
3. **Early unlock**: 90% penalty
4. **Smart contract bug**: Potential exploit
5. **Treasury drain**: Backing below value
6. **Opportunity cost**: Better opportunities elsewhere

**Mitigation**:
- Understand risks
- Start small
- Only invest what you can lose
- Monitor backing ratio
- Use hardware wallet
- Verify contracts

### Is this legal?

**Decentralized Protocol**:
- No company
- No central control
- Permissionless
- Smart contracts

**Your Responsibility**:
- Know your local laws
- Consult tax advisor
- Report crypto gains
- Understand regulations

**We Cannot**:
- Provide legal advice
- Guarantee legality in your jurisdiction
- Take responsibility for your compliance

### How do I report taxes?

**Not financial advice, but**:

**Track**:
- All ECHO purchases (cost basis)
- Staking rewards (income?)
- Referral bonuses (income?)
- Sales and unstakes (capital gains?)
- Transfer between wallets (not taxable?)

**Tools**:
- Koinly
- CoinTracker
- TokenTax

**Consult**:
- Tax professional
- Especially for large amounts
- Laws vary by jurisdiction

---

## Troubleshooting

### My transaction failed. Why?

**Common Causes**:
1. **Insufficient gas**: Add more ETH to wallet
2. **Slippage**: Increase slippage tolerance
3. **No approval**: Must approve tokens first
4. **Cooldown not met**: Wait for timelock
5. **Contract paused**: Check announcements

**Check**:
- Error message in wallet
- Transaction on Arbiscan
- Gas price settings
- Approval status

### I don't see my eECHO in wallet

**Add Custom Token**:
1. Copy eECHO contract address
2. Wallet → Add Token
3. Paste address
4. eECHO should appear

**Still not showing?**:
- Check correct network (Arbitrum)
- Verify you actually staked
- Check transaction status
- Contact support

### How do I verify my referral relationship?

**Check on-chain**:
- View contract on Arbiscan
- Query your address
- See referrer address
- Verify referral count

**Dashboard shows**:
- Your referrer (if any)
- Direct referrals count
- Total referral rewards earned
- Current APY based on backing

### Rebase didn't increase my balance

**Check**:
- Correct time (every 8 hours)
- Backing ratio (0% dampener = no rebase)
- Your eECHO balance (not ECHO)
- Recent rebase events

**If APY is very low**:
- Backing ratio is low
- Wait for backing to recover
- APY will increase automatically
- Balance still preserved

---

## More Questions?

**Join the Community**:
- Discord: [Link]
- Telegram: [Link]
- Twitter: @EchoForge

**Read the Docs**:
- Getting Started Guide
- Protocol Overview
- Technical Documentation

**Contact Support**:
- support@echoforge.xyz
- Response within 24-48 hours

---

EchoForge - Building sustainable DeFi yields backed by real treasury assets.
