# EchoForge Documentation

Welcome to EchoForge, a next-generation DeFi protocol on Arbitrum featuring dynamic APY, sustainable tokenomics, and innovative staking mechanics.

## Overview

EchoForge is a treasury-backed DeFi protocol that combines:

- **Dynamic APY System**: 0-30,000% APY that scales with treasury backing
- **Exponential Bonding Curve**: Fair-launch token distribution
- **Rebasing Staking**: Automatic compounding via eECHO
- **10-Level Referral System**: Earn eECHO from referrals' stakes
- **Stake-Based Governance**: Democratic voting power
- **Treasury Backing**: 100%+ backing with automatic safeguards

## Core Features

### Dynamic APY (0-30,000%)

APY automatically adjusts based on treasury backing ratio:

- **200% backing** � 30,000% APY (maximum rewards)
- **100% backing** � 5,000% APY (healthy baseline)
- **90% backing** � 3,500% APY (gradual decline)
- **70% backing** � 2,000% APY (knife catch zone)
- **Below 70%** � Continues scaling down

This ensures sustainable rewards aligned with protocol health.

### ECHO & eECHO Tokens

**ECHO**: Main protocol token
- Adaptive transfer tax (4-15%)
- Auto-swap on all transfers (50% ECHO, 50% ETH to treasury, triggers at >$50 USD)
- Acquired via bonding curve or DEX
- Stakable for eECHO

**eECHO**: Rebasing staking token
- Balance grows every 8 hours automatically
- Dynamic APY based on backing
- Always redeemable 1:1 for ECHO
- No transfer tax for stakers

### Referral System

Earn eECHO from your referrals' stakes:

- **L1 (Direct)**: 4% of their stake as eECHO
- **L2**: 2% as eECHO
- **L3-L10**: 1% each as eECHO
- **Protected**: Transfer tax makes gaming unprofitable
- **Rebasing**: Your referral rewards rebase alongside their stake

### Governance

Stake-based governance system:
- Voting power proportional to staked amount
- No NFTs or tiers required
- Direct democracy
- Simple and transparent

## Key Mechanics

### Unstake Penalty

Exponential penalty curve (0-75%) based on treasury backing:

**Formula**: `penalty = 75% × ((120% - ratio) / 70%)²`

- **≥120% backing**: 0% penalty
- **100% backing**: 6.1% penalty
- **50% backing**: 75% penalty (maximum)

**Distribution**:
- 50% burned (deflationary)
- 50% to treasury (sustainability)

### Dynamic Unstake Cooldown

Cooldown period based on backing ratio:
- **Formula**: `cooldown = 1 day + 6 days × ((120% - ratio) / 70%)`
- **Range**: 1-7 days
- **≥120% backing**: 1 day
- **50% backing**: 7 days

## Lock Multipliers

Voluntarily lock eECHO for bonus rewards:

| Lock Duration | Multiplier | Example (100% backing) |
|--------------|-----------|------------------------|
| 30 days | 1.2� | 5,000% � 6,000% APY |
| 90 days | 2� | 5,000% � 10,000% APY |
| 180 days | 3� | 5,000% � 15,000% APY |
| 365 days | 4� | 5,000% � 20,000% APY |

## Getting Started

1. **Buy ECHO**: Via bonding curve or DEX
2. **Stake ECHO**: Receive eECHO (1:1 initially)
3. **Earn Rebases**: Balance grows every 8 hours
4. **Build Referrals**: Share your link, earn eECHO
5. **Optional Lock**: Multiply your rewards

## Documentation

- [Getting Started Guide](getting-started.md) - Onboarding walkthrough
- [Staking Guide](staking-guide.md) - Complete staking mechanics
- [FAQ](faq.md) - Frequently asked questions
- [Protocol Overview](protocol-overview.md) - Technical details
- [Referral System](referral-system.md) - Referral mechanics
- [Treasury](treasury.md) - Treasury management
- [Security](security.md) - Security features

## Protocol Health Indicators

Monitor these metrics:
- **Treasury Backing Ratio**: Target >100%
- **Current APY**: Reflects backing health
- **Unstake Cooldown**: Lower is better (1-7 days)
- **Unstake Penalty**: Lower is better (0-75%)

## Safety Mechanisms

1. **Dynamic APY**: Auto-adjusts to prevent death spirals
2. **Exponential Unstake Penalties**: Protect treasury during stress
3. **Dynamic Cooldown**: Prevents bank runs (1-7 days)
4. **Transfer Tax**: Discourages selling, funds treasury
5. **Buyback Engine**: Automatic price support

## Resources

- **Website**: [echoforge.xyz](https://echoforge.xyz)
- **App**: [app.echoforge.xyz](https://app.echoforge.xyz)
- **Discord**: [Community Discord]
- **Twitter**: [@EchoForge]
- **Documentation**: [docs.echoforge.xyz](https://docs.echoforge.xyz)

## Risk Disclosure

DeFi protocols carry inherent risks:
- Smart contract vulnerabilities
- Market volatility
- APY fluctuations based on backing
- Unstake penalties during stress
- Time-locked funds for multipliers

**Only invest what you can afford to lose.**

## Support

- **Documentation**: Read the full guides
- **Discord**: Join community support
- **Email**: support@echoforge.xyz

---

**EchoForge** - Dynamic, sustainable DeFi yields backed by real treasury assets.
