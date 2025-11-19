// Contract ABIs (simplified - import from artifacts in production)
export const CONTRACTS = {
  ECHO: {
    address: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    abi: [
      "function balanceOf(address) view returns (uint256)",
      "function totalSupply() view returns (uint256)",
      "function approve(address spender, uint256 amount) returns (bool)",
      "function getCurrentTaxRate() view returns (uint256)",
      "function totalBurned() view returns (uint256)",
      "function transfer(address to, uint256 amount) returns (bool)",
    ],
  },
  eECHO: {
    address: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    abi: [
      "function balanceOf(address) view returns (uint256)",
      "function wrap(uint256 amount) returns (uint256)",
      "function unwrap(uint256 amount) returns (uint256)",
      "function rebase() returns (uint256)",
      "function getCurrentRebaseRate() view returns (uint256)",
      "function nextRebaseTime() view returns (uint256)",
      "function backingRatio() view returns (uint256)",
      "function epoch() view returns (uint256)",
    ],
  },
  EchoNode: {
    address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
    abi: [
      "function ownerToNodeId(address) view returns (uint256)",
      "function getNodeData(uint256) view returns (tuple(uint256 stakedAmount, uint256 totalRewardsEarned, uint256 nodeCreationTime, address referrer, uint256 directReferralCount, uint256 totalReferralVolume, uint256 lastActivityTime, uint8 tierLevel, bool isSoulbound, uint8 lockTier, uint256 lockExpiry))",
      "function tokenURI(uint256) view returns (string)",
      "function calculateTier(uint256) pure returns (uint8)",
    ],
  },
  Staking: {
    address: "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707",
    abi: [
      "function stake(uint256 amount, address referrer)",
      "function requestUnstake(uint256 amount)",
      "function unstake(uint256 amount)",
      "function claimRewards()",
      "function compound()",
      "function getStakedBalance(address) view returns (uint256)",
      "function getPendingRewards(address) view returns (uint256)",
      "function calculateUnstakePenalty(uint256) view returns (uint256)",
      "function getStakingRatio() view returns (uint256)",
    ],
  },
  Referral: {
    address: "0x0165878A594ca255338adfa4d48449f69242Eb8F",
    abi: [
      "function getReferralData(address) view returns (tuple(address referrer, address[] directReferrals, uint256 totalReferralVolume, uint256 totalEarned))",
      "function getDirectReferrals(address) view returns (address[])",
      "function hasReferrer(address) view returns (bool)",
    ],
  },
  Treasury: {
    address: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    abi: [
      "function getBackingRatio() view returns (uint256)",
      "function getTotalValue() view returns (uint256)",
      "function getLiquidValue() view returns (uint256)",
      "function getRunway() view returns (uint256)",
      "function shouldExecuteBuyback() view returns (bool)",
    ],
  },
  BondingCurve: {
    address: "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6",
    abi: [
      "function buyWithETH() payable returns (uint256)",
      "function getCurrentPrice() view returns (uint256)",
      "function getEchoAmount(uint256, address) view returns (uint256)",
      "function totalEchoSold() view returns (uint256)",
    ],
  },
  LockTiers: {
    address: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
    abi: [
      "function lockTokens(uint256 amount, uint8 tier)",
      "function unlock()",
      "function forceUnlock()",
      "function getLockInfo(address) view returns (tuple(uint256 amount, uint256 lockTime, uint256 unlockTime, uint8 tier))",
      "function getTimeRemaining(address) view returns (uint256)",
    ],
  },
};

export const CHAIN_CONFIG = {
  arbitrumOne: {
    chainId: 42161,
    name: "Arbitrum One",
    rpcUrl: "https://arb1.arbitrum.io/rpc",
    blockExplorer: "https://arbiscan.io",
  },
  arbitrumSepolia: {
    chainId: 421614,
    name: "Arbitrum Sepolia",
    rpcUrl: "https://sepolia-rollup.arbitrum.io/rpc",
    blockExplorer: "https://sepolia.arbiscan.io",
  },
};
