# EchoForge - Getting Started Guide

## Project Overview

EchoForge is a fully decentralized, treasury-backed reserve currency with:
- 8,000% starting APY
- 10-level referral system
- Dynamic unstake penalty (anti-death spiral)
- NFT tier progression system
- Real yield from GMX/GLP
- 100% fair launch via bonding curve

---

## Project Structure

```
echo/
├── contracts/                 # Smart contracts
│   ├── core/                 # Core tokens (ECHO, eECHO, EchoNode)
│   ├── mechanisms/           # Staking, Referral, LockTiers, etc.
│   ├── treasury/             # Treasury, InsuranceVault
│   ├── governance/           # DAO governance
│   └── interfaces/           # Contract interfaces
├── frontend/                 # React frontend
│   ├── src/
│   │   ├── components/      # UI components
│   │   ├── config/          # Contract configurations
│   │   └── hooks/           # Custom React hooks
│   └── public/
├── scripts/                  # Deployment scripts
├── test/                     # Contract tests
└── docs/                     # Documentation
```

---

## Smart Contracts Implemented

### ✅ Core Contracts (3)
1. **ECHO.sol** - Main ERC20 with adaptive transfer tax
2. **eECHO.sol** - Rebasing wrapper with backing-linked dampener
3. **EchoNode.sol** - ERC721 NFT tier system (Bronze → Diamond)

### ✅ Mechanism Contracts (5)
4. **BondingCurve.sol** - Fair launch bonding curve
5. **Staking.sol** - Core staking with Dynamic Unstake Penalty
6. **Referral.sol** - 10-level referral tree with echo-back
7. **LockTiers.sol** - Voluntary cliff locks (30d-365d)
8. **RedemptionQueue.sol** - Anti-rush unstaking queue

### ✅ Treasury Contracts (2)
9. **Treasury.sol** - Forge Reserve with buyback engine
10. **InsuranceVault.sol** - Emergency backing fund

### ✅ Governance (1)
11. **Governance.sol** - DAO voting system

### ✅ Interfaces (6)
- IECHO, IeECHO, IEchoNode, ITreasury, IStaking, IReferral

**Total**: 11 production contracts + 6 interfaces

---

## Installation & Setup

### Prerequisites

```bash
- Node.js v18+
- npm or yarn
- Git
```

### 1. Install Dependencies

```bash
# Install contract dependencies
npm install

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values:
# - ARBITRUM_RPC_URL
# - PRIVATE_KEY (for deployment)
# - ARBISCAN_API_KEY (for verification)
```

### 3. Compile Contracts

```bash
npx hardhat compile
```

Expected output: All 11 contracts compile successfully.

---

## Deployment

### Deploy to Arbitrum Sepolia (Testnet)

```bash
npx hardhat run scripts/deploy.js --network arbitrumSepolia
```

This will:
1. Deploy all 11 contracts
2. Configure contract connections
3. Transfer initial ECHO to bonding curve
4. Save deployment addresses to `deployments-arbitrumSepolia.json`

### Deploy to Arbitrum One (Mainnet)

```bash
# ⚠️ MAINNET - Double check everything first!
npx hardhat run scripts/deploy.js --network arbitrumOne
```

### Verify Contracts

```bash
npx hardhat verify --network arbitrumSepolia <CONTRACT_ADDRESS>
```

---

## Frontend Development

### 1. Configure Contract Addresses

After deployment, update `frontend/src/config/contracts.js` with deployed addresses:

```javascript
export const CONTRACTS = {
  ECHO: { address: "0x..." },
  eECHO: { address: "0x..." },
  EchoNode: { address: "0x..." },
  // ... etc
};
```

### 2. Start Frontend

```bash
cd frontend
npm start
```

Frontend will be available at `http://localhost:3000`

### 3. Frontend Features

- **Dashboard**: Protocol stats, APY, backing ratio, runway
- **Bond**: Buy ECHO via bonding curve
- **Stake**: Stake ECHO, earn 8,000% APY
- **Referrals**: Generate referral link, track earnings

---

## Testing

### Run Contract Tests

```bash
# Run all tests
npx hardhat test

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Run specific test
npx hardhat test test/ECHO.test.js
```

### Test Coverage

```bash
npx hardhat coverage
```

---

## Post-Deployment Checklist

### 1. Launch Bonding Curve

```javascript
const bondingCurve = await ethers.getContractAt("BondingCurve", BONDING_CURVE_ADDRESS);
await bondingCurve.launch();
```

### 2. Transfer Ownership to DAO

```javascript
// Create 9-of-15 multisig (Gnosis Safe recommended)
const daoMultisig = "0x...";

// Transfer all contracts to DAO
await echo.transferOwnership(daoMultisig);
await eEcho.transferOwnership(daoMultisig);
await echoNode.transferOwnership(daoMultisig);
// ... repeat for all contracts
```

### 3. Verify on Arbiscan

```bash
npx hardhat verify --network arbitrumOne <address> <constructor-args>
```

### 4. Update Frontend

- Deploy frontend to IPFS or Vercel
- Set up ENS domain (optional)
- Enable analytics

### 5. Community Launch

- Announce on Twitter/Discord/Telegram
- Share bonding curve link
- Activate referral system

---

## Key Features Implemented

### ✅ Adaptive Transfer Tax
- 4% base tax, scales to 15% when staking ratio < 88%
- 50% to Echo Pool, 50% to Treasury
- Whitelisting for DEXs/bridges

### ✅ Rebasing with Dampener
- Automatic balance increase every 8 hours
- Dampener scales 0-100% based on backing ratio
- Protects against negative rebases

### ✅ Dynamic Unstake Penalty
- 0% penalty when backing > 150%
- 75% penalty when backing < 80%
- Linear scaling between thresholds
- 50% burned, 50% to top 100 nodes

### ✅ 10-Level Referral System
- L1: 4%, L2: 2%, L3-L10: 1% each
- Total max: 11% on all downstream volume
- Tier multipliers: 1× to 6× (Bronze to Diamond)
- 25% echo-back boosts referrer's node

### ✅ NFT Tier System
- Bronze → Silver → Gold → Platinum → Diamond
- Volume thresholds: $10K → $100M+
- Multipliers increase with tier
- On-chain SVG metadata

### ✅ Treasury Features
- Backing ratio calculation
- Automatic buyback when price < 75% TWAP
- Yield deployment to GMX/GLP
- Runway calculation

---

## Common Commands

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to testnet
npx hardhat run scripts/deploy.js --network arbitrumSepolia

# Verify contract
npx hardhat verify --network arbitrumSepolia <address>

# Start local node
npx hardhat node

# Run frontend
cd frontend && npm start

# Build frontend
cd frontend && npm run build
```

---

## Troubleshooting

### Contract Compilation Errors

```bash
# Clean cache and recompile
npx hardhat clean
npx hardhat compile
```

### Frontend Build Errors

```bash
# Clear node_modules and reinstall
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Transaction Failures

- Check gas settings (Arbitrum uses lower gas)
- Ensure sufficient ETH for gas
- Verify contract addresses are correct
- Check allowances for token approvals

---

## Security Considerations

### Pre-Launch
- [ ] Complete 3 independent audits
- [ ] Run comprehensive test suite
- [ ] Stress test on mainnet fork
- [ ] Set up bug bounty program
- [ ] Prepare emergency pause mechanisms

### Post-Launch
- [ ] Monitor treasury backing ratio
- [ ] Watch for unusual transaction patterns
- [ ] Regular security reviews
- [ ] Community governance active
- [ ] Insurance vault funded

---

## Resources

- **Documentation**: `/docs` folder
- **Contracts**: `/contracts` folder
- **Frontend**: `/frontend` folder
- **Tests**: `/test` folder (to be created)

---

## Next Steps

1. **Test on Arbitrum Sepolia**
   - Deploy all contracts
   - Test full user flow
   - Verify all mechanics work

2. **Security Audits**
   - Engage Hackensight
   - Engage CertiK
   - Engage PeckShield

3. **Mainnet Deployment**
   - Deploy to Arbitrum One
   - Transfer to DAO multisig
   - Launch bonding curve

4. **Community Launch**
   - Announce to community
   - Activate referral system
   - Monitor protocol health

---

## Support

For issues or questions:
- GitHub: https://github.com/dcrypto25/Echo
- Discord: (to be created)
- Twitter: (to be created)
- Docs: `/docs` folder

---

Built with community, powered by alignment.

**"$OHM was the prototype. $ECHO is the final form."**
