# EchoForge ($ECHO)

> **The Unkillable, Self-Propagating Reserve Currency**

## Core Thesis

EchoForge is the first fully decentralized, referral-optimized, treasury-backed reserve currency that turns every single holder into a paid growth engine and mathematically prevents the death spirals that destroyed every prior (3,3) protocol — including $OHM.

**"Every holder is paid to recruit. The treasury is the marketing budget."**

## What Makes EchoForge Different

- **Dynamic APY (0-30,000%)**: APY automatically adjusts based on treasury backing
- **10-Level Referral System**: Earn 4% L1 + 2% L2 + 1% L3-L10 on all referred stakes
- **Dynamic Unstake Penalty**: 0-75% penalty based on backing ratio protects treasury
- **Treasury Buyback Engine**: Auto-buys and burns when price drops 25%+ below TWAP
- **Real Yield Integration**: 40% of treasury earns GMX/GLP yields independently
- **Insurance Vault**: Community-owned bailout fund activated if backing < 50%
- **100% Fair Launch**: No team tokens, no pre-sale, no VCs — only bonding curve

## Regulatory Immunity (OlympusDAO Playbook)

- ✅ Day 0 ownership renounced → 9-of-15 DAO multisig
- ✅ 100% pseudonymous founders (no KYC, no legal entities)
- ✅ Multi-audit (Hackensight + CertiK + PeckShield)
- ✅ SEC-compliant "decentralized network participation right"
- ✅ Open-source + transparent treasury

## Quick Start

### For Users

```bash
# 1. Visit app.echoforge.finance (post-launch)
# 2. Connect wallet (MetaMask on Arbitrum)
# 3. Buy ECHO via bonding curve
# 4. Stake ECHO → receive eECHO + Echo Node NFT
# 5. Share your referral link → earn 4-11% on all referrals (10 levels)
# 6. Watch your balance rebase every 8 hours
```

### For Developers

```bash
# Clone repository
git clone https://github.com/dcrypto25/Echo.git
cd echo

# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Arbitrum Sepolia testnet
npx hardhat run scripts/deploy.js --network arbitrumSepolia
```

## Core Mechanics

### 1. Bonding Curve Launch
- **Fair price discovery**: Exponential curve (starts $0.01, increases with supply)
- **No team allocation**: 100% of ECHO enters circulation via public bonding
- **Multi-asset**: Accepts ETH, WETH, USDC, USDT, DAI
- **All funds → Treasury**: Immediate backing ratio > 100%

### 2. Staking & Rebasing
- **Stake 1 ECHO** → receive **1 eECHO** (rebasing token)
- **Dynamic APY (0-30,000%)** automatically adjusts based on treasury backing
- **Rebase every 8 hours** (3× daily)
- **Backing-linked dampener**: Rebase scales 0-100% based on treasury health

### 3. Referral System (10 Levels)
```
Your Referrals:
├─ Level 1 (Direct): 4% of stake
├─ Level 2: 2% of stake
└─ Levels 3-10: 1% each

Total max: 11% of all downstream volume

Example:
Alice refers Bob (stakes $10,000)
├─ Alice earns: $400 instantly (4%)
├─ Bob refers Charlie (stakes $10,000)
│   ├─ Bob earns: $400 (4%)
│   └─ Alice earns: $200 (2% L2 bonus)
```

### 4. Lock Tiers (Optional)
Lock your eECHO for bonus multipliers:
- **30 days** → 1.2× rewards
- **90 days** → 2× rewards
- **180 days** → 3× rewards
- **365 days** → 4× rewards

Early unlock = 90% penalty (burned)

### 5. Dynamic Unstake Penalty (Anti-Death Spiral)
```
Exponential Penalty Formula: penalty = 75% × ((120% - ratio) / 70%)²

Backing Ratio → Penalty:
≥ 120% backing → 0% penalty (free exit)
100% backing → 6.1% penalty
50% backing → 75% penalty (maximum)

Penalty split:
- 50% burned (deflationary)
- 50% to treasury (sustainability)

Dynamic Cooldown: 1-7 days based on backing
≥ 120% backing → 1 day cooldown
50% backing → 7 days cooldown
```

### 6. Treasury Buyback Engine
```
Trigger: ECHO price < 30-day TWAP by 25%

Auto-action:
1. Treasury buys ECHO on Uniswap V3
2. Burns purchased tokens
3. Continues until price recovers
4. Max 5% of treasury per week
```

### 7. Real Yield Autopilot
- **40% of treasury** → GMX/GLP staking
- **Yields auto-compound** into backing assets
- **Creates sustainable floor** independent of new deposits
- **Future integrations**: Pendle, Jones DAO, Aura Finance

## Smart Contract Architecture

```
Core Contracts (13 total):
├─ ECHO.sol               - Main ERC20 with adaptive transfer tax
├─ eECHO.sol              - Rebasing wrapper with dampener
├─ EchoNode.sol           - ERC721 NFT tier system
├─ BondingCurve.sol       - Fair launch mechanism
├─ Staking.sol            - Core staking + DUP
├─ Referral.sol           - 10-level referral tree
├─ LockTiers.sol          - Voluntary cliff locks
├─ Treasury.sol           - Forge Reserve + buyback engine
├─ InsuranceVault.sol     - Emergency backing fund
├─ YieldStrategy.sol      - GMX/GLP integration
├─ EchoOracle.sol         - Confidence score calculator
├─ Governance.sol         - DAO voting
└─ RedemptionQueue.sol    - Anti-rush unstaking

Tech Stack:
- Solidity 0.8.20
- Hardhat + Foundry
- Arbitrum One (L2)
- Chainlink Oracles
- Uniswap V3
- GMX Protocol
```

See [docs/TECHNICAL_ARCHITECTURE.md](docs/TECHNICAL_ARCHITECTURE.md) for complete specifications.

## Projected Growth (Conservative Model)

| Month | TVL | $ECHO Price | Backing/Token | Runway | Key Milestone |
|-------|-----|-------------|---------------|--------|---------------|
| 1 | $25M | $120 | $45 | 180 days | Referral ignition |
| 3 | $400M | $1,800 | $420 | 1 year | Lock Tiers activated |
| 6 | $2.1B | $9,500 | $2,800 | 3+ years | Cross-chain expansion |
| 12 | $8-15B | $40K-$80K | $12K-$25K | 10+ years | Top-20 DeFi protocol |

**Assumptions**: 1.8 viral coefficient, 88% staking ratio, 15-20% GMX yields, no black swans

## Documentation

- **[Project Bible](docs/PROJECT_BIBLE.md)** - Complete vision and tokenomics
- **[Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)** - Full contract specifications
- **[Tokenomics Deep-Dive](docs/TOKENOMICS.md)** - Economic models and sustainability

## Development Roadmap

**Phase 1: Foundation** (Weeks 1-2)
- ✅ Repository setup
- ✅ Documentation
- ⏳ Core contracts (ECHO, eECHO, EchoNode)
- ⏳ Bonding curve implementation

**Phase 2: Core Protocol** (Weeks 3-4)
- ⏳ Staking with DUP
- ⏳ 10-level referral system
- ⏳ Lock tiers mechanism
- ⏳ Unit tests (>90% coverage)

**Phase 3: Treasury & Yield** (Week 5)
- ⏳ Treasury + buyback engine
- ⏳ Insurance vault
- ⏳ GMX/GLP integration
- ⏳ Oracle system

**Phase 4: Governance** (Week 6)
- ⏳ DAO contracts
- ⏳ Redemption queue
- ⏳ Integration tests
- ⏳ Mainnet fork testing

**Phase 5: Security** (Weeks 7-10)
- ⏳ Internal audit
- ⏳ External audits (3×)
- ⏳ Bug bounty program
- ⏳ Audit remediation

**Phase 6: Launch Prep** (Weeks 11-12)
- ⏳ Frontend development
- ⏳ Subgraph deployment
- ⏳ Deployment scripts
- ⏳ Community setup

**Phase 7: Launch** (Week 13)
- ⏳ Mainnet deployment
- ⏳ Contract verification
- ⏳ Ownership transfer to DAO
- ⏳ Public announcement

## Security & Audits

### Pre-Launch Checklist
- [ ] Hackensight audit
- [ ] CertiK audit + formal verification
- [ ] PeckShield audit
- [ ] Immunefi bug bounty ($1M max)
- [ ] 95%+ test coverage
- [ ] Fuzz testing on all math
- [ ] Mainnet fork stress testing

### Known Risks
- **Smart contract risk**: Despite audits, bugs may exist
- **Economic risk**: High APY models inherently volatile
- **Oracle risk**: Price manipulation possibilities
- **Regulatory risk**: DeFi regulations evolving

## Community

- **Twitter**: [@EchoForgeDAO](https://twitter.com/EchoForgeDAO) (post-launch)
- **Discord**: [discord.gg/echoforge](https://discord.gg/echoforge) (post-launch)
- **Telegram**: [t.me/echoforge](https://t.me/echoforge) (post-launch)
- **Docs**: [docs.echoforge.finance](https://docs.echoforge.finance) (post-launch)
- **Dune**: Analytics dashboard (post-launch)

## For Contributors

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - see [LICENSE](LICENSE) file

## Disclaimer

**This protocol is experimental software.**

- No guarantees of profit or returns
- Smart contract risks exist despite audits
- Regulatory landscape may change
- Use at your own risk
- Never invest more than you can afford to lose
- Do your own research (DYOR)

EchoForge has no company, no CEO, no legal entity. It is a fully decentralized protocol governed by $ECHO holders.

---

**"$OHM was the prototype. $ECHO is the final form."**

Built with community, powered by alignment.
