// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IECHO.sol";
import "../interfaces/IeECHO.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStaking.sol";

/**
 * @title Staking
 * @notice Core staking contract with Dynamic Unstake Penalty (DUP)
 * @dev Stakes ECHO, mints eECHO, distributes referral bonuses
 *
 * Key Features:
 * - Dynamic unstake penalty based on treasury backing (0-75%)
 * - Dynamic cooldown period (1-7 days based on backing ratio)
 * - Referral bonus distribution
 * - Penalty split: 50% burned, 50% to treasury (helps restore protocol health)
 */
contract Staking is Ownable, ReentrancyGuard, IStaking {
    // ============ State Variables ============

    // Core contracts
    IECHO public immutable echo;
    IeECHO public immutable eEcho;
    IReferral public referral;
    ITreasury public treasury;

    // Staking data
    struct StakeInfo {
        uint256 amount;           // eECHO balance
        uint256 depositTime;      // When staked
        uint256 lastClaimTime;    // Last reward claim
        uint256 totalClaimed;     // Lifetime claims
    }

    mapping(address => StakeInfo) public stakes;

    // Unstake penalty configuration (in basis points)
    uint256 public constant MIN_BACKING_ZERO_PENALTY = 12000;  // 120% backing = 0% penalty
    uint256 public constant MAX_PENALTY_BACKING = 5000;        // 50% backing = 75% penalty
    uint256 public constant MAX_PENALTY_PERCENT = 7500;        // 75% max penalty

    // Dynamic unstake cooldown (1-7 days based on backing)
    uint256 public constant MIN_COOLDOWN = 1 days;       // 120%+ backing = 1 day
    uint256 public constant MAX_COOLDOWN = 7 days;       // 50% backing = 7 days
    mapping(address => uint256) public unstakeRequests;

    // Total staked tracking
    uint256 public totalStaked;

    // ============ Events ============

    event UnstakeRequested(address indexed user, uint256 amount, uint256 availableAt);
    event Compounded(address indexed user, uint256 amount);

    // ============ Constructor ============

    constructor(
        address _echo,
        address _eEcho
    ) Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        require(_eEcho != address(0), "Zero address");

        echo = IECHO(_echo);
        eEcho = IeECHO(_eEcho);
    }

    // ============ Configuration ============

    function setReferral(address _referral) external onlyOwner {
        require(address(referral) == address(0), "Already set");
        referral = IReferral(_referral);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(address(treasury) == address(0), "Already set");
        treasury = ITreasury(_treasury);
    }

    // ============ Staking ============

    /**
     * @notice Stake ECHO tokens
     * @param amount Amount to stake
     * @param referrer Address of referrer (zero address if none)
     */
    function stake(uint256 amount, address referrer) external override nonReentrant {
        require(amount > 0, "Zero amount");
        require(referrer != msg.sender, "Cannot refer yourself");

        // Transfer ECHO from user
        require(echo.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Approve eECHO contract to wrap
        echo.approve(address(eEcho), amount);

        // Wrap to eECHO
        uint256 eEchoAmount = eEcho.wrap(amount);

        // Record referral on first stake
        if (stakes[msg.sender].amount == 0 && referrer != address(0) && referrer != msg.sender) {
            referral.recordReferral(msg.sender, referrer);
        }

        // Update stake info
        StakeInfo storage stakeInfo = stakes[msg.sender];
        stakeInfo.amount += eEchoAmount;
        if (stakeInfo.depositTime == 0) {
            stakeInfo.depositTime = block.timestamp;
        }
        if (stakeInfo.lastClaimTime == 0) {
            stakeInfo.lastClaimTime = block.timestamp;
        }

        // Update total staked
        totalStaked += amount;

        // Distribute referral bonuses
        if (referrer != address(0)) {
            referral.distributeReferralBonus(msg.sender, amount);
            referral.applyEchoBack(referrer, amount);
        }

        // Update staking ratio in ECHO contract
        _updateStakingRatio();

        emit Staked(msg.sender, amount, referrer);
    }

    // ============ Unstaking ============

    /**
     * @notice Request unstake (starts cooldown)
     * @param amount Amount to unstake
     */
    function requestUnstake(uint256 amount) external override {
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");

        unstakeRequests[msg.sender] = block.timestamp;

        uint256 cooldown = calculateUnstakeCooldown();

        emit UnstakeRequested(
            msg.sender,
            amount,
            block.timestamp + cooldown
        );
    }

    /**
     * @notice Unstake tokens after cooldown
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external override nonReentrant {
        require(amount > 0, "Zero amount");
        require(stakes[msg.sender].amount >= amount, "Insufficient stake");

        uint256 requiredCooldown = calculateUnstakeCooldown();
        require(
            block.timestamp >= unstakeRequests[msg.sender] + requiredCooldown,
            "Cooldown not complete"
        );

        // Calculate penalty
        uint256 penalty = calculateUnstakePenalty(amount);
        uint256 netAmount = amount - penalty;

        // Update stake info
        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        // Unwrap eECHO to ECHO
        uint256 echoAmount = eEcho.unwrap(amount);

        // Distribute penalty if any
        if (penalty > 0) {
            uint256 burnAmount = penalty / 2;
            uint256 treasuryAmount = penalty - burnAmount;

            // Burn half (helps reduce supply, increases backing ratio)
            echo.approve(address(echo), burnAmount);
            echo.burn(burnAmount);

            // Send other half to treasury (gives treasury ECHO for buybacks/holding)
            require(echo.transfer(address(treasury), treasuryAmount), "Treasury transfer failed");

            // Net amount after penalty
            netAmount = echoAmount - penalty;
        } else {
            netAmount = echoAmount;
        }

        // Transfer ECHO to user
        require(echo.transfer(msg.sender, netAmount), "Transfer failed");

        // Update staking ratio
        _updateStakingRatio();

        emit Unstaked(msg.sender, amount, penalty);
    }

    // ============ Rewards ============

    /**
     * @notice Claim pending rewards
     */
    function claimRewards() external override nonReentrant {
        uint256 rewards = getPendingRewards(msg.sender);
        require(rewards > 0, "No rewards");

        stakes[msg.sender].lastClaimTime = block.timestamp;
        stakes[msg.sender].totalClaimed += rewards;

        // Rewards come from rebasing, already in eECHO balance
        // This is a claim event for tracking

        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Compound rewards back into stake
     */
    function compound() external override nonReentrant {
        uint256 rewards = getPendingRewards(msg.sender);
        require(rewards > 0, "No rewards");

        stakes[msg.sender].lastClaimTime = block.timestamp;
        stakes[msg.sender].amount += rewards;

        emit Compounded(msg.sender, rewards);
    }

    // ============ Penalty Calculation ============

    /**
     * @notice Calculate unstake penalty based on backing ratio (EXPONENTIAL CURVE)
     * @param amount Amount to unstake
     * @return penalty Penalty amount
     *
     * @dev Penalty curve:
     * - 120%+ backing = 0% penalty (very healthy protocol, free to unstake)
     * - 110% backing = ~1.5% penalty
     * - 100% backing = ~6.1% penalty
     * - 90% backing = ~13.8% penalty
     * - 80% backing = ~24.5% penalty
     * - 70% backing = ~38.3% penalty
     * - 60% backing = ~55.1% penalty
     * - 50% backing = 75% penalty (crisis mode)
     *
     * Formula: penalty = 75% * ((120% - ratio) / 70%)^2
     * This exponential curve always has some penalty to protect protocol health,
     * but minimal friction when backing is strong (>120%)
     */
    function calculateUnstakePenalty(uint256 amount)
        public
        view
        override
        returns (uint256 penalty)
    {
        uint256 backingRatio = treasury.getBackingRatio();

        // No penalty if backing >= 120%
        if (backingRatio >= MIN_BACKING_ZERO_PENALTY) {
            return 0;
        }

        // Max penalty (75%) if backing <= 50%
        if (backingRatio <= MAX_PENALTY_BACKING) {
            return (amount * MAX_PENALTY_PERCENT) / 10000;
        }

        // Exponential scale between 50% and 120%
        // penalty = 75% * ((120% - current%) / 70%)^2
        uint256 deficit = MIN_BACKING_ZERO_PENALTY - backingRatio; // 0-7000 (0-70%)
        uint256 range = MIN_BACKING_ZERO_PENALTY - MAX_PENALTY_BACKING; // 7000 (70%)

        // Calculate (deficit / range)^2
        // = (deficit * deficit) / (range * range)
        uint256 deficitSquared = (deficit * deficit);
        uint256 rangeSquared = (range * range);

        // penaltyPercent = 75% * deficitSquared / rangeSquared
        uint256 penaltyPercent = (MAX_PENALTY_PERCENT * deficitSquared) / rangeSquared;

        return (amount * penaltyPercent) / 10000;
    }

    /**
     * @notice Calculate dynamic unstake cooldown based on backing ratio
     * @return cooldown Cooldown period in seconds
     *
     * @dev Cooldown curve (linear):
     * - 120%+ backing = 1 day (minimum cooldown)
     * - 100% backing = ~3.9 days
     * - 80% backing = ~5.4 days
     * - 50% backing = 7 days (maximum cooldown)
     *
     * Formula: cooldown = MIN_COOLDOWN + (MAX_COOLDOWN - MIN_COOLDOWN) * ((120% - ratio) / 70%)
     * Linear scale rewards protocol health with faster unstaking
     */
    function calculateUnstakeCooldown()
        public
        view
        returns (uint256 cooldown)
    {
        uint256 backingRatio = treasury.getBackingRatio();

        // Min cooldown if backing >= 120%
        if (backingRatio >= MIN_BACKING_ZERO_PENALTY) {
            return MIN_COOLDOWN;
        }

        // Max cooldown if backing <= 50%
        if (backingRatio <= MAX_PENALTY_BACKING) {
            return MAX_COOLDOWN;
        }

        // Linear scale between 50% and 120%
        // cooldown = MIN + (MAX - MIN) * ((120% - current%) / 70%)
        uint256 deficit = MIN_BACKING_ZERO_PENALTY - backingRatio; // 0-7000 (0-70%)
        uint256 range = MIN_BACKING_ZERO_PENALTY - MAX_PENALTY_BACKING; // 7000 (70%)

        uint256 cooldownRange = MAX_COOLDOWN - MIN_COOLDOWN; // 6 days in seconds
        uint256 additionalCooldown = (cooldownRange * deficit) / range;

        return MIN_COOLDOWN + additionalCooldown;
    }

    // ============ View Functions ============

    function getStakedBalance(address user) external view override returns (uint256) {
        return stakes[user].amount;
    }

    function getPendingRewards(address user) public view override returns (uint256) {
        // Rewards from rebasing are already in the eECHO balance
        // Calculate theoretical rewards since last claim
        uint256 currentBalance = stakes[user].amount;
        uint256 timeElapsed = block.timestamp - stakes[user].lastClaimTime;

        // Simplified reward calculation (actual rewards are from eECHO rebasing)
        // This is for display purposes
        if (timeElapsed == 0) return 0;

        uint256 rebaseRate = eEcho.getCurrentRebaseRate();
        uint256 rebases = timeElapsed / 8 hours;

        uint256 rewards = (currentBalance * rebaseRate * rebases) / 1e18;
        return rewards;
    }

    function getStakingRatio() public view override returns (uint256) {
        uint256 totalSupply = echo.totalSupply();
        if (totalSupply == 0) return 0;

        return (totalStaked * 10000) / totalSupply;
    }

    // ============ Internal Functions ============

    function _updateStakingRatio() private {
        uint256 ratio = getStakingRatio();
        echo.updateStakingRatio(ratio);
    }
}
