# What is EchoForge?

EchoForge is a reserve currency protocol on Arbitrum featuring an elastic supply model with treasury backing and self-regulating economic mechanisms.

## Core Concept

EchoForge introduces a rebasing token (eECHO) backed by a DAO-controlled treasury (Forge Reserve), where emissions automatically adjust to protocol health, preventing the death spirals that collapsed previous reserve currency experiments.

### Primary Goals

- **Treasury-Backed Value**: Every ECHO token backed by real protocol-owned assets
- **Self-Regulating Emissions**: APY responds dynamically to backing ratio (0-30,000%)
- **Sustainable Growth**: Multiple revenue streams fund long-term protocol sustainability
- **Decentralized Governance**: Community-controlled from genesis via DAO

### The Reserve Currency Thesis

Reserve currencies in DeFi serve as protocol-owned liquidity assets that other protocols can build upon. Unlike algorithmic stablecoins that target $1, reserve currencies aim to grow value while maintaining treasury backing.

**The Challenge**: Previous protocols like OlympusDAO demonstrated the concept but failed to prevent death spirals when emissions exceeded treasury capacity.

**EchoForge's Solution**: Dynamic economic parameters that automatically scale with protocol health, mathematically preventing the failure modes that destroyed predecessors.

## Key Mechanisms

### Dynamic APY System

APY automatically adjusts based on treasury backing ratio:

- **High backing (≥200%)**: Aggressive APY (18,000-30,000%) attracts capital
- **Healthy backing (100-150%)**: Moderate APY (5,000-12,000%) sustains growth
- **Low backing (<100%)**: Reduced APY (0-5,000%) protects treasury

This self-regulating system ensures emissions never exceed treasury capacity.

### Elastic Supply Model

The eECHO token uses elastic supply mechanics where user balances automatically increase through rebasing every 8 hours. This compound growth model provides exponential returns while maintaining proportional ownership.

### Treasury-Backed Security

The Forge Reserve backs every token with real assets:
- 60% productive yield-generating assets (GMX/GLP, Curve)
- 30% liquid reserves (ETH, stablecoins)
- 10% protocol tokens (ECHO)

Treasury yield (15-30% APY) provides sustainable revenue independent of token price.

### Multi-Layer Protection

EchoForge implements multiple mechanisms that work together to prevent death spirals:

1. **Dynamic APY**: Emissions scale with backing
2. **Transfer Tax**: Adaptive 4-15% tax funds treasury
3. **Unstake Penalties**: 0-75% exponential penalty protects during stress
4. **Redemption Queue**: 1-7 day cooldown prevents bank runs
5. **Buyback Engine**: Automatic price support below 75% TWAP

## How It Works

### For Users

1. **Acquire ECHO**: Purchase via DEX or bonding curve
2. **Stake**: Wrap ECHO to eECHO (1:1)
3. **Earn**: Balance grows automatically every 8 hours
4. **Lock** (optional): Lock tokens for 30-365 days for up to 4× multiplier
5. **Refer** (optional): Earn 4-14% of referee stakes across 10 levels
6. **Unstake**: Subject to dynamic penalties and queue based on backing ratio

### For the Protocol

Treasury continuously:
- Deploys assets to yield strategies (GMX, GLP, Aave)
- Collects transfer taxes and unstake penalties
- Executes buybacks when price falls below floor
- Adjusts APY based on backing ratio
- Maintains 100%+ backing ratio

## What Makes EchoForge Different

### vs. OlympusDAO

| Feature | OlympusDAO | EchoForge |
|---------|-----------|-----------|
| APY Model | Fixed 8,000% | Dynamic 0-30,000% |
| Death Spiral Protection | Minimal | 5 interlocking mechanisms |
| Treasury Yield | 5-10% | 15-30% |
| Bank Run Prevention | None | Penalties + queue + APY reduction |
| Backing at Peak | 100%+ | Target 100-150% |
| Result | -99.7% collapse | Mathematical sustainability |

### Key Innovations

**Self-Regulating Economics**:
- No manual intervention required
- Parameters adjust automatically to market conditions
- System finds natural equilibrium

**Compound Growth Formula**:
- Per-rebase rate: `(1 + APY)^(1/1095) - 1`
- Not linear division (APY/1095) that over-emitted in predecessors
- Mathematically correct compound calculations

**Real Yield Integration**:
- Treasury earns independent revenue from DeFi protocols
- Not dependent on new user deposits
- Sustainable even in bear markets

**Fair Launch**:
- No team allocation
- No pre-sale
- 100% community-owned from genesis
- Bonding curve ensures fair price discovery

## Use Cases

### Individual Participants

- **Long-term Holders**: Earn compounding returns on treasury-backed assets
- **Yield Farmers**: Capture high APY when backing ratio is strong
- **Network Builders**: Earn referral commissions building user network
- **DAO Contributors**: Govern protocol parameters and treasury allocation

### Protocol Integration

- **Collateral**: Use ECHO as collateral in lending protocols
- **Liquidity**: Protocol-owned liquidity for other projects
- **Reserve Asset**: Hold ECHO in DAO treasuries
- **Yield Source**: Earn APY on treasury holdings

## Getting Started

New to EchoForge? Start here:

1. **[Getting Started](./getting-started.md)**: Step-by-step guide for new users
2. **[Mechanisms](./mechanisms/)**: Detailed explanation of core systems
3. **[Mathematics](./mathematics.md)**: Complete formula specifications
4. **[Whitepaper](./whitepaper.md)**: Full technical and economic design

## Protocol Status

- **Network**: Arbitrum One
- **Launch**: Q1 2026
- **Status**: Pre-launch
- **Contracts**: Audited by Hackensight, CertiK, PeckShield
- **Governance**: DAO-controlled (9-of-15 multisig)

## Risks

EchoForge is experimental DeFi software. Users should understand the risks:

- **Smart Contract Risk**: Bugs despite audits
- **Economic Risk**: Unproven tokenomics model
- **Market Risk**: High volatility, potential principal loss
- **Liquidity Risk**: May not be able to exit during crisis
- **Regulatory Risk**: Evolving regulatory landscape

**Only invest capital you can afford to lose entirely.**

## Learn More

- **[Architecture](./architecture.md)**: Technical system design
- **[Tokenomics](./tokenomics/)**: Supply model and economics
- **[Treasury](./mechanisms/treasury.md)**: Forge Reserve management
- **[FAQ](./faq.md)**: Frequently asked questions
- **Website**: https://echoforge.xyz
- **Discord**: https://discord.gg/echoforge

---

*Last updated: November 2025*
