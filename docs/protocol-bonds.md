# Protocol Bonds - Continuous Treasury Building

**OHM-style bonding mechanism for ongoing treasury growth**

---

## Overview

Protocol Bonds allow users to exchange assets (ETH, stablecoins) for ECHO, while continuously building the protocol treasury with diverse backing assets.

**Key Features:**
- 🎁 **Two pricing modes**: Fixed price OR 5% discount on market
- ⏱️ **5-day vesting** period
- 💰 **Multiple assets accepted**: ETH, USDC, USDT, DAI
- 🏦 **100% to treasury** - strengthens backing
- ⚡ **Active from day 1** - Available immediately at launch

**Pricing Modes:**
1. **Fixed Price Mode** (Launch): $0.015/ECHO (same as bonding curve final price)
2. **Oracle Mode** (Post-DEX): Market price - 5% discount

---

## How It Works

### **Simple Flow:**

```
1. User deposits $100 USDC
2. Protocol calculates ECHO value at market price + 5% discount
3. User receives eECHO (vested for 5 days)
4. Treasury receives $100 USDC
5. After 5 days, user can claim/unstake eECHO
```

### **Example:**

**Market Conditions:**
- ECHO price: $0.02/token
- User deposits: $100 USDC

**Calculation:**
```
Market rate: $100 / $0.02 = 5,000 ECHO
With 5% discount: 5,000 × 1.05 = 5,250 ECHO
Vesting: 5 days
```

**Result:**
- User gets: 5,250 eECHO (claimable in 5 days)
- Treasury gets: $100 USDC
- User saves: $5 vs buying on DEX + gas fees

---

## Why Bond Instead of Buying on DEX?

| Method | Cost | Time | Benefits |
|--------|------|------|----------|
| **Buy on DEX** | $100 + 0.3% fees + gas | Instant | Immediate liquidity |
| **Protocol Bond** | $100 (5% discount) | 5 days | Lower price, helps treasury |

**Bond Advantages:**
- ✅ 5% cheaper than market
- ✅ No DEX fees or slippage
- ✅ Supports protocol treasury
- ✅ Get eECHO (rebasing)

**DEX Advantages:**
- ✅ Instant liquidity
- ✅ No vesting wait

**Best for:**
- 💎 Long-term holders → **Bond** (save 5%, get rebasing eECHO)
- 🔄 Active traders → **DEX** (need instant liquidity)

---

## Accepted Assets

| Asset | Discount | Min Deposit | Notes |
|-------|----------|-------------|-------|
| **ETH** | 5% | 0.01 ETH | Native asset, best for treasury |
| **USDC** | 5% | $10 | Stablecoin backing |
| **USDT** | 5% | $10 | Stablecoin backing |
| **DAI** | 5% | $10 | Stablecoin backing |

**All bonds:**
- 5-day vesting period
- Receive eECHO (rebasing token)
- 100% proceeds to treasury

---

## Launch Strategy

### **Phase 1: Fixed Price Mode (Day 1 - DEX Launch)**
```
Status: Protocol Bonds ACTIVE @ $0.015
Bonding Curve: Also active @ $0.0003 → $0.015
Strategy: Two ways to buy, sellers must provide LP

Why $0.015 fixed price?
- Matches bonding curve final price
- Fair for all participants
- Simple and transparent
- No discount confusion
```

**User Options:**
```
Want to buy ECHO?
├── Bonding Curve: $0.0003 → $0.015 (instant)
└── Protocol Bonds: $0.015 (5-day vest, get eECHO)

Want to sell ECHO?
└── Must create DEX liquidity (organic LP!)
```

### **Phase 2: Oracle Mode (Post-DEX Launch)**
```
Status: Protocol Bonds ACTIVE @ Market - 5%
DEX: Price discovery via oracle
Strategy: Bonds give 5% discount vs DEX

When to switch?
- After DEX has stable liquidity
- Oracle deployed and tested
- Usually 1-2 weeks after bonding curve completes
```

**User Options:**
```
Want to buy ECHO?
├── DEX: Market price (instant)
└── Protocol Bonds: Market - 5% (5-day vest, discount!)

Want to sell ECHO?
└── DEX (instant liquidity)
```

---

## Treasury Impact

### **Bonding Curve Only (No Protocol Bonds):**

| Timeframe | Treasury Value | Sources |
|-----------|---------------|---------|
| Launch | $9,500 | Bonding curve |
| Month 6 | $15,000 | Tax + yield |
| Year 1 | $25,000 | Tax + yield |

### **With Protocol Bonds:**

| Timeframe | Treasury Value | Sources |
|-----------|---------------|---------|
| Launch | $9,500 | Bonding curve |
| Month 6 | $50,000 | Tax + yield + **$30k bonds** |
| Year 1 | $150,000 | Tax + yield + **$100k bonds** |

**Bonds dramatically accelerate treasury growth!**

---

## Use Cases

### **For Users:**

**Long-term Holder:**
```
Goal: Accumulate ECHO at best price
Strategy: Bond $500 USDC monthly
Benefit: Save 5% vs DEX + support protocol
Result: Lower cost basis, stronger backing ratio
```

**Yield Farmer:**
```
Goal: Maximize returns
Strategy: Bond during high APY periods
Benefit: 5% discount + rebasing rewards
Result: Higher total returns than DEX buying
```

**Treasury Maximalist:**
```
Goal: Strengthen protocol backing
Strategy: Bond ETH when backing < 100%
Benefit: Help treasury + get discounted ECHO
Result: Improved backing ratio for all holders
```

### **For Protocol:**

**Diversified Treasury:**
```
Before bonds: $9,500 in ETH/stables (from bonding curve)
After 6 months: $50,000 in mixed assets
  - $15k ETH
  - $20k USDC/USDT/DAI
  - $10k from tax revenue
  - $5k yield earnings
```

**Stronger Backing:**
```
Without bonds:
- Treasury: $15k
- Market cap: $200k
- Backing: 7.5%

With bonds:
- Treasury: $50k
- Market cap: $200k
- Backing: 25%
```

---

## Technical Details

### **Vesting Mechanism:**

**When you bond:**
1. Protocol mints ECHO for your bond
2. ECHO is wrapped to eECHO
3. eECHO is locked in contract
4. After 5 days, you can claim

**During vesting:**
- ✅ eECHO balance visible on-chain
- ✅ Rebases accumulate (you earn yield while vesting!)
- ❌ Cannot transfer or sell
- ❌ Cannot unstake to ECHO

**After vesting:**
- ✅ Claim eECHO to your wallet
- ✅ Unstake to ECHO anytime
- ✅ Transfer or sell freely

### **Price Oracle:**

Protocol uses price oracle to determine bond rates:

**Price Sources (in order of priority):**
1. Chainlink ECHO/USD oracle (if available)
2. TWAP from ECHO-ETH Uniswap pool
3. Fallback: Bonding curve final price ($0.015)

**5% Discount Applied:**
```solidity
marketPrice = getECHOPrice();  // e.g., $0.02
bondPrice = marketPrice * 0.95; // $0.019
echoAmount = depositValue / bondPrice;
```

---

## Security Features

**Protections:**
- ✅ Reentrancy guards on all functions
- ✅ Vesting prevents instant dumps
- ✅ Owner cannot withdraw user funds
- ✅ Emergency pause for bonds
- ✅ All deposits go directly to treasury

**Limitations:**
- ⏱️ Bonds activate 1 week after curve completes (not instant)
- 🔒 5-day vesting (cannot claim early)
- 💰 No refunds once bond is created
- 📊 Bond prices depend on market oracle

---

## FAQ

### Why 5% discount instead of higher?

**5% is optimal:**
- High enough to incentivize bonding over DEX
- Low enough to prevent exploitation
- Covers DEX fees + slippage + gas
- Sustainable for protocol long-term

Higher discounts (10-15%) were common in OHM but led to:
- Mercenary capital (bond → dump immediately)
- Unsustainable treasury drain
- Negative price pressure

### What if ECHO price drops during vesting?

**You're protected by the discount:**

```
Example:
- Bond at $0.02 with 5% discount → effective price $0.019
- Price drops to $0.018 during vesting
- You still get 5,250 ECHO worth $94.50
- You "lost" $5.50 vs waiting, but gained from rebasing

If price rises:
- Bond at $0.02 → effective price $0.019
- Price rises to $0.025 during vesting
- You get 5,250 ECHO worth $131.25
- You gained $31.25!
```

**Plus:** eECHO rebases during vesting, so you earn yield while waiting!

### Can I bond LP tokens?

**Not in v1.0**, but planned for v2.0:

Potential LP bonding:
- Bond ECHO-ETH LP tokens
- Get 5% discount
- Treasury owns protocol-owned liquidity (POL)
- Reduced dependency on mercenary liquidity

### How do bonds affect tokenomics?

**Supply Expansion:**
- Bonds mint new ECHO (inflationary)
- Similar to rebasing rewards
- Difference: Treasury gets valuable assets in return

**Net Effect:**
```
User bonds $100 USDC
- Supply increases: +5,000 ECHO
- Treasury increases: +$100
- Backing per token: +$0.02/ECHO

This is healthy inflation (backed by assets)
```

---

## Comparison to OlympusDAO

| Feature | OlympusDAO Bonds | EchoForge Bonds |
|---------|------------------|-----------------|
| **Discount** | 5-15% (variable) | 5% (fixed) |
| **Vesting** | 5 days | 5 days |
| **Assets** | DAI, FRAX, LP tokens | ETH, USDC, USDT, DAI |
| **Activation** | Immediate | 1 week after curve |
| **Token Received** | OHM | eECHO (rebasing) |
| **Rebasing During Vest** | No | **Yes** ✅ |

**Key Improvement:** EchoForge bonds give eECHO which rebases during vesting, so you earn yield while waiting!

---

## Getting Started

### **Check Bond Availability:**

```javascript
// Check if bonds are active
const bondsActive = await protocolBonds.isBondsActive();

// Check time until activation
const timeLeft = await protocolBonds.timeUntilActivation();
```

### **Get Bond Quote:**

```javascript
// Quote for bonding $100 USDC
const quote = await protocolBonds.getBondQuote(
  100_000000, // $100 (6 decimals)
  USDC_ADDRESS
);
// Returns: { echoAmount, vestingEnd }
```

### **Create Bond:**

```javascript
// Bond USDC
await usdc.approve(protocolBonds.address, amount);
await protocolBonds.bondToken(USDC_ADDRESS, amount);

// Bond ETH
await protocolBonds.bondETH({ value: ethAmount });
```

### **Claim Bonds:**

```javascript
// Get claimable bonds
const claimable = await protocolBonds.getClaimableBonds(userAddress);

// Claim single bond
await protocolBonds.claimBond(bondId);

// Claim multiple bonds
await protocolBonds.claimBonds([bondId1, bondId2, bondId3]);
```

---

*Protocol Bonds are a key mechanism for sustainable treasury growth, inspired by OlympusDAO's innovations but improved with fixed discounts and rebasing during vesting.*

*Last updated: 2025-11-19*
