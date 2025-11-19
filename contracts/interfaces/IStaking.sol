// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStaking
 * @notice Interface for the Staking contract
 */
interface IStaking {
    /**
     * @notice Emitted when user stakes tokens
     * @param user Address of the staker
     * @param amount Amount staked
     * @param referrer Address of referrer
     */
    event Staked(address indexed user, uint256 amount, address indexed referrer);

    /**
     * @notice Emitted when user unstakes tokens
     * @param user Address of the user
     * @param amount Amount unstaked
     * @param penalty Penalty amount applied
     */
    event Unstaked(address indexed user, uint256 amount, uint256 penalty);

    /**
     * @notice Emitted when rewards are claimed
     * @param user Address of the user
     * @param amount Amount of rewards claimed
     */
    event RewardsClaimed(address indexed user, uint256 amount);

    /**
     * @notice Stake ECHO tokens
     * @param amount Amount to stake
     * @param referrer Address of referrer (zero address if none)
     */
    function stake(uint256 amount, address referrer) external;

    /**
     * @notice Request to unstake tokens (starts cooldown)
     * @param amount Amount to unstake
     */
    function requestUnstake(uint256 amount) external;

    /**
     * @notice Unstake tokens after cooldown
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Claim pending rewards
     */
    function claimRewards() external;

    /**
     * @notice Compound rewards back into stake
     */
    function compound() external;

    /**
     * @notice Calculate unstake penalty for an amount
     * @param amount Amount to unstake
     * @return penalty Penalty amount
     */
    function calculateUnstakePenalty(uint256 amount) external view returns (uint256 penalty);

    /**
     * @notice Get staked balance for a user
     * @param user Address to check
     * @return Staked amount in eECHO
     */
    function getStakedBalance(address user) external view returns (uint256);

    /**
     * @notice Get pending rewards for a user
     * @param user Address to check
     * @return Pending rewards
     */
    function getPendingRewards(address user) external view returns (uint256);

    /**
     * @notice Get current staking ratio
     * @return Ratio in basis points
     */
    function getStakingRatio() external view returns (uint256);
}
