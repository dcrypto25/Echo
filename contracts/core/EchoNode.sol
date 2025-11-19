// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IEchoNode.sol";

/**
 * @title EchoNode
 * @notice ERC721 NFT representing staking positions with tier progression
 * @dev One NFT per address, tracks staking stats and referral performance
 *
 * Tier System:
 * - Bronze: $10K lifetime volume
 * - Silver: $100K lifetime volume
 * - Gold: $1M lifetime volume
 * - Platinum: $10M lifetime volume
 * - Diamond: $100M+ lifetime volume
 */
contract EchoNode is ERC721, ERC721Enumerable, Ownable, IEchoNode {
    using Strings for uint256;

    // ============ State Variables ============

    // Node data storage
    mapping(uint256 => NodeData) private _nodeData;
    mapping(address => uint256) public override ownerToNodeId;

    uint256 private _nextTokenId = 1;

    // Tier thresholds (in USD value, assuming 18 decimals)
    uint256[5] public tierThresholds = [
        10_000 * 1e18,      // Bronze: $10K
        100_000 * 1e18,     // Silver: $100K
        1_000_000 * 1e18,   // Gold: $1M
        10_000_000 * 1e18,  // Platinum: $10M
        100_000_000 * 1e18  // Diamond: $100M
    ];

    // Tier multipliers (in basis points: 100 = 1x)
    uint256[5] public referralMultipliers = [100, 150, 250, 400, 600]; // 1×, 1.5×, 2.5×, 4×, 6×
    uint256[5] public poolShareBonuses = [5, 15, 30, 60, 100];         // +5%, +15%, +30%, +60%, +100%

    // Lock tier multipliers
    uint256[5] public lockMultipliers = [100, 120, 200, 300, 400];     // 1×, 1.2×, 2×, 3×, 4×

    // Tier names for metadata
    string[5] private tierNames = ["Bronze", "Silver", "Gold", "Platinum", "Diamond"];
    string[5] private tierColors = ["#CD7F32", "#C0C0C0", "#FFD700", "#E5E4E2", "#B9F2FF"];

    // Authorized contracts
    address public stakingContract;
    address public referralContract;

    // ============ Constructor ============

    constructor() ERC721("Echo Node", "ENODE") Ownable(msg.sender) {}

    // ============ Configuration ============

    function setStakingContract(address _staking) external onlyOwner {
        require(stakingContract == address(0), "Already set");
        stakingContract = _staking;
    }

    function setReferralContract(address _referral) external onlyOwner {
        require(referralContract == address(0), "Already set");
        referralContract = _referral;
    }

    // ============ Minting ============

    /**
     * @notice Mint a new Echo Node NFT
     * @param owner Address to mint to
     * @param referrer Address of referrer
     * @param isSoulbound Whether NFT should be soulbound
     * @return tokenId ID of minted token
     */
    function mintNode(
        address owner,
        address referrer,
        bool isSoulbound
    ) external override returns (uint256 tokenId) {
        require(msg.sender == stakingContract, "Only staking");
        require(ownerToNodeId[owner] == 0, "Already has node");

        tokenId = _nextTokenId++;

        _safeMint(owner, tokenId);

        _nodeData[tokenId] = NodeData({
            stakedAmount: 0,
            totalRewardsEarned: 0,
            nodeCreationTime: block.timestamp,
            referrer: referrer,
            directReferralCount: 0,
            totalReferralVolume: 0,
            lastActivityTime: block.timestamp,
            tierLevel: 0, // Bronze
            isSoulbound: isSoulbound,
            lockTier: 0,  // No lock
            lockExpiry: 0
        });

        ownerToNodeId[owner] = tokenId;

        emit NodeMinted(tokenId, owner, referrer);
        return tokenId;
    }

    // ============ Node Data Management ============

    /**
     * @notice Update node data (only authorized contracts)
     * @param tokenId Token ID to update
     * @param data New node data
     */
    function updateNodeData(uint256 tokenId, NodeData calldata data) external override {
        require(
            msg.sender == stakingContract || msg.sender == referralContract,
            "Not authorized"
        );
        require(_ownerOf(tokenId) != address(0), "Node doesn't exist");

        // Update tier based on referral volume
        uint8 newTier = calculateTier(data.totalReferralVolume);

        NodeData storage node = _nodeData[tokenId];
        node.stakedAmount = data.stakedAmount;
        node.totalRewardsEarned = data.totalRewardsEarned;
        node.directReferralCount = data.directReferralCount;
        node.totalReferralVolume = data.totalReferralVolume;
        node.lastActivityTime = block.timestamp;
        node.tierLevel = newTier;
        node.lockTier = data.lockTier;
        node.lockExpiry = data.lockExpiry;

        if (newTier != node.tierLevel) {
            emit NodeUpdated(tokenId, newTier);
        }
    }

    // ============ Tier Calculation ============

    /**
     * @notice Calculate tier based on referral volume
     * @param totalVolume Total referral volume
     * @return tierLevel 0-4 (Bronze to Diamond)
     */
    function calculateTier(uint256 totalVolume) public view override returns (uint8 tierLevel) {
        if (totalVolume >= tierThresholds[4]) return 4; // Diamond
        if (totalVolume >= tierThresholds[3]) return 3; // Platinum
        if (totalVolume >= tierThresholds[2]) return 2; // Gold
        if (totalVolume >= tierThresholds[1]) return 1; // Silver
        return 0; // Bronze
    }

    /**
     * @notice Get multipliers for a node
     * @param tokenId Token ID
     * @return referralMultiplier Referral bonus multiplier
     * @return poolShareBonus Pool share bonus
     * @return lockMultiplier Lock tier multiplier
     */
    function getNodeMultipliers(uint256 tokenId)
        external
        view
        override
        returns (
            uint256 referralMultiplier,
            uint256 poolShareBonus,
            uint256 lockMultiplier
        )
    {
        NodeData memory node = _nodeData[tokenId];

        referralMultiplier = referralMultipliers[node.tierLevel];
        poolShareBonus = poolShareBonuses[node.tierLevel];
        lockMultiplier = lockMultipliers[node.lockTier];

        return (referralMultiplier, poolShareBonus, lockMultiplier);
    }

    // ============ View Functions ============

    function getNodeData(uint256 tokenId)
        external
        view
        override
        returns (NodeData memory)
    {
        require(_ownerOf(tokenId) != address(0), "Node doesn't exist");
        return _nodeData[tokenId];
    }

    function hasNode(address owner) external view override returns (bool) {
        return ownerToNodeId[owner] != 0;
    }

    // ============ Transfer Override (Soulbound) ============

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Check soulbound (allow minting and burning)
        if (from != address(0) && to != address(0)) {
            require(!_nodeData[tokenId].isSoulbound, "Soulbound");
        }

        // Update owner mapping
        if (from != address(0) && to != address(0)) {
            ownerToNodeId[from] = 0;
            ownerToNodeId[to] = tokenId;
        }

        return super._update(to, tokenId, auth);
    }

    // ============ Metadata (On-Chain SVG) ============

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token doesn't exist");

        NodeData memory node = _nodeData[tokenId];
        string memory svg = _generateSVG(tokenId, node);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Echo Node #',
                        tokenId.toString(),
                        '", "description": "EchoForge staking position - ',
                        tierNames[node.tierLevel],
                        ' Tier", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": [',
                        '{"trait_type": "Tier", "value": "',
                        tierNames[node.tierLevel],
                        '"},',
                        '{"trait_type": "Staked Amount", "value": "',
                        (node.stakedAmount / 1e18).toString(),
                        '"},',
                        '{"trait_type": "Referral Volume", "value": "',
                        (node.totalReferralVolume / 1e18).toString(),
                        '"},',
                        '{"trait_type": "Direct Referrals", "value": "',
                        node.directReferralCount.toString(),
                        '"}',
                        "]}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _generateSVG(uint256 tokenId, NodeData memory node)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
                    '<defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">',
                    '<stop offset="0%" style="stop-color:',
                    tierColors[node.tierLevel],
                    ';stop-opacity:1" />',
                    '<stop offset="100%" style="stop-color:#000;stop-opacity:1" />',
                    "</linearGradient></defs>",
                    '<rect width="400" height="400" fill="url(#grad)"/>',
                    '<text x="200" y="100" font-size="32" fill="white" text-anchor="middle" font-family="Arial">',
                    "Echo Node #",
                    tokenId.toString(),
                    "</text>",
                    '<text x="200" y="150" font-size="24" fill="white" text-anchor="middle" font-family="Arial">',
                    tierNames[node.tierLevel],
                    " Tier</text>",
                    '<text x="200" y="200" font-size="18" fill="white" text-anchor="middle" font-family="Arial">',
                    "Staked: ",
                    (node.stakedAmount / 1e18).toString(),
                    " ECHO</text>",
                    '<text x="200" y="230" font-size="18" fill="white" text-anchor="middle" font-family="Arial">',
                    "Referrals: ",
                    node.directReferralCount.toString(),
                    "</text>",
                    '<text x="200" y="260" font-size="18" fill="white" text-anchor="middle" font-family="Arial">',
                    "Volume: $",
                    (node.totalReferralVolume / 1e18).toString(),
                    "</text>",
                    "</svg>"
                )
            );
    }

    // ============ Required Overrides ============

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
