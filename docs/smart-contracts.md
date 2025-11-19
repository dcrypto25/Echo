# EchoForge Smart Contracts

Technical documentation of all smart contracts, their interactions, key functions, and deployment information.

---

## Contract Architecture

### Core Contracts

```
EchoForge Protocol
├── ECHO.sol (Main token)
├── eECHO.sol (Staking token)
├── Treasury.sol (Forge Reserve)
├── EmissionBalancer.sol (Excess burn)
├── BondingCurve.sol (Fair launch)
├── Staking.sol (Core staking)
├── Referral.sol (Referral system)
├── LockTiers.sol (Lock bonuses)
├── RedemptionQueue.sol (Unstake queue)
├── InsuranceVault.sol (Emergency fund)
└── Governance.sol (DAO control)
```

### Contract Addresses

**Arbitrum One** (Production - To Be Deployed)

```
ECHO Token: 0x... (TBD)
eECHO Token: 0x... (TBD)
Treasury: 0x... (TBD)
Bonding Curve: 0x... (TBD)
Staking: 0x... (TBD)
Referral: 0x... (TBD)
Lock Tiers: 0x... (TBD)
Redemption Queue: 0x... (TBD)
Insurance Vault: 0x... (TBD)
Governance: 0x... (TBD)
```

**Arbitrum Sepolia** (Testnet)

```
[Testnet addresses will be listed here]
```

---

## ECHO Token Contract

### Contract: ECHO.sol

**Purpose**: Main ERC20 protocol token with adaptive transfer tax.

**Key Features**:
- ERC20 standard compliance
- Adaptive tax (4-15%)
- Auto-swap on all transfers (50% ECHO, 50% ETH, triggers at >1000 ECHO)
- Whitelist system
- Burn mechanism
- Staking ratio tracking

### Key Functions

**User Functions**:
```solidity
// Transfer with tax
function transfer(address to, uint256 amount) external returns (bool)

// TransferFrom with tax
function transferFrom(address from, address to, uint256 amount) 
    external returns (bool)

// Burn tokens
function burn(uint256 amount) external

// Burn from allowance
function burnFrom(address from, uint256 amount) external
```

**View Functions**:
```solidity
// Get current tax rate
function getCurrentTaxRate() external view returns (uint256)

// Check whitelist status
function isWhitelisted(address account) external view returns (bool)

// Get circulating supply
function circulatingSupply() external view returns (uint256)

// Get total burned
function totalBurned() external view returns (uint256)
```

**Admin Functions** (Owner only):
```solidity
// Set Treasury address (one-time)
function setTreasury(address _treasury) external onlyOwner

// Set Uniswap router and pair for auto-swap (one-time)
function setUniswapAddresses(address _router, address _pair) external onlyOwner

// Set Staking contract (one-time)
function setStakingContract(address _stakingContract) external onlyOwner

// Update whitelist
function setWhitelist(address account, bool status) external onlyOwner

// Set DEX pair status
function setDEXPair(address pair, bool status) external onlyOwner
```

**Authorized Functions**:
```solidity
// Update staking ratio (Staking contract only)
function updateStakingRatio(uint256 newRatio) external
```

### Key State Variables

```solidity
uint256 public constant BASE_TAX_RATE = 400;        // 4%
uint256 public constant MAX_TAX_RATE = 1500;        // 15%
uint256 public constant TARGET_STAKING_RATIO = 9000; // 90%

uint256 public currentStakingRatio;
uint256 public totalBurned;

address public treasury;
address public stakingContract;
address public dexRouter;  // For auto-swap

mapping(address => bool) private _whitelist;
mapping(address => bool) private _isDexPair;  // Track DEX pairs for auto-swap
```

### Events

```solidity
event WhitelistUpdated(address indexed account, bool status);
event StakingRatioUpdated(uint256 oldRatio, uint256 newRatio);
event Burned(address indexed from, uint256 amount);
```

---

## eECHO Token Contract

### Contract: eECHO.sol

**Purpose**: Rebasing wrapper for staked ECHO with elastic supply and dynamic APY.

**Key Features**:
- Elastic supply (rebasing every 8 hours)
- Dynamic APY system (0-30,000% based on backing ratio)
- Self-regulating emissions
- 1:1 wrapping/unwrapping
- Gons-based accounting

### Key Functions

**User Functions**:
```solidity
// Wrap ECHO to eECHO
function wrap(uint256 echoAmount) external returns (uint256 eEchoAmount)

// Unwrap eECHO to ECHO
function unwrap(uint256 eEchoAmount) external returns (uint256 echoAmount)

// Trigger rebase (anyone can call)
function rebase() external returns (uint256)
```

**View Functions**:
```solidity
// Get current rebase rate
function getCurrentRebaseRate() public view returns (uint256)

// Calculate dynamic APY based on backing ratio
function calculateDynamicAPY(uint256 _backingRatio) public pure returns (uint256)

// Get next rebase time
function nextRebaseTime() external view returns (uint256)

// Get current epoch
function epoch() external view returns (uint256)

// Get backing ratio
function backingRatio() external view returns (uint256)
```

**Authorized Functions**:
```solidity
// Update backing ratio (Treasury only)
function updateBackingRatio(uint256 newRatio) external

// Set treasury (Owner, one-time)
function setTreasury(address _treasury) external onlyOwner
```

### Key State Variables

```solidity
uint256 public constant REBASE_FREQUENCY = 8 hours;
uint256 public constant REBASES_PER_YEAR = 1095;

uint256 public lastRebaseTime;
uint256 public epoch;
uint256 public backingRatio = 10000;  // 100% default
```

### Dynamic APY System

The eECHO contract implements a self-regulating APY system based on backing ratio:

**APY Ranges**:
- **>200% backing**: 30,000% APY (maximum aggression)
- **150-200% backing**: 12,000% - 30,000% APY (very aggressive)
- **120-150% backing**: 8,000% - 12,000% APY (aggressive)
- **100-120% backing**: 5,000% - 8,000% APY (attractive)
- **90-100% backing**: 3,500% - 5,000% APY (gradual slowdown)
- **80-90% backing**: 2,500% - 3,500% APY (moderate slowdown)
- **70-80% backing**: 2,000% - 2,500% APY (stronger slowdown)
- **<70% backing**: 0% - 2,000% APY (emergency mode)

**Formula**:
```solidity
function calculateDynamicAPY(uint256 _backingRatio) public pure returns (uint256)
```

This creates a self-regulating system:
- High backing attracts capital with aggressive APY
- Low backing slows emissions to protect the treasury
- No manual intervention required

### Events

```solidity
event Rebase(uint256 indexed epoch, uint256 totalSupply);
event BackingRatioUpdated(uint256 oldRatio, uint256 newRatio);
```

---

## Bonding Curve Contract

### Contract: BondingCurve.sol

**Purpose**: Fair launch mechanism with exponential price discovery.

**Key Features**:
- Exponential curve pricing
- Multi-token payments
- Anti-bot protection
- Direct treasury funding

### Key Functions

**User Functions**:
```solidity
// Buy with ETH
function buyWithETH() external payable returns (uint256 echoAmount)

// Buy with ERC20
function buyWithToken(address token, uint256 amount) 
    external returns (uint256 echoAmount)
```

**View Functions**:
```solidity
// Get current price
function getCurrentPrice() external view returns (uint256)

// Calculate ECHO amount for payment
function getEchoAmount(uint256 paymentAmount, address paymentToken)
    external view returns (uint256)

// Calculate cost for ECHO amount
function getCost(uint256 echoAmount) external view returns (uint256)
```

**Admin Functions**:
```solidity
// Launch bonding curve
function launch() external onlyOwner

// Update token price oracle
function updateTokenPrice(address token, uint256 priceInETH) 
    external onlyOwner

// Update max buy amount
function updateMaxBuyAmount(uint256 newMax) external onlyOwner

// Emergency withdraw
function emergencyWithdraw() external onlyOwner
```

### Key State Variables

```solidity
uint256 public constant INITIAL_PRICE = 0.01 ether;
uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;

uint256 public totalEchoSold;
uint256 public launchTime;

uint256 public maxBuyAmount = 10_000 * 10**18;
uint256 public constant ANTI_BOT_PERIOD = 24 hours;
```

### Events

```solidity
event Purchase(
    address indexed buyer,
    uint256 echoAmount,
    uint256 cost,
    address paymentToken
);
event Launch(uint256 timestamp);
```

---

## Staking Contract

### Contract: Staking.sol

**Purpose**: Core staking logic with Dynamic Unstake Penalty (DUP).

**Key Features**:
- ECHO to eECHO conversion
- Referral integration
- Dynamic penalties based on backing ratio (0-75%)
- 7-day unstake cooldown
- Penalty distribution: 50% burn, 50% treasury
- Stake-based governance weight

### Key Functions

**User Functions**:
```solidity
// Stake ECHO
function stake(uint256 amount, address referrer) external

// Request unstake
function requestUnstake(uint256 amount) external

// Execute unstake after cooldown
function unstake(uint256 amount) external

// Claim rewards
function claimRewards() external

// Compound rewards
function compound() external
```

**View Functions**:
```solidity
// Get staked balance
function getStakedBalance(address user) external view returns (uint256)

// Get pending rewards
function getPendingRewards(address user) external view returns (uint256)

// Calculate unstake penalty
function calculateUnstakePenalty(uint256 amount) 
    external view returns (uint256)

// Get staking ratio
function getStakingRatio() external view returns (uint256)
```

**Admin Functions**:
```solidity
// Set referral contract (one-time)
function setReferral(address _referral) external onlyOwner

// Set treasury (one-time)
function setTreasury(address _treasury) external onlyOwner
```

### Key State Variables

```solidity
uint256 public constant MIN_BACKING_ZERO_PENALTY = 15000;  // 150%
uint256 public constant MAX_PENALTY_BACKING = 8000;        // 80%
uint256 public constant MAX_PENALTY_PERCENT = 7500;        // 75%

uint256 public constant UNSTAKE_COOLDOWN = 7 days;

uint256 public totalStaked;
mapping(address => uint256) public unstakeRequests;
```

### Dynamic Unstake Penalty (DUP)

The unstake penalty is calculated based on treasury backing ratio:

**Penalty Calculation**:
- **Backing ≥150%**: 0% penalty (healthy protocol)
- **Backing ≤80%**: 75% penalty (maximum protection)
- **Between 80-150%**: Linear scale

**Formula**: `penalty = 75% × (150% - backing) / (150% - 80%)`

**Penalty Distribution**:
- 50% burned (reduces supply, increases backing ratio)
- 50% to treasury (provides ECHO for buybacks)

This system protects the protocol during stress while rewarding long-term holders.

### Events

```solidity
event Staked(address indexed user, uint256 amount, address indexed referrer);
event Unstaked(address indexed user, uint256 amount, uint256 penalty);
event RewardsClaimed(address indexed user, uint256 amount);
event UnstakeRequested(address indexed user, uint256 amount, uint256 availableAt);
event Compounded(address indexed user, uint256 amount);
```

---

## Referral Contract

### Contract: Referral.sol

**Purpose**: 10-level referral system with eECHO rewards.

**Key Features**:
- 10-level tree tracking
- eECHO bonus distribution (rebasing rewards)
- 4-14% total rewards across all levels
- Circular referral prevention
- No NFT integration

### Key Functions

**Authorized Functions** (Staking only):
```solidity
// Record new referral
function recordReferral(address referee, address referrer) external

// Distribute bonuses
function distributeReferralBonus(address referee, uint256 stakeAmount)
    external returns (uint256 totalPaid)
```

**View Functions**:
```solidity
// Get referral tree
function getReferralTree(address user, uint256 maxDepth)
    external view returns (address[] memory)

// Get referral data
function getReferralData(address user)
    external view returns (ReferralData memory)

// Get direct referrals
function getDirectReferrals(address user)
    external view returns (address[] memory)

// Check if has referrer
function hasReferrer(address user) external view returns (bool)
```

### Key State Variables

```solidity
uint256[10] public bonusRates = [400, 200, 100, 100, 100, 100, 100, 100, 100, 100];
uint256 public constant MAX_DEPTH = 10;
```

### Referral Reward Structure

Referrers receive eECHO (not ECHO) as rewards, which then rebases with the protocol:

**Reward Rates** (% of referee's stake):
- **Level 1** (Direct): 4%
- **Level 2**: 2%
- **Levels 3-10**: 1% each

**Total**: 4% + 2% + (8 × 1%) = 14% distributed across the tree

**Example**: User stakes 1,000 ECHO
- Direct referrer receives 40 eECHO (4%)
- Level 2 referrer receives 20 eECHO (2%)
- Levels 3-10 each receive 10 eECHO (1%)

Since rewards are paid in eECHO, referrers benefit from rebasing alongside the referee's stake.

### Events

```solidity
event ReferralRecorded(address indexed referee, address indexed referrer);
event ReferralBonus(address indexed referrer, address indexed referee, uint256 level, uint256 amount);
```

---

## LockTiers Contract

### Contract: LockTiers.sol

**Purpose**: Voluntary time locks for bonus multipliers without NFT requirements.

**Key Features**:
- 4 lock tiers (30/90/180/365 days)
- Multipliers: 1.2x to 4x
- Time-based early unlock penalty (90% → 10%)
- No NFT requirements
- Lock extension supported

### Key Functions

**User Functions**:
```solidity
// Lock eECHO tokens
function lockTokens(uint256 amount, uint8 tier) external

// Extend lock to higher tier
function extendLock(uint8 newTier) external

// Unlock after lock period
function unlock() external

// Force unlock with penalty
function forceUnlock() external
```

**View Functions**:
```solidity
// Get user's multiplier
function getMultiplier(address user) external view returns (uint256)

// Get lock information
function getLockInfo(address user) external view returns (Lock memory)

// Calculate early unlock penalty
function calculateEarlyUnlockPenalty(address user) public view returns (uint256)

// Check if user has lock
function isLocked(address user) external view returns (bool)

// Get time remaining
function getTimeRemaining(address user) external view returns (uint256)
```

### Lock Tiers

```solidity
// Lock durations
uint256[5] public lockDurations = [0, 30 days, 90 days, 180 days, 365 days];

// Multipliers (in basis points: 100 = 1x)
uint256[5] public multipliers = [100, 120, 200, 300, 400];
```

**Tier Details**:
- **Tier 1**: 30 days → 1.2x multiplier
- **Tier 2**: 90 days → 2x multiplier
- **Tier 3**: 180 days → 3x multiplier
- **Tier 4**: 365 days → 4x multiplier

### Early Unlock Penalty

Time-based penalty that decreases linearly over the lock duration:

**Formula**: `penalty = 90% - (80% × timeServed / totalDuration)`

**Examples**:
- Day 1: 90% penalty
- 25% through: 70% penalty
- 50% through: 50% penalty
- 75% through: 30% penalty
- End of lock: 10% penalty

This incentivizes users to honor their lock commitments while allowing emergency exits.

### Events

```solidity
event Locked(address indexed user, uint256 amount, uint8 tier, uint256 unlockTime);
event Unlocked(address indexed user, uint256 amount);
event ExtendedLock(address indexed user, uint8 newTier, uint256 newUnlockTime);
event ForcedUnlock(address indexed user, uint256 amount, uint256 penalty);
```

---

## RedemptionQueue Contract

### Contract: RedemptionQueue.sol

**Purpose**: Dynamic queue system for unstaking during market stress.

**Key Features**:
- Queue duration scales with backing ratio
- 0-10 day range
- No wait when healthy (≥120% backing)
- Extended queue during stress

### Key Functions

```solidity
// Calculate current queue days
function calculateQueueDays() public view returns (uint256)

// Add user to queue
function addToQueue(address user, uint256 amount) external onlyOwner

// Check if redemption is available
function isAvailable(address user) external view returns (bool)
```

### Queue Duration Formula

Queue time dynamically adjusts based on backing ratio:

**Formula**: `queueDays = 10 × (120% - β) / 50%`

**Queue Times**:
- **≥120% backing**: 0 days (healthy protocol, no wait)
- **95% backing**: 5 days
- **70% backing**: 10 days (maximum protection)

This provides fast redemptions when the protocol is healthy while extending queue times during stress to allow the protocol to recover.

### Events

```solidity
event Queued(address indexed user, uint256 amount, uint256 availableTime);
event Processed(address indexed user, uint256 amount);
```

---

## Treasury Contract

### Contract: Treasury.sol

**Purpose**: Protocol treasury with backing calculation and buyback engine.

**Key Features**:
- Asset management
- Backing calculation
- Buyback automation
- Yield strategies
- Multi-asset support

### Key Functions

**Public Functions**:
```solidity
// Deposit assets
function deposit(address token, uint256 amount) external payable

// Execute buyback
function executeBuyback(uint256 maxAmount) external returns (uint256)
```

**View Functions**:
```solidity
// Get backing ratio
function getBackingRatio() external view returns (uint256)

// Get total value
function getTotalValue() external view returns (uint256)

// Get liquid value
function getLiquidValue() external view returns (uint256)

// Get yield value
function getYieldValue() external view returns (uint256)

// Get runway
function getRunway() external view returns (uint256)

// Check if should buyback
function shouldExecuteBuyback() external view returns (bool)
```

**Admin Functions**:
```solidity
// Withdraw assets
function withdraw(address token, uint256 amount) external onlyOwner

// Deploy to yield
function deployToYield(address strategy, uint256 amount) external onlyOwner

// Withdraw from yield
function withdrawFromYield(address strategy, uint256 amount) external onlyOwner

// Approve strategy
function approveStrategy(address strategy) external onlyOwner

// Update price
function updatePrice(uint256 newPrice) external onlyOwner
```

### Events

```solidity
event Deposited(address indexed token, uint256 amount);
event Withdrawn(address indexed token, uint256 amount, address indexed to);
event BuybackExecuted(uint256 echoAmount, uint256 cost);
event BackingRatioUpdated(uint256 oldRatio, uint256 newRatio);
event YieldDeployed(address indexed strategy, uint256 amount);
event YieldWithdrawn(address indexed strategy, uint256 amount);
```

---

## EmissionBalancer Contract

### Contract: EmissionBalancer.sol

**Purpose**: Prevents death spirals by burning emissions that exceed treasury sustainability.

**Key Features**:
- Sustainable APY calculation from treasury metrics
- Automatic excess emission detection
- Treasury-funded buyback and burn
- No user action required

### Key Functions

**Public Functions**:
```solidity
// Check and burn excess emissions (called during rebase)
function balanceEmissions() external returns (uint256 burnedAmount)

// Calculate sustainable APY
function getSustainableAPY() public view returns (uint256)
```

**View Functions**:
```solidity
// Get current sustainable APY
function sustainableAPY() external view returns (uint256)

// Get excess emission amount
function getExcessEmissions() external view returns (uint256)

// Check if burn needed
function shouldBurnExcess() external view returns (bool)

// Get treasury yield rate
function getTreasuryYield() external view returns (uint256)
```

**Admin Functions**:
```solidity
// Update parameters
function updateSafetyFactor(uint256 newFactor) external onlyOwner

// Update risk adjustment
function updateRiskAdjustment(uint256 newAdjustment) external onlyOwner
```

### Key State Variables

```solidity
uint256 public constant SAFETY_FACTOR = 8000;  // 0.8 = 80%
uint256 public riskAdjustment = 9000;          // 0.9 = 90%

uint256 public totalBurned;
uint256 public lastBalanceTime;

address public treasury;
address public eECHO;
```

### Calculation Formula

```solidity
function getSustainableAPY() public view returns (uint256) {
    // Get treasury metrics
    uint256 baseYield = treasury.getYieldRate();
    uint256 backing = treasury.getBackingRatio();
    uint256 liquidity = treasury.getLiquidityDepth();

    // Calculate sustainable rate
    uint256 backingFactor = sqrt(backing);
    uint256 liquidityFactor = sqrt(liquidity);

    return baseYield
        .mul(backingFactor)
        .mul(liquidityFactor)
        .mul(SAFETY_FACTOR)
        .mul(riskAdjustment)
        .div(10000)
        .div(10000);
}
```

### Events

```solidity
event ExcessBurned(uint256 excessAmount, uint256 sustainableAPY, uint256 actualAPY);
event SustainableAPYUpdated(uint256 oldAPY, uint256 newAPY);
event ParametersUpdated(uint256 safetyFactor, uint256 riskAdjustment);
```

---

## Contract Interactions

### Staking Flow

```
User → Staking.stake()
  ├→ ECHO.transferFrom(user) [Transfer ECHO]
  ├→ eECHO.wrap() [Convert to eECHO]
  ├→ Referral.recordReferral() [Record relationship if first stake]
  ├→ Referral.distributeReferralBonus() [Mint & distribute eECHO bonuses]
  └→ ECHO.updateStakingRatio() [Update tax rate]
```

### Unstaking Flow

```
User → Staking.requestUnstake()
  └→ [7-day cooldown starts]

User → Staking.unstake() [After cooldown]
  ├→ Treasury.getBackingRatio() [Check backing]
  ├→ [Calculate penalty: 0-75% based on backing]
  ├→ eECHO.unwrap() [Convert to ECHO]
  ├→ ECHO.burn() [Burn 50% of penalty]
  ├→ ECHO.transfer() [Send 50% of penalty to treasury]
  ├→ ECHO.transfer() [Send net amount to user]
  └→ ECHO.updateStakingRatio() [Update tax rate]
```

### Rebase Flow

```
Anyone → eECHO.rebase()
  ├→ [Check 8 hours passed]
  ├→ Treasury.getBackingRatio() [Get backing]
  ├→ calculateDynamicAPY() [Calculate APY: 0-30,000%]
  ├→ getCurrentRebaseRate() [Convert APY to per-rebase rate]
  ├→ [Calculate supply delta]
  ├→ [Increase totalSupply]
  ├→ [Update gonsPerFragment]
  └→ [All balances increase proportionally]
```

### Referral Bonus Distribution Flow

```
User stakes 1,000 ECHO → Staking.stake()
  └→ Referral.distributeReferralBonus()
       ├→ [Traverse up referral tree (max 10 levels)]
       ├→ Level 1: Mint 40 ECHO, wrap to 40 eECHO, send to referrer
       ├→ Level 2: Mint 20 ECHO, wrap to 20 eECHO, send to referrer
       ├→ Level 3-10: Mint 10 ECHO each, wrap to 10 eECHO, send to referrer
       └→ [All eECHO rewards automatically rebase with protocol]
```

---

## Security Features

### Access Control

**Ownable Pattern**:
- One-time setup functions (owner only)
- Renounce ownership after setup
- Multi-sig as owner

**Role-Based Access**:
- Staking contract → can call Referral
- Treasury → can update eECHO backing
- Authorized contracts only

### Reentrancy Guards

All external functions with transfers:
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

function stake(...) external nonReentrant {
    // Protected from reentrancy
}
```

### Safe Math

Solidity 0.8.20 native overflow protection:
- Automatic revert on overflow/underflow
- No need for SafeMath library
- Gas efficient

### Input Validation

```solidity
require(amount > 0, "Zero amount");
require(to != address(0), "Zero address");
require(backing <= 10000, "Invalid ratio");
```

### Immutable Variables

Critical addresses marked immutable:
```solidity
IECHO public immutable echo;
IeECHO public immutable eEcho;
ITreasury public immutable treasury;
```

---

## Deployment

### Deployment Order

1. **ECHO Token**
2. **eECHO Token** (pass ECHO address)
3. **Treasury** (pass ECHO, eECHO)
4. **Referral** (pass ECHO, eECHO)
5. **Staking** (pass ECHO, eECHO)
6. **LockTiers** (pass eECHO)
7. **RedemptionQueue** (pass Treasury)
8. **BondingCurve** (pass ECHO, Treasury)
9. **InsuranceVault** (pass Treasury)
10. **Governance** (pass all contracts)

### Post-Deployment Setup

```solidity
// ECHO setup
ECHO.setEchoPool(echoPool);
ECHO.setTreasury(treasury);
ECHO.setStakingContract(staking);
ECHO.setWhitelist(staking, true);
ECHO.setWhitelist(treasury, true);
ECHO.setWhitelist(bondingCurve, true);

// eECHO setup
eECHO.setTreasury(treasury);

// Staking setup
Staking.setReferral(referral);
Staking.setTreasury(treasury);

// Referral setup
Referral.setStakingContract(staking);

// BondingCurve setup
BondingCurve.launch();

// Transfer ownership to multi-sig
[All contracts].transferOwnership(multisig);
```

---

## Verification

All contracts verified on Arbiscan:
- Source code visible
- Constructor arguments
- Compiler version: 0.8.20
- Optimization: 200 runs
- License: MIT

---

## Integration Guide

### For Developers

**Read Contract Data**:
```javascript
// Web3.js
const echo = new web3.eth.Contract(ECHO_ABI, ECHO_ADDRESS);
const balance = await echo.methods.balanceOf(userAddress).call();
const taxRate = await echo.methods.getCurrentTaxRate().call();
```

**Write Transactions**:
```javascript
// Stake ECHO
await echo.methods.approve(STAKING_ADDRESS, amount).send({from: user});
await staking.methods.stake(amount, referrer).send({from: user});
```

**Listen to Events**:
```javascript
staking.events.Staked({fromBlock: 'latest'})
  .on('data', event => {
    console.log('New stake:', event.returnValues);
  });
```

---

## FAQ

**Q: Are contracts upgradeable?**
A: No, all contracts are immutable for security.

**Q: Can admin steal funds?**
A: No, admin can only execute predefined functions, not arbitrary transfers.

**Q: What if a contract has a bug?**
A: Insurance vault exists. Audits minimize risk. Can deploy new versions.

**Q: How to verify contracts?**
A: All source code published on Arbiscan with verification.

**Q: Can contracts be paused?**
A: No pause functionality. Increases decentralization and security.

---

## Conclusion

EchoForge smart contracts are:
- **Immutable**: No upgrades, final code
- **Secure**: Audited, best practices
- **Transparent**: Open source, verified
- **Modular**: Clean separation of concerns
- **Efficient**: Gas optimized

Full technical reference for developers and auditors.
