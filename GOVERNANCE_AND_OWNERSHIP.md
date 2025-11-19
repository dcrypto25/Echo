# EchoForge Governance & Ownership Strategy

## Overview

This document outlines which contracts should be **renounced** (ownership → address(0)) versus controlled by **Governance** (ownership → Governance contract).

---

## Contracts Under Governance Control

These contracts require ongoing parameter adjustments and MUST be owned by the Governance contract:

### 1. **ProtocolBonds** ⚠️ GOVERNANCE REQUIRED
**Owner:** Governance Contract

**Why:**
- Needs to switch from fixed price ($0.015) to oracle mode (market - 5%)
- Requires ETH price updates (currently hardcoded to $3000)
- May need to adjust discount percentage
- Emergency pause functionality

**Admin Functions:**
```solidity
function setPriceOracle(address _oracle) external onlyOwner
function setFixedPrice(uint256 _price) external onlyOwner
function enableOracleMode() external onlyOwner
function updateETHPrice(uint256 priceInUSD) external onlyOwner
function updateTokenPrice(address token, uint256 priceInUSD) external onlyOwner
function enableBonds() external onlyOwner
function disableBonds() external onlyOwner
```

**Governance Actions Needed:**
1. **Week 1-2:** Monitor fixed price mode at $0.015
2. **Week 2-3:** Deploy and test price oracle
3. **Week 3:** Vote to set oracle and switch to oracle mode
4. **Ongoing:** Update ETH price if needed (or use Chainlink)

---

### 2. **ECHO Token** ⚠️ GOVERNANCE REQUIRED
**Owner:** Governance Contract

**Why:**
- Minter role management
- Tax parameter adjustments
- Whitelisting addresses
- Emergency functions

**Admin Functions:**
```solidity
function grantMinterRole(address minter) external onlyOwner
function revokeMinterRole(address minter) external onlyOwner
function setWhitelisted(address account, bool status) external onlyOwner
function setTreasury(address _treasury) external onlyOwner
```

**Governance Actions Needed:**
- Grant/revoke minter roles as needed
- Whitelist new contracts
- Emergency adjustments

---

### 3. **eECHO Token** ⚠️ GOVERNANCE REQUIRED
**Owner:** Governance Contract

**Why:**
- Rebase control
- Treasury management
- Emergency functions

**Admin Functions:**
```solidity
function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner
function setTreasury(address _treasury) external onlyOwner
```

---

### 4. **Treasury** ⚠️ GOVERNANCE REQUIRED
**Owner:** Governance Contract

**Why:**
- Fund allocation
- Yield strategy management
- Buyback operations
- Emergency withdrawals

**Admin Functions:**
```solidity
function allocateFunds(...) external onlyOwner
function executeYieldStrategy(...) external onlyOwner
function executeBuyback(...) external onlyOwner
function emergencyWithdraw(...) external onlyOwner
```

---

### 5. **Staking** 🔒 GOVERNANCE RECOMMENDED
**Owner:** Governance Contract

**Why:**
- Parameter adjustments (APY, penalties, etc.)
- Integration updates
- Emergency pause

**Admin Functions:**
```solidity
function setTreasury(address _treasury) external onlyOwner
function setReferral(address _referral) external onlyOwner
// Plus any parameter adjustment functions
```

---

## Contracts That Can Be Renounced

These contracts have **immutable** logic and don't require ongoing adjustments:

### 1. **BondingCurve** ✅ CAN RENOUNCE (with caveats)
**Owner:** Can renounce AFTER launch completes

**Why Safe:**
- All parameters are constants
- One-time launch mechanism
- No ongoing adjustments needed

**HOWEVER:**
- Currently has ETH price hardcoded to $3000
- May want to keep owner until bonding completes
- Has `updateTokenPrice()` and `updateMaxBuyAmount()` functions

**Recommendation:** Keep owner until bonding curve completes, then renounce

---

### 2. **LockTiers** ✅ CAN RENOUNCE
**Owner:** Can renounce

**Why Safe:**
- Multipliers are immutable
- No parameter adjustments needed
- Pure logic contract

---

### 3. **Referral** ✅ CAN RENOUNCE
**Owner:** Can renounce

**Why Safe:**
- Reward percentages are constants
- No adjustable parameters
- Pure logic contract

---

### 4. **EchoNode NFT** 🔒 GOVERNANCE RECOMMENDED
**Owner:** Governance Contract (for upgrades)

**Why:**
- May need to update integrations
- Future feature additions
- Metadata updates

---

### 5. **Governance** ❌ NEVER RENOUNCE
**Owner:** Self-owned (Governance → Governance)

**Why:**
- Controls all other contracts
- Self-governance model
- Can upgrade itself via proposals

---

### 6. **RedemptionQueue** 🔒 GOVERNANCE RECOMMENDED
**Owner:** Governance Contract

**Why:**
- May need parameter adjustments
- Emergency queue management
- Integration updates

---

### 7. **InsuranceVault** 🔒 GOVERNANCE RECOMMENDED
**Owner:** Governance Contract

**Why:**
- Fund management
- Claim processing
- Emergency functions

---

## Critical Issues to Fix

### Issue #1: USD/ETH Pricing Confusion ⚠️

**Problem:** Contracts use `0.015 ether` to mean "$0.015" but 0.015 ETH = $45 (at $3000 ETH)

**Affected Contracts:**
- BondingCurve.sol
- ProtocolBonds.sol (FIXED ✓)

**Solution:**
```solidity
// OLD (WRONG):
uint256 public constant INITIAL_PRICE = 0.0003 ether; // $0.0003

// NEW (CORRECT):
uint256 public constant INITIAL_PRICE = 0.0003e18; // $0.0003 USD (1e18 = $1)
```

**Fix Status:**
- ✅ ProtocolBonds: FIXED - Now uses USD pricing (1e18 = $1)
- ❌ BondingCurve: NOT FIXED - Still uses ETH pricing

---

## Deployment Checklist

### Step 1: Deploy All Contracts
```
1. Deploy ECHO
2. Deploy eECHO
3. Deploy EchoNode
4. Deploy Treasury
5. Deploy InsuranceVault
6. Deploy Staking
7. Deploy Referral
8. Deploy LockTiers
9. Deploy BondingCurve
10. Deploy ProtocolBonds
11. Deploy Governance
12. Deploy RedemptionQueue
```

### Step 2: Initial Configuration
```
1. Set up contract references (staking, treasury, etc.)
2. Grant minter roles to appropriate contracts
3. Enable Protocol Bonds
4. Transfer 1M ECHO to BondingCurve
```

### Step 3: Transfer Ownership to Governance
```
Transfer ownership of these contracts to Governance:
✓ ECHO → Governance
✓ eECHO → Governance
✓ Treasury → Governance
✓ Staking → Governance
✓ ProtocolBonds → Governance ⚠️ CRITICAL
✓ EchoNode → Governance
✓ RedemptionQueue → Governance
✓ InsuranceVault → Governance
```

### Step 4: Renounce Where Appropriate
```
Renounce ownership (set to address(0)):
✓ LockTiers
✓ Referral
? BondingCurve (wait until bonding completes)
```

### Step 5: Verify Governance Control
```
Verify Governance can:
1. Call ProtocolBonds.setPriceOracle()
2. Call ProtocolBonds.updateETHPrice()
3. Call ProtocolBonds.enableOracleMode()
4. Call ECHO.grantMinterRole()
5. Call Treasury.allocateFunds()
```

---

## Post-Launch Governance Actions

### Week 1-2: Fixed Price Mode
```
Action: Monitor Protocol Bonds at $0.015 fixed price
Governance: No action needed
```

### Week 2-3: Oracle Deployment
```
Action: Deploy Chainlink ECHO/USD oracle
Governance: No action yet (testing)
```

### Week 3: Switch to Oracle Mode
```
Proposal: "Enable Oracle Mode for Protocol Bonds"
Vote: Community votes on switching from fixed to oracle pricing
Execution:
  1. protocolBonds.setPriceOracle(oracleAddress)
  2. protocolBonds.enableOracleMode()
Result: Protocol Bonds now give 5% discount vs DEX price
```

### Ongoing: Price Updates
```
Option A (Automated): Use Chainlink oracle
Option B (Manual): Governance votes to update prices weekly
  - protocolBonds.updateETHPrice(newPrice)
  - bondingCurve.updateTokenPrice(ETH, newPrice)
```

---

## Summary

**Under Governance Control (8 contracts):**
1. ECHO
2. eECHO
3. Treasury
4. Staking
5. ProtocolBonds ⚠️ CRITICAL
6. EchoNode
7. RedemptionQueue
8. InsuranceVault

**Can Be Renounced (3 contracts):**
1. LockTiers
2. Referral
3. BondingCurve (after completion)

**Never Renounce (1 contract):**
1. Governance

---

## Critical Fix Needed

**BondingCurve.sol** still has ETH/USD pricing confusion. Options:

1. **Fix before deployment** (recommended)
2. **Keep owner and update prices** via governance
3. **Accept hardcoded $3000 ETH price** and renounce

**Recommendation:** Fix BondingCurve to use USD pricing like ProtocolBonds, OR keep BondingCurve under governance control until bonding completes.
