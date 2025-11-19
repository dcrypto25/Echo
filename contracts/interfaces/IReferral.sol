// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReferral
 * @notice Interface for the Referral system contract
 */
interface IReferral {
    struct ReferralData {
        address referrer;              // Who referred this address
        address[] directReferrals;     // L1 referrals
        uint256 totalReferralVolume;   // Lifetime $ volume from entire tree
        uint256 totalEarned;           // Lifetime referral earnings
    }

    /**
     * @notice Emitted when a referral is recorded
     * @param referee Address of the new user
     * @param referrer Address of the referrer
     */
    event ReferralRecorded(address indexed referee, address indexed referrer);

    /**
     * @notice Emitted when referral bonus is distributed
     * @param referrer Address receiving the bonus
     * @param referee Address who triggered the bonus
     * @param level Referral level (1-10)
     * @param amount Bonus amount
     */
    event ReferralBonus(
        address indexed referrer,
        address indexed referee,
        uint256 level,
        uint256 amount
    );

    /**
     * @notice Emitted when echo-back is applied
     * @param referrer Address receiving echo-back
     * @param stakeAmount Original stake amount
     * @param echoBackAmount Amount echoed back
     */
    event EchoBack(address indexed referrer, uint256 stakeAmount, uint256 echoBackAmount);

    /**
     * @notice Record a new referral relationship
     * @param referee Address of the new user
     * @param referrer Address of the referrer
     */
    function recordReferral(address referee, address referrer) external;

    /**
     * @notice Distribute referral bonuses up the tree (10 levels)
     * @param referee Address who staked
     * @param stakeAmount Amount staked
     * @return totalPaid Total amount paid in bonuses
     */
    function distributeReferralBonus(address referee, uint256 stakeAmount)
        external
        returns (uint256 totalPaid);

    /**
     * @notice Apply echo-back to referrer's node
     * @param referrer Address of the referrer
     * @param stakeAmount Amount staked by referee
     */
    function applyEchoBack(address referrer, uint256 stakeAmount) external;

    /**
     * @notice Get referral tree for a user
     * @param user Address to get tree for
     * @param maxDepth Maximum depth to retrieve
     * @return tree Array of addresses in referral tree
     */
    function getReferralTree(address user, uint256 maxDepth)
        external
        view
        returns (address[] memory tree);

    /**
     * @notice Get referral data for a user
     * @param user Address to check
     * @return data Referral data struct
     */
    function getReferralData(address user) external view returns (ReferralData memory data);

    /**
     * @notice Get direct referrals for a user
     * @param user Address to check
     * @return referrals Array of direct referral addresses
     */
    function getDirectReferrals(address user) external view returns (address[] memory referrals);

    /**
     * @notice Check if user has a referrer
     * @param user Address to check
     * @return True if user has a referrer
     */
    function hasReferrer(address user) external view returns (bool);
}
