// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IeECHO.sol";

/**
 * @title LockTiers
 * @notice Voluntary cliff locks for bonus multipliers
 * @dev Lock eECHO for 30/90/180/365 days to earn 1.2x-4x multipliers
 *
 * Lock Tiers:
 * - 30 days: 1.2x multiplier
 * - 90 days: 2x multiplier
 * - 180 days: 3x multiplier
 * - 365 days: 4x multiplier
 *
 * Early unlock: Time-based penalty (90% → 10% over lock duration)
 */
contract LockTiers is Ownable, ReentrancyGuard {
    // ============ State Variables ============

    IeECHO public immutable eEcho;

    struct Lock {
        uint256 amount;       // Locked eECHO
        uint256 lockTime;     // When locked
        uint256 unlockTime;   // When can unlock
        uint8 tier;           // 0=none, 1=30d, 2=90d, 3=180d, 4=365d
    }

    mapping(address => Lock) public locks;

    // Lock durations
    uint256[5] public lockDurations = [0, 30 days, 90 days, 180 days, 365 days];

    // Multipliers (in basis points: 100 = 1x)
    uint256[5] public multipliers = [100, 120, 200, 300, 400]; // 1×, 1.2×, 2×, 3×, 4×

    // Early unlock penalty (time-based: 90% → 10%)
    uint256 public constant MAX_EARLY_UNLOCK_PENALTY = 9000; // 90% at start
    uint256 public constant MIN_EARLY_UNLOCK_PENALTY = 1000; // 10% at end

    // ============ Events ============

    event Locked(address indexed user, uint256 amount, uint8 tier, uint256 unlockTime);
    event Unlocked(address indexed user, uint256 amount);
    event ExtendedLock(address indexed user, uint8 newTier, uint256 newUnlockTime);
    event ForcedUnlock(address indexed user, uint256 amount, uint256 penalty);

    // ============ Constructor ============

    constructor(address _eEcho) Ownable(msg.sender) {
        eEcho = IeECHO(_eEcho);
    }

    // ============ Lock Management ============

    /**
     * @notice Lock eECHO tokens for a specific tier
     * @param amount Amount to lock
     * @param tier Lock tier (1-4)
     */
    function lockTokens(uint256 amount, uint8 tier) external nonReentrant {
        require(amount > 0, "Zero amount");
        require(tier >= 1 && tier <= 4, "Invalid tier");
        require(locks[msg.sender].amount == 0, "Already locked");

        // Transfer eECHO from user
        require(eEcho.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Create lock
        locks[msg.sender] = Lock({
            amount: amount,
            lockTime: block.timestamp,
            unlockTime: block.timestamp + lockDurations[tier],
            tier: tier
        });

        emit Locked(msg.sender, amount, tier, locks[msg.sender].unlockTime);
    }

    /**
     * @notice Extend existing lock to higher tier
     * @param newTier New lock tier (must be higher)
     */
    function extendLock(uint8 newTier) external nonReentrant {
        require(newTier >= 1 && newTier <= 4, "Invalid tier");
        require(locks[msg.sender].amount > 0, "No lock");
        require(newTier > locks[msg.sender].tier, "Must be higher tier");

        Lock storage lock = locks[msg.sender];
        lock.tier = newTier;
        lock.unlockTime = block.timestamp + lockDurations[newTier];

        emit ExtendedLock(msg.sender, newTier, lock.unlockTime);
    }

    /**
     * @notice Unlock tokens after lock period
     */
    function unlock() external nonReentrant {
        require(locks[msg.sender].amount > 0, "No lock");
        require(block.timestamp >= locks[msg.sender].unlockTime, "Still locked");

        uint256 amount = locks[msg.sender].amount;

        // Clear lock
        delete locks[msg.sender];

        // Transfer eECHO back to user
        require(eEcho.transfer(msg.sender, amount), "Transfer failed");

        emit Unlocked(msg.sender, amount);
    }

    /**
     * @notice Force unlock with time-based penalty
     * @dev Penalty decreases from 90% to 10% over lock duration
     */
    function forceUnlock() external nonReentrant {
        require(locks[msg.sender].amount > 0, "No lock");

        Lock memory lock = locks[msg.sender];
        uint256 amount = lock.amount;

        // Calculate time-based penalty
        uint256 penaltyPercent = calculateEarlyUnlockPenalty(msg.sender);
        uint256 penalty = (amount * penaltyPercent) / 10000;
        uint256 netAmount = amount - penalty;

        // Clear lock
        delete locks[msg.sender];

        // Burn penalty amount
        eEcho.transfer(address(1), penalty); // Send to burn address

        // Transfer remaining to user
        require(eEcho.transfer(msg.sender, netAmount), "Transfer failed");

        emit ForcedUnlock(msg.sender, netAmount, penalty);
    }

    /**
     * @notice Calculate early unlock penalty based on time served
     * @dev Penalty = 90% - (80% × timeServed / totalDuration)
     * @param user Address to calculate penalty for
     * @return Penalty percentage in basis points (10000 = 100%)
     */
    function calculateEarlyUnlockPenalty(address user) public view returns (uint256) {
        Lock memory lock = locks[user];
        require(lock.amount > 0, "No lock");

        // Calculate total lock duration
        uint256 totalDuration = lockDurations[lock.tier];
        require(totalDuration > 0, "Invalid tier");

        // Calculate time served
        uint256 timeServed = block.timestamp - lock.lockTime;

        // If already past unlock time, no penalty (shouldn't happen, but safe)
        if (timeServed >= totalDuration) {
            return MIN_EARLY_UNLOCK_PENALTY;
        }

        // Penalty decreases linearly: 90% → 10%
        // Formula: 90% - (80% × timeServed / totalDuration)
        // Range: 9000 - 1000 = 8000 basis points
        uint256 penaltyReduction = (8000 * timeServed) / totalDuration;
        uint256 penalty = MAX_EARLY_UNLOCK_PENALTY - penaltyReduction;

        return penalty;
    }

    // ============ View Functions ============

    function getMultiplier(address user) external view returns (uint256) {
        return multipliers[locks[user].tier];
    }

    function getLockInfo(address user) external view returns (Lock memory) {
        return locks[user];
    }

    function isLocked(address user) external view returns (bool) {
        return locks[user].amount > 0;
    }

    function getTimeRemaining(address user) external view returns (uint256) {
        if (locks[user].amount == 0) return 0;
        if (block.timestamp >= locks[user].unlockTime) return 0;
        return locks[user].unlockTime - block.timestamp;
    }
}
