// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IReferral.sol";
import "../interfaces/IECHO.sol";
import "../interfaces/IeECHO.sol";

/**
 * @title Referral
 * @notice 10-level referral system with rebasing rewards
 * @dev Referrers receive % of referee's initial stake as eECHO (which then rebases)
 *
 * Reward Structure:
 * - Level 1 (Direct): 4% of referee's stake
 * - Level 2: 2% of referee's stake
 * - Levels 3-10: 1% of referee's stake
 *
 * Example: Referee stakes 1000 ECHO
 * - Direct referrer gets 40 eECHO
 * - This 40 eECHO rebases alongside the referee's 1000 eECHO
 * - Effectively gives referrer 4% of all future rebases
 */
contract Referral is Ownable, ReentrancyGuard, IReferral {
    // ============ State Variables ============

    IECHO public immutable echo;
    IeECHO public immutable eEcho;

    // Referral data
    mapping(address => ReferralData) private _referralData;

    // Bonus rates (in basis points: 400 = 4%)
    uint256[10] public bonusRates = [
        400,  // L1: 4%
        200,  // L2: 2%
        100,  // L3: 1%
        100,  // L4: 1%
        100,  // L5: 1%
        100,  // L6: 1%
        100,  // L7: 1%
        100,  // L8: 1%
        100,  // L9: 1%
        100   // L10: 1%
    ];

    uint256 public constant MAX_DEPTH = 10;

    // Authorized contract (staking)
    address public stakingContract;

    // ============ Constructor ============

    constructor(address _echo, address _eEcho) Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        require(_eEcho != address(0), "Zero address");

        echo = IECHO(_echo);
        eEcho = IeECHO(_eEcho);
    }

    // ============ Configuration ============

    function setStakingContract(address _staking) external onlyOwner {
        require(stakingContract == address(0), "Already set");
        stakingContract = _staking;
    }

    // ============ Referral Management ============

    /**
     * @notice Record a new referral relationship
     * @param referee Address of the new user
     * @param referrer Address of the referrer
     */
    function recordReferral(address referee, address referrer) external override {
        require(msg.sender == stakingContract, "Only staking");
        require(referee != address(0), "Zero address");
        require(referrer != address(0), "Zero address");
        require(referee != referrer, "Self-referral");
        require(_referralData[referee].referrer == address(0), "Already has referrer");

        // Prevent circular referrals
        require(!_isCircular(referee, referrer), "Circular referral");

        // Record referral
        _referralData[referee].referrer = referrer;
        _referralData[referrer].directReferrals.push(referee);

        emit ReferralRecorded(referee, referrer);
    }

    /**
     * @notice Distribute referral bonuses up the tree
     * @dev Mints eECHO to referrers based on % of referee's stake
     * @param referee Address who staked
     * @param stakeAmount Amount staked (in ECHO)
     * @return totalPaid Total eECHO given to referrers
     */
    function distributeReferralBonus(address referee, uint256 stakeAmount)
        external
        override
        nonReentrant
        returns (uint256 totalPaid)
    {
        require(msg.sender == stakingContract, "Only staking");

        address current = _referralData[referee].referrer;
        uint256 depth = 0;

        while (current != address(0) && depth < MAX_DEPTH) {
            // Calculate referral reward (% of stake amount)
            uint256 bonusAmount = (stakeAmount * bonusRates[depth]) / 10000;

            if (bonusAmount > 0) {
                // Mint ECHO for the referral bonus
                echo.mint(address(this), bonusAmount);

                // Approve eECHO contract to wrap
                echo.approve(address(eEcho), bonusAmount);

                // Wrap ECHO to eECHO
                uint256 eEchoAmount = eEcho.wrap(bonusAmount);

                // Transfer eECHO to referrer
                require(eEcho.transfer(current, eEchoAmount), "Transfer failed");

                // Update stats
                _referralData[current].totalEarned += bonusAmount;
                _referralData[current].totalReferralVolume += stakeAmount;
                totalPaid += bonusAmount;

                emit ReferralBonus(current, referee, depth + 1, bonusAmount);
            }

            // Move up tree
            current = _referralData[current].referrer;
            depth++;
        }

        return totalPaid;
    }

    /**
     * @notice Track referral volume for stats (deprecated)
     * @dev Called when a referee stakes - no longer performs echo-back (NFTs removed)
     * @dev Kept for interface compatibility, may be removed in future versions
     * @param referrer Address of the referrer
     * @param stakeAmount Amount staked by referee
     */
    function applyEchoBack(address referrer, uint256 stakeAmount) external override {
        require(msg.sender == stakingContract, "Only staking");

        if (referrer == address(0)) return;

        // No-op: Echo-back was removed with NFT system
        // This function exists only for interface compatibility
        emit EchoBack(referrer, stakeAmount, 0);
    }

    // ============ View Functions ============

    /**
     * @notice Get referral tree for a user
     * @param user Address to get tree for
     * @param maxDepth Maximum depth to retrieve
     * @return tree Array of addresses in referral tree
     */
    function getReferralTree(address user, uint256 maxDepth)
        external
        view
        override
        returns (address[] memory tree)
    {
        // Calculate total size needed
        uint256 totalSize = 0;
        for (uint256 i = 0; i < maxDepth; i++) {
            totalSize += _getReferralsAtDepth(user, i);
        }

        tree = new address[](totalSize);
        uint256 index = 0;

        // Fill array
        for (uint256 i = 0; i < maxDepth; i++) {
            address[] memory levelRefs = _getDirectReferrals(user);
            for (uint256 j = 0; j < levelRefs.length; j++) {
                if (index < totalSize) {
                    tree[index++] = levelRefs[j];
                }
            }
        }

        return tree;
    }

    function getReferralData(address user)
        external
        view
        override
        returns (ReferralData memory data)
    {
        return _referralData[user];
    }

    function getDirectReferrals(address user)
        external
        view
        override
        returns (address[] memory referrals)
    {
        return _referralData[user].directReferrals;
    }

    function hasReferrer(address user) external view override returns (bool) {
        return _referralData[user].referrer != address(0);
    }

    // ============ Internal Functions ============

    /**
     * @notice Check if adding referrer would create circular reference
     * @param referee New user
     * @param referrer Proposed referrer
     * @return True if circular
     */
    function _isCircular(address referee, address referrer) private view returns (bool) {
        address current = referrer;
        uint256 depth = 0;

        while (current != address(0) && depth < MAX_DEPTH * 2) {
            if (current == referee) {
                return true; // Circular!
            }
            current = _referralData[current].referrer;
            depth++;
        }

        return false;
    }

    function _getDirectReferrals(address user) private view returns (address[] memory) {
        return _referralData[user].directReferrals;
    }

    function _getReferralsAtDepth(address user, uint256 depth) private view returns (uint256) {
        if (depth == 0) {
            return _referralData[user].directReferrals.length;
        }

        uint256 count = 0;
        address[] memory refs = _referralData[user].directReferrals;

        for (uint256 i = 0; i < refs.length; i++) {
            count += _getReferralsAtDepth(refs[i], depth - 1);
        }

        return count;
    }
}
