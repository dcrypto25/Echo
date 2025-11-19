# Instant Unstake System

The Instant Unstake system allows users to bypass the redemption queue by paying a dynamic fee to the treasury, providing immediate liquidity while generating protocol revenue.

## Overview

Normally, when a user unstakes their eECHO, they enter a redemption queue that lasts 3-7 days depending on the backing ratio. This protects the treasury during high sell pressure. However, users who need immediate liquidity can pay a fee to skip the queue entirely.

**Key Innovation**: Fee is dynamic based on queue length and wait time, ensuring fairness while maximizing treasury revenue during high demand periods.

## Fee Structure

### Dynamic Fee Formula

```
Fee = Base Fee + Time Fee + Congestion Fee (capped at 10%)

Where:
- Base Fee: 2% (always applied)
- Time Fee: 0.5% per day of queue wait
- Congestion Fee: 0.1% per user in queue
- Maximum: 10% total
```

### Fee Examples

**Scenario 1: Healthy Protocol (Light Queue)**
```
Backing Ratio: 130%
Queue Time: 3 days
Queue Length: 5 users

Calculation:
├── Base: 2%
├── Time: 3 days × 0.5% = 1.5%
├── Congestion: 5 × 0.1% = 0.5%
└── Total: 4%

To instantly unstake $10,000:
→ Pay $400 (in USDC or ETH equivalent)
```

**Scenario 2: Moderate Stress (Medium Queue)**
```
Backing Ratio: 90%
Queue Time: 4 days
Queue Length: 50 users

Calculation:
├── Base: 2%
├── Time: 4 days × 0.5% = 2%
├── Congestion: 50 × 0.1% = 5%
└── Total: 9%

To instantly unstake $10,000:
→ Pay $900
```

**Scenario 3: High Stress (Full Queue)**
```
Backing Ratio: 55%
Queue Time: 7 days
Queue Length: 200 users

Calculation:
├── Base: 2%
├── Time: 7 days × 0.5% = 3.5%
├── Congestion: 200 × 0.1% = 20% (capped)
├── Raw total: 25.5%
└── Capped Total: 10%

To instantly unstake $10,000:
→ Pay $1,000 (maximum possible)
```

## Payment Options

Users can pay instant unstake fees in two ways:

### Option 1: Stablecoins (USDC or DAI)

**Process:**
1. Calculate fee in USD based on ECHO value
2. User approves stablecoin transfer
3. Call `instantUnstakeStable(tokenAddress)`
4. Stablecoins transferred to treasury
5. User receives ECHO instantly

**Benefits:**
- Exact fee known upfront
- No price slippage
- Straightforward calculation
- Preferred for large unstakes

**Example:**
```solidity
// Unstake $50,000 worth of ECHO
// Fee: 5% = $2,500

// Approve USDC
USDC.approve(redemptionQueue, 2500e6);  // 6 decimals

// Execute instant unstake
redemptionQueue.instantUnstakeStable(USDC_ADDRESS);

// Receive 100,000 ECHO immediately
```

### Option 2: ETH

**Process:**
1. Calculate fee in USD
2. Convert to ETH using Chainlink oracle
3. Send ETH with `instantUnstakeETH()`
4. ETH transferred to treasury
5. User receives ECHO instantly

**Benefits:**
- No token approval needed
- One-step transaction
- Use native gas token
- Preferred for smaller unstakes

**Example:**
```solidity
// Unstake $10,000 worth of ECHO
// Fee: 5% = $500
// ETH price: $2,000
// Fee in ETH: 0.25 ETH

redemptionQueue.instantUnstakeETH{value: 0.25 ether}();

// Receive 20,000 ECHO immediately
```

## Economic Rationale

### Why Dynamic Fees Work

**Problem with Fixed Fees:**
- Too low → everyone uses it, queue worthless
- Too high → nobody uses it, lost revenue
- Can't adapt to market conditions

**Solution: Dynamic Pricing**
- Quiet periods: Low fees (3-4%) encourage use
- Busy periods: High fees (8-10%) maximize revenue
- Self-regulating: High fees → fewer instant unstakes → queue clears → fees drop

### Revenue Projections

**Conservative Scenario (Bear Market)**
```
Assumptions:
- 20 instant unstakes/day
- Average unstake: $5,000
- Average fee: 4%

Daily Revenue:
20 × $5,000 × 4% = $4,000

Annual Revenue: $1.46M
```

**Moderate Scenario (Normal Market)**
```
Assumptions:
- 50 instant unstakes/day
- Average unstake: $8,000
- Average fee: 6%

Daily Revenue:
50 × $8,000 × 6% = $24,000

Annual Revenue: $8.76M
```

**Bull Scenario (High Demand)**
```
Assumptions:
- 150 instant unstakes/day
- Average unstake: $12,000
- Average fee: 8%

Daily Revenue:
150 × $12,000 × 8% = $144,000

Annual Revenue: $52.56M
```

### Treasury Impact

**Benefits:**
1. **Non-dilutive revenue** - No new ECHO minted
2. **Diverse assets** - Receives both ETH and stablecoins
3. **Counter-cyclical** - Higher fees during stress = higher revenue when needed most
4. **User choice** - Those who can wait don't pay; impatient users subsidize treasury
5. **Backing improvement** - Revenue increases backing ratio

**Example Treasury Composition (1 Year)**
```
Starting: $1M treasury
Instant unstake fees: $8.76M (moderate scenario)

Revenue split (50/50 ETH/stables):
├── ETH: $4.38M (2,190 ETH @ $2,000)
└── USDC: $4.38M

Ending Treasury: $9.76M
Backing Ratio: 100% → 245% (assuming 4M supply)
```

## Queue Mechanics Refresher

### Queue Time Calculation

Queue wait time scales with backing ratio:

```
Backing ≥120%: 3 days
Backing ≤50%: 7 days

Between 50-120%: Linear scale
Formula: 3 + 4 × (120% - β) / 70%
```

**Examples:**
- 120% backing → 3 days queue
- 100% backing → 4.1 days queue
- 80% backing → 5.3 days queue
- 60% backing → 6.4 days queue
- 50% backing → 7 days queue

### Fee Impact on Queue

**Feedback Loop:**
```
High queue → High fees → Fewer instant unstakes → Queue grows
Low queue → Low fees → More instant unstakes → Revenue increases

Result: Self-balancing system
- Queue never gets too long (high fees deter)
- Revenue never drops too low (low fees encourage)
```

## User Decision Matrix

| Scenario | Wait Time | Fee | Best Choice |
|----------|-----------|-----|-------------|
| Healthy protocol, no rush | 3 days | 4% | **Wait** (save $) |
| Need funds tomorrow | 3 days | 4% | **Pay** (worth convenience) |
| Emergency exit needed | 7 days | 10% | **Pay** (necessary evil) |
| Large whale unstake | Any | Any | **Wait** (save massive $) |
| Small retail unstake | 3 days | 4% | **Pay** ($40 fee on $1k) |

## Smart Contract Interface

### Read Functions

```solidity
// Get user's current queue info
function getQueueInfo(address user) external view returns (
    uint256 amount,           // ECHO amount queued
    uint256 queueTime,        // When entered queue
    uint256 availableTime,    // When can unstake for free
    uint256 feeBasisPoints,   // Fee in basis points (200-1000)
    uint256 feeUSD,           // Fee in USD (6 decimals)
    uint256 feeETH            // Fee in ETH (18 decimals)
);

// Calculate current queue wait time
function calculateQueueDays() public view returns (uint256);

// Get current queue length
function getQueueLength() external view returns (uint256);

// Calculate fee for specific user
function calculateInstantUnstakeFee(address user) public view returns (uint256);
```

### Write Functions

```solidity
// Instant unstake with USDC/DAI
function instantUnstakeStable(address paymentToken) external;

// Instant unstake with ETH
function instantUnstakeETH() external payable;
```

## Usage Examples

### Frontend Integration

```javascript
// Check user's queue status
const queueInfo = await redemptionQueue.getQueueInfo(userAddress);

if (queueInfo.amount > 0) {
    const waitTime = (queueInfo.availableTime - Date.now()) / 1000 / 86400;
    const feePercent = queueInfo.feeBasisPoints / 100;

    console.log(`
        Queued amount: ${formatECHO(queueInfo.amount)}
        Wait time: ${waitTime.toFixed(1)} days
        Instant unstake fee: ${feePercent}%
        Fee in USDC: $${formatUSD(queueInfo.feeUSD)}
        Fee in ETH: ${formatETH(queueInfo.feeETH)}
    `);
}

// Option 1: Instant unstake with USDC
async function instantUnstakeWithUSDC() {
    const { feeUSD } = await redemptionQueue.getQueueInfo(userAddress);

    // Approve USDC
    await USDC.approve(redemptionQueue.address, feeUSD);

    // Execute
    await redemptionQueue.instantUnstakeStable(USDC.address);
}

// Option 2: Instant unstake with ETH
async function instantUnstakeWithETH() {
    const { feeETH } = await redemptionQueue.getQueueInfo(userAddress);

    // Execute with ETH
    await redemptionQueue.instantUnstakeETH({ value: feeETH });
}
```

### UI/UX Recommendations

**Queue Status Display:**
```
Your Unstake Request
├── Amount: 10,000 ECHO ($5,000)
├── Queue position: #42 of 120
├── Wait time: 4 days, 6 hours
└── Available: Dec 15, 2025 3:45 PM

[Wait in Queue (FREE)] [Instant Unstake (5% fee)]
```

**Instant Unstake Modal:**
```
Instant Unstake Options

Option 1: Pay in USDC
├── Fee: $250 USDC (5%)
├── You receive: 10,000 ECHO immediately
└── [Pay with USDC]

Option 2: Pay in ETH
├── Fee: 0.125 ETH ($250)
├── You receive: 10,000 ECHO immediately
└── [Pay with ETH]

Note: Fee goes to treasury to strengthen protocol backing.
```

## Risk Considerations

### For Users

**Overpaying Risk:**
- Fee might seem high compared to wait time
- Weigh urgency vs cost

**Price Movement Risk:**
- ECHO price might drop while waiting in queue
- Or might rise after paying to exit

**Recommendation:** Only use instant unstake if truly needed, not as default.

### For Protocol

**Queue Bypass Risk:**
- If everyone instant unstakes, queue protection fails
- Mitigation: 10% fee cap makes it expensive

**Oracle Risk:**
- ETH price feed failure could miscalculate fees
- Mitigation: Chainlink oracle redundancy + governance override

**Revenue Volatility:**
- Bear markets: fewer unstakes, lower fees
- Bull markets: more unstakes, higher fees
- Mitigation: Diversified revenue sources

## Governance Parameters

**Adjustable via DAO:**

| Parameter | Current | Min | Max | Rationale |
|-----------|---------|-----|-----|-----------|
| Base Fee | 2% | 1% | 5% | Always profitable |
| Max Fee | 10% | 5% | 20% | Prevent excessive fees |
| Time Multiplier | 0.5%/day | 0.2%/day | 1%/day | Scale with urgency |
| Congestion Multiplier | 0.1%/user | 0.05%/user | 0.2%/user | Scale with demand |

**Cannot be changed:**
- Fee cap mechanism (prevents >20% fees)
- Payment tokens (USDC, DAI, ETH only)
- Chainlink oracle usage

**All changes: 48-hour timelock**

## Comparison to Alternatives

### Centralized Exchanges

**CEX Withdrawal:**
- Fee: $5-50 (flat)
- Time: Minutes to hours
- Risk: Custodial, counterparty risk

**EchoForge Instant Unstake:**
- Fee: 2-10% (percentage)
- Time: Immediate (on-chain)
- Risk: Non-custodial, trustless

### Other DeFi Protocols

**Liquid Staking (Lido):**
- No queue (liquid staking derivative)
- No unstake fee
- But: 10% staking commission

**Fixed Unstake Period (Most protocols):**
- 7-21 day lockup (fixed)
- No instant unstake option
- Users stuck regardless of urgency

**EchoForge Advantage:**
- Dynamic queue (1-7 days, not fixed)
- Instant option available (pay for urgency)
- Fee-based (don't pay if not needed)

---

**Last updated**: November 2025
**Related**: [Unstake Penalty](./unstake-penalty.md) | [Treasury Backing](./treasury-backing.md)
