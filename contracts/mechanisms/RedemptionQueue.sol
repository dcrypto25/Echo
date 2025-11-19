// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/ITreasury.sol";

/**
 * @title RedemptionQueue
 * @notice Queue system for unstaking with instant unstake option
 * @dev Queue length scales with backing ratio (1-7 days)
 *      Users can pay dynamic fee (2-10%) to skip queue instantly
 */
contract RedemptionQueue is Ownable {
    using SafeERC20 for IERC20;

    ITreasury public immutable treasury;
    AggregatorV3Interface public ethPriceFeed;

    IERC20 public immutable USDC;
    IERC20 public immutable DAI;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant BASE_FEE = 200;  // 2%
    uint256 public constant MAX_FEE = 1000;  // 10%
    uint256 public constant TIME_MULTIPLIER = 50;  // 0.5% per day
    uint256 public constant CONGESTION_MULTIPLIER = 10;  // 0.1% per queued user

    struct QueueEntry {
        address user;
        uint256 amount;
        uint256 queueTime;
        uint256 availableTime;
    }

    mapping(address => QueueEntry) public queue;
    address[] public queueList;  // Track all queued users
    mapping(address => uint256) public queueIndex;  // User's index in queueList

    event Queued(address indexed user, uint256 amount, uint256 availableTime);
    event InstantUnstake(address indexed user, uint256 amount, uint256 fee, address paymentToken);
    event Processed(address indexed user, uint256 amount);

    constructor(
        address _treasury,
        address _ethPriceFeed,
        address _usdc,
        address _dai
    ) Ownable(msg.sender) {
        treasury = ITreasury(_treasury);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        USDC = IERC20(_usdc);
        DAI = IERC20(_dai);
    }

    /**
     * @notice Calculate queue wait time based on backing ratio
     * @dev 3-7 days scaling: ≥120% = 3 days, ≤50% = 7 days
     */
    function calculateQueueDays() public view returns (uint256) {
        uint256 backing = treasury.getBackingRatio();

        // ≥120% backing: 3 days (minimum queue)
        if (backing >= 12000) return 3;

        // ≤50% backing: 7 days (maximum protection)
        if (backing <= 5000) return 7;

        // 50-120% backing: Linear scale from 3 to 7 days
        // Formula: 3 + 4 × (120% - β) / 70%
        // Days = 3 + ((12000 - backing) * 4) / 7000
        uint256 additionalDays = ((12000 - backing) * 4) / 7000;

        return 3 + additionalDays;
    }

    /**
     * @notice Calculate dynamic instant unstake fee
     * @dev Fee = 2% base + 0.5% per day + 0.1% per queued user (capped at 10%)
     * @param user Address of user wanting instant unstake
     * @return Fee in basis points
     */
    function calculateInstantUnstakeFee(address user) public view returns (uint256) {
        QueueEntry memory entry = queue[user];
        require(entry.amount > 0, "Not in queue");

        // Calculate time-based component
        uint256 queueDays = (entry.availableTime - entry.queueTime) / 1 days;
        uint256 timeFee = queueDays * TIME_MULTIPLIER;

        // Calculate congestion component
        uint256 congestionFee = queueList.length * CONGESTION_MULTIPLIER;

        // Total fee (capped at MAX_FEE)
        uint256 totalFee = BASE_FEE + timeFee + congestionFee;

        return totalFee > MAX_FEE ? MAX_FEE : totalFee;
    }

    /**
     * @notice Calculate instant unstake fee in dollar terms
     * @param user Address of user
     * @param echoAmount Amount of ECHO being unstaked
     * @return Fee amount in USD (6 decimals)
     */
    function calculateInstantUnstakeFeeUSD(address user, uint256 echoAmount) public view returns (uint256) {
        uint256 feeBasisPoints = calculateInstantUnstakeFee(user);

        // Get ECHO price from treasury (in USD, 6 decimals)
        uint256 echoPrice = treasury.getECHOPrice();

        // Calculate fee in USD
        uint256 totalValueUSD = (echoAmount * echoPrice) / 1e18;  // echoAmount has 18 decimals
        uint256 feeUSD = (totalValueUSD * feeBasisPoints) / BASIS_POINTS;

        return feeUSD;
    }

    /**
     * @notice Calculate instant unstake fee in ETH
     * @param user Address of user
     * @param echoAmount Amount of ECHO being unstaked
     * @return Fee amount in ETH (18 decimals)
     */
    function calculateInstantUnstakeFeeETH(address user, uint256 echoAmount) public view returns (uint256) {
        uint256 feeUSD = calculateInstantUnstakeFeeUSD(user, echoAmount);

        // Get ETH price from Chainlink (8 decimals)
        (, int256 ethPriceInt, , , ) = ethPriceFeed.latestRoundData();
        require(ethPriceInt > 0, "Invalid ETH price");

        uint256 ethPrice = uint256(ethPriceInt);  // Price in USD with 8 decimals

        // Convert USD fee to ETH
        // feeUSD has 6 decimals, ethPrice has 8 decimals
        // Result should have 18 decimals
        uint256 feeETH = (feeUSD * 1e20) / ethPrice;  // 6 + 20 - 8 = 18 decimals

        return feeETH;
    }

    /**
     * @notice Add user to redemption queue
     * @param user Address of user
     * @param amount Amount of ECHO to queue
     */
    function addToQueue(address user, uint256 amount) external onlyOwner {
        require(queue[user].amount == 0, "Already in queue");

        uint256 queueDays = calculateQueueDays();

        queue[user] = QueueEntry({
            user: user,
            amount: amount,
            queueTime: block.timestamp,
            availableTime: block.timestamp + (queueDays * 1 days)
        });

        // Add to queue list
        queueIndex[user] = queueList.length;
        queueList.push(user);

        emit Queued(user, amount, queue[user].availableTime);
    }

    /**
     * @notice Instant unstake with ETH payment
     * @dev User pays dynamic fee in ETH to skip queue
     */
    function instantUnstakeETH() external payable {
        QueueEntry memory entry = queue[msg.sender];
        require(entry.amount > 0, "Not in queue");

        uint256 feeETH = calculateInstantUnstakeFeeETH(msg.sender, entry.amount);
        require(msg.value >= feeETH, "Insufficient ETH fee");

        // Send fee to treasury
        (bool success, ) = address(treasury).call{value: msg.value}("");
        require(success, "ETH transfer failed");

        // Remove from queue
        _removeFromQueue(msg.sender);

        emit InstantUnstake(msg.sender, entry.amount, msg.value, address(0));
    }

    /**
     * @notice Instant unstake with stablecoin payment
     * @param paymentToken Address of payment token (USDC or DAI)
     */
    function instantUnstakeStable(address paymentToken) external {
        QueueEntry memory entry = queue[msg.sender];
        require(entry.amount > 0, "Not in queue");
        require(
            paymentToken == address(USDC) || paymentToken == address(DAI),
            "Unsupported token"
        );

        uint256 feeUSD = calculateInstantUnstakeFeeUSD(msg.sender, entry.amount);

        // Transfer stablecoin to treasury
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(treasury), feeUSD);

        // Remove from queue
        _removeFromQueue(msg.sender);

        emit InstantUnstake(msg.sender, entry.amount, feeUSD, paymentToken);
    }

    /**
     * @notice Remove user from queue (internal)
     */
    function _removeFromQueue(address user) internal {
        uint256 index = queueIndex[user];
        uint256 lastIndex = queueList.length - 1;

        // Move last element to deleted spot
        if (index != lastIndex) {
            address lastUser = queueList[lastIndex];
            queueList[index] = lastUser;
            queueIndex[lastUser] = index;
        }

        // Remove last element
        queueList.pop();
        delete queueIndex[user];
        delete queue[user];
    }

    /**
     * @notice Process regular queue unstake (no fee)
     * @param user Address to process
     */
    function processQueue(address user) external onlyOwner {
        require(block.timestamp >= queue[user].availableTime, "Not available yet");

        uint256 amount = queue[user].amount;
        _removeFromQueue(user);

        emit Processed(user, amount);
    }

    /**
     * @notice Check if user can unstake from queue
     */
    function isAvailable(address user) external view returns (bool) {
        return block.timestamp >= queue[user].availableTime;
    }

    /**
     * @notice Get current queue length
     */
    function getQueueLength() external view returns (uint256) {
        return queueList.length;
    }

    /**
     * @notice Get user's queue info with fee estimates
     */
    function getQueueInfo(address user) external view returns (
        uint256 amount,
        uint256 queueTime,
        uint256 availableTime,
        uint256 feeBasisPoints,
        uint256 feeUSD,
        uint256 feeETH
    ) {
        QueueEntry memory entry = queue[user];

        if (entry.amount == 0) {
            return (0, 0, 0, 0, 0, 0);
        }

        return (
            entry.amount,
            entry.queueTime,
            entry.availableTime,
            calculateInstantUnstakeFee(user),
            calculateInstantUnstakeFeeUSD(user, entry.amount),
            calculateInstantUnstakeFeeETH(user, entry.amount)
        );
    }

    /**
     * @notice Update ETH price feed oracle
     */
    function updateETHPriceFeed(address newFeed) external onlyOwner {
        ethPriceFeed = AggregatorV3Interface(newFeed);
    }

    /**
     * @notice Accept ETH for treasury
     */
    receive() external payable {}
}
