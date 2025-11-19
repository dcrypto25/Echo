// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IECHO.sol";
import "../interfaces/IeECHO.sol";

/**
 * @title Treasury
 * @notice Forge Reserve - DAO-controlled treasury with buyback engine
 * @dev Manages protocol assets, calculates backing ratio, executes buybacks
 *
 * Key Features:
 * - Automatic buyback when price < 75% of 30-day TWAP
 * - Backing ratio calculation
 * - Yield strategy deployment
 * - Runway calculation
 */
contract Treasury is Ownable, ReentrancyGuard, ITreasury {
    // ============ State Variables ============

    IECHO public immutable echo;
    IeECHO public immutable eEcho;

    // Treasury assets
    mapping(address => uint256) public assetBalances;
    address[] public assets;

    // Backing calculation
    uint256 public totalValue;      // Total value in USD (18 decimals)
    uint256 public liquidValue;             // Liquid assets value
    uint256 public yieldValue;              // Yield-earning assets value

    // Buyback configuration
    uint256 public buybackFloorPercent = 7500;      // 75% of TWAP
    uint256 public maxBuybackPerWeek = 500;         // 5% of treasury
    uint256 public lastBuybackTime;

    // Price tracking (simplified - would use Chainlink oracle in production)
    uint256 public lastPrice;
    uint256 public twapPrice;

    // Yield strategies
    mapping(address => bool) public approvedStrategies;
    mapping(address => uint256) public strategyBalances;

    // ============ Events ============

    event Withdrawn(address indexed token, uint256 amount, address indexed to);
    event YieldDeployed(address indexed strategy, uint256 amount);
    event YieldWithdrawn(address indexed strategy, uint256 amount);

    // ============ Constructor ============

    constructor(address _echo, address _eEcho) Ownable(msg.sender) {
        echo = IECHO(_echo);
        eEcho = IeECHO(_eEcho);
    }

    // ============ Deposit Functions ============

    /**
     * @notice Deposit assets to treasury
     * @param token Token address (zero for ETH)
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount)
        external
        payable
        override
        nonReentrant
    {
        if (token == address(0)) {
            // ETH deposit
            require(msg.value == amount, "Amount mismatch");
            assetBalances[address(0)] += amount;
            _addAsset(address(0));
        } else {
            // ERC20 deposit
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
            assetBalances[token] += amount;
            _addAsset(token);
        }

        // Update values
        _updateTotalValue();

        emit Deposited(token, amount);
    }

    /**
     * @notice Withdraw assets (governance only)
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        require(assetBalances[token] >= amount, "Insufficient balance");

        assetBalances[token] -= amount;

        if (token == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }

        _updateTotalValue();

        emit Withdrawn(token, amount, msg.sender);
    }

    // ============ Buyback Engine ============

    /**
     * @notice Execute buyback when price is below floor
     * @param maxAmount Maximum treasury amount to spend
     * @return echoAmount Amount of ECHO bought and burned
     */
    function executeBuyback(uint256 maxAmount)
        external
        override
        nonReentrant
        returns (uint256 echoAmount)
    {
        require(shouldExecuteBuyback(), "Conditions not met");

        // Check weekly limit
        if (block.timestamp < lastBuybackTime + 1 weeks) {
            uint256 weeklyLimit = (totalValue * maxBuybackPerWeek) / 10000;
            require(maxAmount <= weeklyLimit, "Exceeds weekly limit");
        }

        // Calculate ECHO to buy (simplified - would use DEX in production)
        // This is a placeholder for actual DEX integration
        echoAmount = _simulateBuyback(maxAmount);

        // Update backing ratio
        _updateTotalValue();
        uint256 newBackingRatio = getBackingRatio();
        eEcho.updateBackingRatio(newBackingRatio);

        lastBuybackTime = block.timestamp;

        emit BuybackExecuted(echoAmount, maxAmount);

        return echoAmount;
    }

    /**
     * @notice Check if buyback should be triggered
     * @return True if conditions met
     */
    function shouldExecuteBuyback() public view override returns (bool) {
        // Check if price is below floor
        uint256 floorPrice = (twapPrice * buybackFloorPercent) / 10000;
        return lastPrice < floorPrice;
    }

    // ============ Yield Strategy Management ============

    /**
     * @notice Deploy funds to yield strategy
     * @param strategy Strategy address
     * @param amount Amount to deploy
     */
    function deployToYield(address strategy, uint256 amount) external override onlyOwner {
        require(approvedStrategies[strategy], "Strategy not approved");
        require(liquidValue >= amount, "Insufficient liquid assets");

        // Transfer to strategy (simplified)
        strategyBalances[strategy] += amount;
        liquidValue -= amount;
        yieldValue += amount;

        _updateTotalValue();

        emit YieldDeployed(strategy, amount);
    }

    /**
     * @notice Withdraw from yield strategy
     * @param strategy Strategy address
     * @param amount Amount to withdraw
     */
    function withdrawFromYield(address strategy, uint256 amount) external override onlyOwner {
        require(strategyBalances[strategy] >= amount, "Insufficient balance");

        strategyBalances[strategy] -= amount;
        yieldValue -= amount;
        liquidValue += amount;

        _updateTotalValue();

        emit YieldWithdrawn(strategy, amount);
    }

    /**
     * @notice Approve a yield strategy
     * @param strategy Strategy address
     */
    function approveStrategy(address strategy) external onlyOwner {
        approvedStrategies[strategy] = true;
    }

    // ============ View Functions ============

    /**
     * @notice Get backing ratio
     * @return Ratio in basis points (10000 = 100%)
     */
    function getBackingRatio() public view override returns (uint256) {
        uint256 totalSupply = echo.totalSupply();
        if (totalSupply == 0) return 10000; // 100% if no supply

        // backing = totalValue / totalSupply
        return (totalValue * 10000) / totalSupply;
    }

    function getTotalValue() external view override returns (uint256) {
        return totalValue;
    }

    function getLiquidValue() external view override returns (uint256) {
        return liquidValue;
    }

    function getYieldValue() external view override returns (uint256) {
        return yieldValue;
    }

    /**
     * @notice Calculate runway in days with compound growth
     * @return Days of runway at current APY
     * @dev Formula: T = ln(1 + Treasury/Staked) / ln(1 + daily_rate)
     * @dev This accounts for exponentially growing emissions
     */
    function getRunway() external view override returns (uint256) {
        uint256 totalStaked = echo.totalSupply();
        if (totalStaked == 0) return type(uint256).max;

        // Get current APY from eECHO contract
        uint256 currentAPY = eEcho.getCurrentAPY();
        if (currentAPY == 0) return type(uint256).max;

        // Get daily rate in basis points
        uint256 dailyRateBPS;
        if (currentAPY >= 180000) {
            dailyRateBPS = 151; // ~1.51% for 18000% APY
        } else if (currentAPY >= 80000) {
            dailyRateBPS = 123; // ~1.23% for 8000% APY
        } else if (currentAPY >= 30000) {
            dailyRateBPS = 94;  // ~0.94% for 3000% APY
        } else if (currentAPY >= 10000) {
            dailyRateBPS = 63;  // ~0.63% for 1000% APY
        } else if (currentAPY >= 5000) {
            dailyRateBPS = 44;  // ~0.44% for 500% APY
        } else {
            dailyRateBPS = currentAPY / 365;
        }

        // Calculate runway: T = ln(1 + Treasury/Staked) / ln(1 + r)
        // Using approximation: ln(1+x) ≈ x for small x
        // For large multipliers, use lookup table

        uint256 stakedValueUSD = totalStaked; // Simplified: $1 per ECHO
        if (stakedValueUSD == 0) return 0;

        uint256 multiplier = (totalValue * 10000) / stakedValueUSD; // In basis points

        // Approximate T using: T ≈ (multiplier - 10000) / dailyRateBPS
        // This is ln(multiplier/10000) / ln(1 + dailyRate) approximation
        if (multiplier <= 10000) return 0; // No runway if under-backed

        uint256 runwayDays = ((multiplier - 10000) * 10000) / (dailyRateBPS * 10000 / 100);

        return runwayDays;
    }

    // ============ Internal Functions ============

    function _addAsset(address token) private {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == token) return;
        }
        assets.push(token);
    }

    function _updateTotalValue() private {
        uint256 oldRatio = getBackingRatio();

        // Recalculate total value (simplified - would use oracles in production)
        liquidValue = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            liquidValue += assetBalances[assets[i]];
        }

        totalValue = liquidValue + yieldValue;

        uint256 newRatio = getBackingRatio();
        if (oldRatio != newRatio) {
            emit BackingRatioUpdated(oldRatio, newRatio);
        }
    }

    function _simulateBuyback(uint256 maxAmount) private returns (uint256) {
        // Placeholder for actual DEX buyback
        // In production, would swap treasury assets for ECHO on Uniswap
        // Then burn the ECHO

        uint256 echoAmount = maxAmount; // Simplified 1:1

        // Burn ECHO
        echo.burn(echoAmount);

        return echoAmount;
    }

    // ============ Price Update (Placeholder) ============

    /**
     * @notice Update price (would use Chainlink oracle in production)
     * @param newPrice New price
     */
    function updatePrice(uint256 newPrice) external onlyOwner {
        lastPrice = newPrice;

        // Update TWAP (simplified)
        if (twapPrice == 0) {
            twapPrice = newPrice;
        } else {
            twapPrice = (twapPrice * 9 + newPrice) / 10; // Simple exponential moving average
        }
    }

    receive() external payable {
        assetBalances[address(0)] += msg.value;
        _addAsset(address(0));
        _updateTotalValue();
        emit Deposited(address(0), msg.value);
    }
}
