# Protocol Architecture

EchoForge is built as a modular system of interconnected smart contracts on Arbitrum One, designed for security, composability, and decentralized governance.

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                  EchoForge Protocol                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Token Layer                                              │
│  ┌──────────────┐         ┌──────────────┐             │
│  │  ECHO Token  │←───────→│ eECHO Token  │             │
│  │   (ERC20)    │ 1:1 wrap │  (Rebasing)  │             │
│  └──────────────┘         └──────────────┘             │
│                                                           │
│  Mechanism Layer                                          │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐ ┌─────────┐     │
│  │Staking  │ │Referral │ │LockTiers │ │ Bonds   │     │
│  └─────────┘ └─────────┘ └──────────┘ └─────────┘     │
│                                                           │
│  Treasury Layer                                           │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Treasury   │←───────→│    Yield     │             │
│  │ (Forge Reserve)│        │  Strategies  │             │
│  └──────────────┘         └──────────────┘             │
│                                                           │
│  Governance Layer                                         │
│  ┌──────────────┐         ┌──────────────┐             │
│  │     DAO      │←───────→│   Multisig   │             │
│  │  Governance  │         │   (9-of-15)  │             │
│  └──────────────┘         └──────────────┘             │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Core Contracts

### ECHO Token

**Purpose**: Main protocol token with adaptive transfer tax

**Key Features**:
- ERC20 standard implementation
- Adaptive transfer tax (4-15%) based on staking ratio
- Auto-swap mechanism (50% ECHO, 50% ETH to treasury)
- Whitelist system for protocol operations
- Burn tracking and deflationary mechanics

**Formula**:
```solidity
taxRate = 4% + 11% × max(0, (90% - stakingRatio) / 90%)
```

**State Variables**:
- `totalSupply`: Current circulating supply
- `stakingRatio`: Percentage of supply staked
- `taxCollected`: Accumulated tax for auto-swap
- `isWhitelisted`: Address exemptions from tax

### eECHO Token

**Purpose**: Rebasing wrapper for staked ECHO tokens

**Key Features**:
- Elastic supply via gons mechanism
- Rebases every 8 hours (3x daily)
- Dynamic APY based on backing ratio (0-30,000%)
- 1:1 wrapping/unwrapping with ECHO
- Proportional balance growth for all holders

**Formula**:
```solidity
// Per-rebase growth rate
rebaseRate = (1 + APY)^(1/1095) - 1

// Dynamic APY calculation
APY = calculateDynamicAPY(backingRatio)
```

**Gons Mechanism**:
```solidity
TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY)
gonsPerFragment = TOTAL_GONS / totalSupply
userBalance = userGons / gonsPerFragment
```

### Staking Contract

**Purpose**: Core staking logic and unstake management

**Key Features**:
- Stake ECHO → receive eECHO (1:1)
- Dynamic unstake penalty (DUP) based on backing
- Redemption queue (1-7 days) during stress
- Lock tier integration
- Referral system integration

**Unstake Penalty Formula**:
```solidity
// Exponential penalty curve
penalty = 75% × ((120% - backingRatio) / 70%)²
// Range: 0% (at ≥120% backing) to 75% (at ≤50% backing)

// Distribution
burnAmount = penalty × 50%
treasuryAmount = penalty × 50%
```

**Queue Length Formula**:
```solidity
queueDays = (12000 - backing) / 500
// Range: 1-7 days
```

### Referral Contract

**Purpose**: 10-level referral network with eECHO rewards

**Key Features**:
- Tree structure tracking (10 levels)
- Automatic eECHO distribution on stakes
- Anti-circular validation
- Level-based commission rates

**Commission Structure**:
```solidity
Level 1: 4% of stake
Level 2: 2% of stake
Levels 3-10: 1% each
Total: 14% maximum
```

**Distribution Flow**:
```
User stakes → Referral contract checks tree
           → Mints ECHO for bonuses
           → Wraps to eECHO
           → Distributes to 10 levels
```

### LockTiers Contract

**Purpose**: Voluntary lock periods with multiplier bonuses

**Key Features**:
- Cliff lock system (30/90/180/365 days)
- Multiplier calculation (1.2× to 4×)
- Time-based early unlock penalties
- Extension and migration logic

**Multipliers**:
```
30 days  → 1.2× APY
90 days  → 2.0× APY
180 days → 3.0× APY
365 days → 4.0× APY
```

**Early Unlock Penalty**:
```solidity
penalty = 90% - (80% × timeServed / totalDuration)
// Range: 90% (immediate) to 10% (at completion)
```

### Treasury Contract

**Purpose**: Forge Reserve - DAO-controlled asset management

**Key Features**:
- Multi-asset treasury (ECHO, ETH, stablecoins)
- Backing ratio calculation
- Buyback engine (price < 75% TWAP)
- Yield strategy deployment
- Runway calculations

**Backing Ratio**:
```solidity
backingRatio = (treasuryValue / echoMarketCap) × 100%

Where:
treasuryValue = liquidAssets + yieldAssets
echoMarketCap = totalSupply × currentPrice
```

**Buyback Trigger**:
```solidity
if (currentPrice < TWAP_30day × 0.75 && backingRatio > 100%) {
    executeBuyback(maxAmount);
    burnPurchasedECHO();
}
```

### YieldStrategy Contracts

**Purpose**: Deploy treasury to productive DeFi protocols

**Supported Strategies**:
- GMX staking (15-20% APY in ETH + esGMX)
- GLP staking (20-30% APY in ETH + esGMX)
- Aave lending (3-8% APY)
- Curve pools (10-20% APY)

**Target Allocation**:
```
60% Productive assets (GMX, GLP, Curve)
30% Liquid reserves (ETH, stablecoins)
10% Protocol tokens (ECHO)
```

### ProtocolBonds Contract

**Purpose**: Alternative acquisition mechanism with discounts

**Key Features**:
- Deposit ETH/stablecoins for discounted ECHO
- 5% discount vs market price
- 1-day vesting period (as eECHO)
- 100% proceeds to treasury

**Bond Pricing**:
```solidity
bondPrice = marketPrice × 0.95  // 5% discount
vestingPeriod = 1 day
```

### BondingCurve Contract

**Purpose**: Fair launch price discovery mechanism

**Key Features**:
- Exponential pricing curve
- Anti-bot protection (first 24h)
- Multi-token payment support
- All proceeds to treasury

**Price Formula**:
```solidity
price(supply) = 0.0003 ETH × (1 + supply / 1,000,000)²
```

### Governance Contracts

**Purpose**: Decentralized protocol control

**Components**:
- **DAO Governance**: Stake-based voting (1 ECHO = 1 vote)
- **Multisig**: 9-of-15 signers for execution
- **Timelock**: 2-day delay for major changes

**Powers**:
- Treasury asset allocation
- Yield strategy approval
- Parameter adjustments (within bounds)
- Emergency actions (if backing < 50%)

**Restrictions**:
- Cannot mint unbacked ECHO
- Cannot change core mechanics
- Cannot bypass timelock
- All actions on-chain and transparent

## Data Flow

### Stake Flow

```
1. User approves ECHO
2. Staking contract transfers ECHO from user
3. Staking mints eECHO (1:1)
4. If referral code: Referral contract mints bonus ECHO
5. Referral contract wraps bonus to eECHO
6. Referral contract distributes to 10 levels
7. Staking updates global staking ratio
8. ECHO contract adjusts transfer tax rate
```

### Rebase Flow

```
1. Anyone calls eECHO.rebase() (every 8 hours)
2. eECHO queries Treasury for backing ratio
3. eECHO calculates dynamic APY from backing
4. eECHO calculates per-rebase rate: (1 + APY)^(1/1095) - 1
5. eECHO increases totalSupply by rebase rate
6. gonsPerFragment decreases proportionally
7. All user balances increase automatically
8. Event emitted with new supply
```

### Unstake Flow

```
1. User requests unstake of X eECHO
2. Staking checks backing ratio
3. Staking calculates:
   a. Queue time (1-7 days based on backing)
   b. Penalty (0-75% based on backing)
4. Request recorded with claimable timestamp
5. After queue period expires:
   a. User calls claimUnstake()
   b. Penalty applied: 50% burned, 50% to treasury
   c. Net ECHO transferred to user
6. Staking updates global staking ratio
7. ECHO contract adjusts transfer tax
```

### Treasury Flow

```
Continuous operations:

1. Collect Revenue:
   - Transfer taxes (50% ECHO + 50% ETH via auto-swap)
   - Unstake penalties (50%, other 50% burned)
   - Bond sales (100%)
   - Yield earnings (from GMX/GLP/Aave)

2. Deploy Assets:
   - Maintain 30% liquid reserves
   - Deploy 60% to yield strategies
   - Hold 10% ECHO

3. Monitor Health:
   - Track backing ratio continuously
   - Calculate runway (days of sustainability)
   - Update eECHO with current backing

4. Execute Buybacks:
   - If price < 75% TWAP
   - Buy ECHO from DEX
   - Burn purchased tokens
   - Support price floor

5. Rebalance:
   - Withdraw from yield if backing drops
   - Deploy more if backing high
   - Maintain target allocations
```

## Security Model

### Access Control

**Tiered Permissions**:
- **Public**: Staking, unstaking, rebasing, bond purchases
- **Governance**: Treasury allocation, parameter adjustments
- **Multisig**: Emergency actions, strategy approvals
- **Immutable**: Core formulas, token contracts

**Timelock Requirements**:
- Parameter changes: 2-day delay
- Treasury deployment: 2-day delay
- Emergency actions: Immediate (requires 9-of-15)

### Invariant Checks

**Critical Invariants**:
```solidity
// Treasury backing must exist
assert(treasury.totalAssets() > 0);

// eECHO supply ≤ ECHO supply
assert(eECHO.totalSupply() <= ECHO.totalSupply());

// Backing ratio calculable
assert(ECHO.totalSupply() > 0);

// No circular referrals
assert(!hasCircularReferrals(user));

// Rebase rate non-negative
assert(rebaseRate >= 0);
```

### Upgrade Strategy

**Non-Upgradeable Contracts**:
- ECHO token
- eECHO token
- Core math functions

**Upgradeable Contracts** (via proxy):
- Yield strategies
- Governance logic
- Oracle integrations

## Integration Points

### External Protocols

**DEX Integration**:
- Uniswap V3 for liquidity and swaps
- Price oracles via TWAP
- Auto-swap execution for transfer tax

**DeFi Protocols**:
- GMX for staking yield
- GLP for liquidity provider yield
- Aave for lending yield
- Curve for LP yield

**Oracles**:
- Chainlink for price feeds
- Internal TWAP for backup
- Multi-source aggregation

### Frontend Integration

**Web3 Requirements**:
- Wallet connection (RainbowKit/Wagmi)
- Contract interactions (ethers.js/viem)
- Event listeners for rebases
- Real-time balance updates

**Key Contract Calls**:
```javascript
// Staking
await ECHO.approve(stakingAddress, amount);
await Staking.stake(amount, referrerAddress);

// Unstaking
await Staking.requestUnstake(amount);
// Wait queue period...
await Staking.claimUnstake();

// Locking
await LockTiers.lock(amount, tierIndex);

// Bonding
await ProtocolBonds.deposit(paymentToken, amount);
```

## Performance Considerations

### Gas Optimization

**Efficient Operations**:
- Gons mechanism (no balance updates on rebase)
- Batch operations where possible
- Minimal storage writes
- Optimized loops in referral distribution

**Expensive Operations**:
- Referral distribution (10 levels)
- Yield strategy deposits
- Buyback executions

**Gas Costs** (approximate):
- Stake: ~150k gas
- Unstake request: ~100k gas
- Claim unstake: ~120k gas
- Rebase: ~80k gas
- Bond purchase: ~200k gas

### Scalability

**Arbitrum Benefits**:
- Low gas costs (~0.1 gwei)
- Fast finality (~1 second)
- Ethereum security
- Growing DeFi ecosystem

**Limitations**:
- 10-level referral adds complexity
- Treasury operations can be gas-intensive
- Yield strategy rebalancing requires periodic execution

## Deployment Architecture

### Contract Deployment Order

```
1. ECHO Token
2. eECHO Token
3. Treasury
4. Staking
5. LockTiers
6. Referral
7. ProtocolBonds
8. BondingCurve
9. YieldStrategies
10. Governance
```

### Initial Configuration

**Launch Parameters**:
- Initial backing ratio: 400% (from bonding curve)
- Initial APY: 30,000% (at 400% backing)
- Transfer tax: 4% (expecting high staking)
- Rebase interval: 8 hours
- Bond discount: 5%
- Bond vesting: 1 day

**Treasury Setup**:
- Deploy initial liquidity (200k ECHO + 4k ETH)
- Configure yield strategies
- Set buyback parameters
- Initialize multisig

## Monitoring and Maintenance

### Health Metrics

**Protocol Health**:
- Backing ratio (target: 100-150%)
- Runway (target: 180+ days)
- Staking ratio (target: 90%+)
- Treasury yield (actual vs projected)

**System Status**:
- Rebase execution (every 8 hours)
- Buyback triggers and execution
- Yield strategy performance
- Oracle price feeds

### Alerting

**Critical Alerts**:
- Backing < 80%
- Runway < 30 days
- Oracle failure
- Large unstake requests
- Abnormal price movements

**Operational Alerts**:
- Rebase missed
- Buyback execution needed
- Yield strategy rebalance due
- Governance vote requiring action

## Future Enhancements

**Planned Improvements**:
- Cross-chain deployment (Base, Optimism)
- Additional yield strategies
- Governance v2 with delegation
- Insurance vault activation
- Protocol-owned liquidity expansion

**Under Research**:
- ECHO-backed stablecoin
- NFT collateral integration
- Cross-chain messaging (LayerZero)
- Real-world asset backing

---

*Last updated: November 2025*
