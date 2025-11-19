// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IEchoNode
 * @notice Interface for the Echo Node NFT contract
 */
interface IEchoNode is IERC721 {
    struct NodeData {
        uint256 stakedAmount;           // Current staked ECHO (including echo-backs)
        uint256 totalRewardsEarned;     // Lifetime rewards claimed
        uint256 nodeCreationTime;       // When the node was first created
        address referrer;               // Who referred this node
        uint256 directReferralCount;    // Number of L1 referrals
        uint256 totalReferralVolume;    // Lifetime referral volume in USD value
        uint256 lastActivityTime;       // Last stake/unstake/claim
        uint8 tierLevel;                // 0=Bronze, 1=Silver, 2=Gold, 3=Platinum, 4=Diamond
        bool isSoulbound;               // If true, cannot be transferred
        uint8 lockTier;                 // 0=none, 1=30d, 2=90d, 3=180d, 4=365d
        uint256 lockExpiry;             // When the lock expires
    }

    /**
     * @notice Emitted when a new node is minted
     * @param tokenId ID of the minted node
     * @param owner Owner of the node
     * @param referrer Who referred the owner
     */
    event NodeMinted(uint256 indexed tokenId, address indexed owner, address indexed referrer);

    /**
     * @notice Emitted when node data is updated
     * @param tokenId ID of the node
     * @param tierLevel New tier level
     */
    event NodeUpdated(uint256 indexed tokenId, uint8 tierLevel);

    /**
     * @notice Mint a new Echo Node NFT
     * @param owner Address to mint to
     * @param referrer Address of referrer (can be zero address)
     * @param isSoulbound Whether the NFT should be soulbound
     * @return tokenId ID of the minted node
     */
    function mintNode(
        address owner,
        address referrer,
        bool isSoulbound
    ) external returns (uint256 tokenId);

    /**
     * @notice Update node data (only callable by staking/referral contracts)
     * @param tokenId ID of the node to update
     * @param data New node data
     */
    function updateNodeData(uint256 tokenId, NodeData calldata data) external;

    /**
     * @notice Get node data
     * @param tokenId ID of the node
     * @return Node data struct
     */
    function getNodeData(uint256 tokenId) external view returns (NodeData memory);

    /**
     * @notice Calculate tier based on total referral volume
     * @param totalVolume Total referral volume in USD
     * @return tierLevel 0-4 representing Bronze to Diamond
     */
    function calculateTier(uint256 totalVolume) external view returns (uint8 tierLevel);

    /**
     * @notice Get multipliers for a node based on tier and lock
     * @param tokenId ID of the node
     * @return referralMultiplier Referral bonus multiplier (100 = 1x)
     * @return poolShareBonus Pool share bonus percentage (5 = +5%)
     * @return lockMultiplier Lock tier multiplier (100 = 1x)
     */
    function getNodeMultipliers(uint256 tokenId)
        external
        view
        returns (
            uint256 referralMultiplier,
            uint256 poolShareBonus,
            uint256 lockMultiplier
        );

    /**
     * @notice Get node ID for an owner
     * @param owner Address of the owner
     * @return tokenId ID of the node (0 if none)
     */
    function ownerToNodeId(address owner) external view returns (uint256 tokenId);

    /**
     * @notice Check if a node exists for an address
     * @param owner Address to check
     * @return True if node exists
     */
    function hasNode(address owner) external view returns (bool);
}
