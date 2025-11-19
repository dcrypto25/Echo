const hre = require("hardhat");

async function main() {
  console.log("🚀 EchoForge Deployment Starting...\n");

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.address)).toString(), "\n");

  // ============ Step 1: Deploy Core Tokens ============
  console.log("📝 Step 1: Deploying Core Tokens...");

  const INITIAL_SUPPLY = hre.ethers.parseEther("1000000"); // 1M ECHO for bonding curve

  const ECHO = await hre.ethers.getContractFactory("ECHO");
  const echo = await ECHO.deploy(INITIAL_SUPPLY);
  await echo.waitForDeployment();
  console.log("✅ ECHO deployed to:", await echo.getAddress());

  const eECHO = await hre.ethers.getContractFactory("eECHO");
  const eEcho = await eECHO.deploy(await echo.getAddress());
  await eEcho.waitForDeployment();
  console.log("✅ eECHO deployed to:", await eEcho.getAddress());

  // ============ Step 2: Deploy Echo Node NFT ============
  console.log("\n📝 Step 2: Deploying Echo Node NFT...");

  const EchoNode = await hre.ethers.getContractFactory("EchoNode");
  const echoNode = await EchoNode.deploy();
  await echoNode.waitForDeployment();
  console.log("✅ EchoNode deployed to:", await echoNode.getAddress());

  // ============ Step 3: Deploy Treasury & Insurance ============
  console.log("\n📝 Step 3: Deploying Treasury & Insurance...");

  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(await echo.getAddress(), await eEcho.getAddress());
  await treasury.waitForDeployment();
  console.log("✅ Treasury deployed to:", await treasury.getAddress());

  const InsuranceVault = await hre.ethers.getContractFactory("InsuranceVault");
  const insurance = await InsuranceVault.deploy(await treasury.getAddress());
  await insurance.waitForDeployment();
  console.log("✅ InsuranceVault deployed to:", await insurance.getAddress());

  // ============ Step 4: Deploy Staking & Referral ============
  console.log("\n📝 Step 4: Deploying Staking & Referral...");

  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(
    await echo.getAddress(),
    await eEcho.getAddress(),
    await echoNode.getAddress()
  );
  await staking.waitForDeployment();
  console.log("✅ Staking deployed to:", await staking.getAddress());

  const Referral = await hre.ethers.getContractFactory("Referral");
  const referral = await Referral.deploy(
    await echo.getAddress(),
    await echoNode.getAddress()
  );
  await referral.waitForDeployment();
  console.log("✅ Referral deployed to:", await referral.getAddress());

  // ============ Step 5: Deploy Lock Tiers ============
  console.log("\n📝 Step 5: Deploying Lock Tiers...");

  const LockTiers = await hre.ethers.getContractFactory("LockTiers");
  const lockTiers = await LockTiers.deploy(
    await eEcho.getAddress(),
    await echoNode.getAddress()
  );
  await lockTiers.waitForDeployment();
  console.log("✅ LockTiers deployed to:", await lockTiers.getAddress());

  // ============ Step 6: Deploy Bonding Curve ============
  console.log("\n📝 Step 6: Deploying Bonding Curve...");

  const BondingCurve = await hre.ethers.getContractFactory("BondingCurve");
  const bondingCurve = await BondingCurve.deploy(
    await echo.getAddress(),
    await treasury.getAddress()
  );
  await bondingCurve.waitForDeployment();
  console.log("✅ BondingCurve deployed to:", await bondingCurve.getAddress());

  // ============ Step 6.5: Deploy Protocol Bonds ============
  console.log("\n📝 Step 6.5: Deploying Protocol Bonds...");

  const ProtocolBonds = await hre.ethers.getContractFactory("ProtocolBonds");
  const protocolBonds = await ProtocolBonds.deploy(
    await echo.getAddress(),
    await eEcho.getAddress(),
    await treasury.getAddress(),
    await bondingCurve.getAddress()
  );
  await protocolBonds.waitForDeployment();
  console.log("✅ ProtocolBonds deployed to:", await protocolBonds.getAddress());

  // ============ Step 7: Deploy Governance ============
  console.log("\n📝 Step 7: Deploying Governance...");

  const Governance = await hre.ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(await echoNode.getAddress());
  await governance.waitForDeployment();
  console.log("✅ Governance deployed to:", await governance.getAddress());

  // ============ Step 8: Deploy Redemption Queue ============
  console.log("\n📝 Step 8: Deploying Redemption Queue...");

  const RedemptionQueue = await hre.ethers.getContractFactory("RedemptionQueue");
  const redemptionQueue = await RedemptionQueue.deploy(await treasury.getAddress());
  await redemptionQueue.waitForDeployment();
  console.log("✅ RedemptionQueue deployed to:", await redemptionQueue.getAddress());

  // ============ Step 9: Configure Contracts ============
  console.log("\n📝 Step 9: Configuring Contracts...");

  // Configure ECHO
  await echo.setEchoPool(await staking.getAddress());
  console.log("✅ ECHO: Echo Pool set");

  await echo.setTreasury(await treasury.getAddress());
  console.log("✅ ECHO: Treasury set");

  await echo.setStakingContract(await staking.getAddress());
  console.log("✅ ECHO: Staking contract set");

  // Configure eECHO
  await eEcho.setTreasury(await treasury.getAddress());
  console.log("✅ eECHO: Treasury set");

  // Configure EchoNode
  await echoNode.setStakingContract(await staking.getAddress());
  console.log("✅ EchoNode: Staking contract set");

  await echoNode.setReferralContract(await referral.getAddress());
  console.log("✅ EchoNode: Referral contract set");

  // Configure Staking
  await staking.setReferral(await referral.getAddress());
  console.log("✅ Staking: Referral set");

  await staking.setTreasury(await treasury.getAddress());
  console.log("✅ Staking: Treasury set");

  // Configure Referral
  await referral.setStakingContract(await staking.getAddress());
  console.log("✅ Referral: Staking contract set");

  // Configure Protocol Bonds
  await echo.grantMinterRole(await protocolBonds.getAddress());
  console.log("✅ ProtocolBonds: Minter role granted");

  // Enable Protocol Bonds immediately (no delay)
  await protocolBonds.enableBonds();
  console.log("✅ ProtocolBonds: Enabled from launch");

  // Transfer ECHO to bonding curve
  await echo.transfer(await bondingCurve.getAddress(), INITIAL_SUPPLY);
  console.log("✅ Transferred 1M ECHO to BondingCurve");

  // ============ Deployment Summary ============
  console.log("\n");
  console.log("=".repeat(60));
  console.log("🎉 EchoForge Deployment Complete!");
  console.log("=".repeat(60));
  console.log("\nContract Addresses:");
  console.log("─".repeat(60));
  console.log("ECHO Token:          ", await echo.getAddress());
  console.log("eECHO Token:         ", await eEcho.getAddress());
  console.log("EchoNode NFT:        ", await echoNode.getAddress());
  console.log("Treasury:            ", await treasury.getAddress());
  console.log("Insurance Vault:     ", await insurance.getAddress());
  console.log("Staking:             ", await staking.getAddress());
  console.log("Referral:            ", await referral.getAddress());
  console.log("Lock Tiers:          ", await lockTiers.getAddress());
  console.log("Bonding Curve:       ", await bondingCurve.getAddress());
  console.log("Protocol Bonds:      ", await protocolBonds.getAddress());
  console.log("Governance:          ", await governance.getAddress());
  console.log("Redemption Queue:    ", await redemptionQueue.getAddress());
  console.log("─".repeat(60));
  console.log("\nLaunch Mechanisms:");
  console.log("─".repeat(60));
  console.log("Total ECHO Minted:   1,000,000 ECHO");
  console.log("  └─ Bonding Curve:  1,000,000 ECHO ($0.0003 → $0.015)");
  console.log("\nProtocol Bonds:      ENABLED from day 1");
  console.log("  └─ 5% discount on market price");
  console.log("  └─ Accepts: ETH, USDC, USDT, DAI");
  console.log("  └─ 5-day vesting in eECHO");
  console.log("─".repeat(60));

  // Save deployment info
  const deployment = {
    network: hre.network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      ECHO: await echo.getAddress(),
      eECHO: await eEcho.getAddress(),
      EchoNode: await echoNode.getAddress(),
      Treasury: await treasury.getAddress(),
      InsuranceVault: await insurance.getAddress(),
      Staking: await staking.getAddress(),
      Referral: await referral.getAddress(),
      LockTiers: await lockTiers.getAddress(),
      BondingCurve: await bondingCurve.getAddress(),
      ProtocolBonds: await protocolBonds.getAddress(),
      Governance: await governance.getAddress(),
      RedemptionQueue: await redemptionQueue.getAddress(),
    },
  };

  const fs = require("fs");
  fs.writeFileSync(
    `deployments-${hre.network.name}.json`,
    JSON.stringify(deployment, null, 2)
  );

  console.log(`\n✅ Deployment info saved to deployments-${hre.network.name}.json`);
  console.log("\n🚀 Next Steps:");
  console.log("1. Launch bonding curve: await bondingCurve.launch()");
  console.log("2. Users can IMMEDIATELY:");
  console.log("   ✓ Buy via Bonding Curve ($0.0003 → $0.015)");
  console.log("   ✓ Buy via Protocol Bonds (5% discount, 5-day vest)");
  console.log("   ✓ Sellers must provide DEX liquidity (organic LP!)");
  console.log("3. After bonding completes:");
  console.log("   - Treasury: ~$9,500");
  console.log("   - Backing: 63% at $0.015 price");
  console.log("   - Protocol Bonds continue (helps grow treasury)");
  console.log("4. Verify contracts on block explorer");
  console.log("5. Transfer ownership to DAO multisig");
  console.log("6. Deploy frontend");
  console.log("\n💡 Strategy: No protocol LP needed! Users wanting to sell");
  console.log("   will create organic liquidity. Protocol Bonds grow treasury.");
  console.log("\n" + "=".repeat(60) + "\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
