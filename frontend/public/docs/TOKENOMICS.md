# EchoForge Tokenomics

Complete economic model for the EchoForge protocol.

## Token Overview

### ECHO Token
- **Standard**: ERC20
- **Network**: Arbitrum One  
- **Launch Supply**: 1,200,000 (1M bonding + 200K DEX liquidity)
- **Supply Model**: Elastic (no hard cap, adjusts dynamically)

### eECHO Token
- **Type**: Rebasing wrapper
- **Rebases**: Every 8 hours (1,095/year)
- **APY**: Dynamic 0-30,000% based on backing ratio
- **Wrapping**: 1:1 with ECHO

## Supply Dynamics

### Inflationary Forces
1. **Rebasing**: Mints ECHO at dynamic APY (0-30,000%)
2. **Referrals**: 4-14% of stake minted for referral tree

### Deflationary Forces
1. **Unstake penalties**: 50% burned (0-75% total penalty)
2. **Early unlock penalties**: 100% burned (90% → 10% based on time)
3. **Buyback burns**: 100% burned (price < 75% TWAP)
4. **Manual burns**: User-initiated

## Distribution

```
Launch: 1,200,000 ECHO total
├── Bonding Curve: 1,000,000 (83%) - fair launch
└── DEX Liquidity: 200,000 (17%) - protocol-owned

Team: 0%
Pre-sale: 0%
VC: 0%
```

## Revenue Model

**Sources**:
1. Bonding curve (~$9,500 one-time)
2. Transfer tax (4-15% adaptive, ~$2k/day)
3. Protocol bonds (5% discount, ~$1.5k/day)
4. Unstake penalties (0-75%, ~$500/day)
5. Yield strategies (15-30% APY, ~$1k/day)

**Total**: ~$5,000/day at maturity = $1.825M/year

## Economic Security

**Sustainability**: APY automatically scales with backing ratio
- High backing (200%) → High APY (30,000%)
- Low backing (50%) → Low APY (0%)
- System self-regulates to equilibrium

**Protection**: Multi-layer death spiral prevention
- Dynamic APY reduces emissions
- Exponential penalties during stress
- Buyback engine supports price
- Real yield provides revenue

---

*For complete details, see full tokenomics documentation*
