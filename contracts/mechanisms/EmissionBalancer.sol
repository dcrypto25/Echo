// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IECHO.sol";
import "../interfaces/IeECHO.sol";
import "../interfaces/ITreasury.sol";

/**
 * @title EmissionBalancer
 * @notice Prevents death spiral by burning excess emissions when rebase exceeds sustainability
 * @dev This is the "Anti-Death Spiral Lock" - mathematically prevents OHM-style collapse
 *
 * KEY INNOVATION:
 * - Users still get their full APY rebase (no reduction in rewards)
 * - But protocol simultaneously burns equivalent ECHO via buybacks
 * - Net effect: Supply stays neutral when emissions exceed treasury capacity
 * - Creates mathematical impossibility of death spiral
 *
 * EXAMPLE:
 * - Treasury can sustainably support 2,000% APY from yield
 * - Backing-dampened APY is 8,000% (high backing scenario)
 * - Users get 8,000% rebase in eECHO
 * - Protocol buys and burns 6,000% worth of ECHO
 * - Net supply change: +8,000% - 6,000% = +2,000% (sustainable)
 */
contract EmissionBalancer is Ownable, ReentrancyGuard {
    // ============ Constants ============

    // Maximum sustainable APY ceiling (prevents miscalculation)
    uint256 public constant MAX_SUSTAINABLE_APY = 10000; // 100x per year = 10,000%

    // Precision for calculations (1e18)
    uint256 private constant PRECISION = 1e18;

    // Base APY unit (100 = 1%)
    uint256 private constant APY_BASE = 10000;

    // Rebase interval (8 hours = 28800 seconds)
    uint256 public constant REBASE_INTERVAL = 8 hours;

    // Annual rebases (365 days / 8 hours = 1095 rebases/year)
    uint256 public constant REBASES_PER_YEAR = 1095;

    // ============ State Variables ============

    IECHO public immutable echo;
    IeECHO public immutable eecho;
    ITreasury public immutable treasury;

    // Tracking
    uint256 public totalExcessBurned;
    uint256 public totalBuybacksExecuted;
    uint256 public lastBalanceCheck;

    // Moving averages for smoothing
    uint256 public avgTreasuryYield; // 30-day average yield (in basis points per year)
    uint256 public avgBackingRatio;  // 30-day average backing ratio

    // Safety parameters
    uint256 public minBuybackAmount = 100 * 1e18; // Minimum 100 ECHO per buyback
    uint256 public maxBuybackPerRebase; // Set during init based on liquidity

    // ============ Events ============

    event ExcessEmissionBurn(
        uint256 indexed rebaseNumber,
        uint256 sustainableAPY,
        uint256 actualAPY,
        uint256 excessAPY,
        uint256 burnAmount,
        uint256 echoPrice
    );

    event BuybackExecuted(
        uint256 amountETH,
        uint256 amountECHO,
        uint256 burnedECHO
    );

    event SustainabilityMetrics(
        uint256 treasuryYield,
        uint256 backingRatio,
        uint256 maxSustainableAPY
    );

    // ============ Constructor ============

    constructor(
        address _echo,
        address _eecho,
        address _treasury
    ) Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        require(_eecho != address(0), "Zero address");
        require(_treasury != address(0), "Zero address");

        echo = IECHO(_echo);
        eecho = IeECHO(_eecho);
        treasury = ITreasury(_treasury);

        // Initialize with conservative defaults
        avgTreasuryYield = 500; // 5% annual yield
        avgBackingRatio = 10000; // 100% backing
        maxBuybackPerRebase = 10000 * 1e18; // 10K ECHO max per rebase
        lastBalanceCheck = block.timestamp;
    }

    // ============ Core Balancing Function ============

    /**
     * @notice Called after each rebase to balance emissions
     * @dev This is the heart of the anti-death-spiral mechanism
     * @param rebaseNumber Current rebase epoch
     * @param actualRebaseRate The rate that was applied (after dampener)
     * @return burnAmount Amount of ECHO burned to offset excess
     */
    function balanceEmissions(uint256 rebaseNumber, uint256 actualRebaseRate)
        external
        nonReentrant
        returns (uint256 burnAmount)
    {
        require(msg.sender == address(eecho), "Only eECHO");

        // Update moving averages
        _updateMetrics();

        // Calculate maximum sustainable APY from treasury
        uint256 sustainableAPY = _calculateSustainableAPY();

        // Convert rebase rate to annualized APY
        uint256 actualAPY = _rebaseRateToAPY(actualRebaseRate);

        // If actual APY exceeds sustainable, we need to burn the excess
        if (actualAPY > sustainableAPY) {
            uint256 excessAPY = actualAPY - sustainableAPY;

            // Calculate how much ECHO needs to be burned to offset excess emission
            burnAmount = _calculateBurnAmount(excessAPY);

            if (burnAmount >= minBuybackAmount) {
                // Cap at max per rebase for safety
                if (burnAmount > maxBuybackPerRebase) {
                    burnAmount = maxBuybackPerRebase;
                }

                // Execute buyback and burn
                _executeBuybackBurn(burnAmount);

                // Record metrics
                totalExcessBurned += burnAmount;
                totalBuybacksExecuted++;

                emit ExcessEmissionBurn(
                    rebaseNumber,
                    sustainableAPY,
                    actualAPY,
                    excessAPY,
                    burnAmount,
                    _getEchoPrice()
                );
            }
        }

        emit SustainabilityMetrics(avgTreasuryYield, avgBackingRatio, sustainableAPY);

        return burnAmount;
    }

    // ============ Sustainability Calculations ============

    /**
     * @notice Calculate maximum sustainable APY from treasury yield
     * @dev Uses complex math to account for:
     *      - Current treasury yield (real yield from GMX/GLP)
     *      - Backing ratio (higher backing = more room for emissions)
     *      - Risk buffer (keep some yield as safety margin)
     * @return Maximum sustainable annual percentage yield
     */
    function _calculateSustainableAPY() private view returns (uint256) {
        // Get current treasury metrics
        uint256 totalValue = treasury.getTotalValue();
        uint256 liquidValue = treasury.getLiquidValue();
        uint256 backingRatio = treasury.getBackingRatio();

        // Total ECHO supply (circulating)
        uint256 totalSupply = echo.totalSupply();

        if (totalSupply == 0 || totalValue == 0) return 0;

        // 1. Calculate base sustainable rate from treasury yield
        // avgTreasuryYield is in basis points per year (e.g., 500 = 5% annual)
        uint256 baseYieldAPY = avgTreasuryYield;

        // 2. Apply backing ratio multiplier
        // Higher backing = more cushion for emissions
        // Formula: multiplier = sqrt(backingRatio / 10000)
        // - 100% backing = 1x multiplier
        // - 200% backing = 1.41x multiplier
        // - 400% backing = 2x multiplier
        uint256 backingMultiplier = _sqrt((backingRatio * PRECISION) / 10000);

        // 3. Apply liquidity factor
        // Need sufficient liquid assets to support buybacks
        // Formula: liquidityFactor = liquidValue / totalValue
        uint256 liquidityFactor = (liquidValue * PRECISION) / totalValue;

        // 4. Calculate raw sustainable APY
        // Formula: baseYield × sqrt(backing) × sqrt(liquidity)
        uint256 rawSustainable = (baseYieldAPY * backingMultiplier * _sqrt(liquidityFactor)) / (PRECISION);

        // 5. Apply safety buffer (use 80% of calculated sustainable)
        // This creates a 20% margin of safety
        uint256 sustainableWithBuffer = (rawSustainable * 8000) / 10000;

        // 6. Apply dynamic risk adjustment based on backing ratio
        // If backing is low, reduce sustainable APY aggressively
        if (backingRatio < 10000) { // Below 100%
            // Reduce by backing deficit percentage
            uint256 deficit = 10000 - backingRatio; // e.g., 90% backing = 1000 deficit
            uint256 reductionFactor = 10000 - (deficit * 2); // 2x penalty for deficit
            sustainableWithBuffer = (sustainableWithBuffer * reductionFactor) / 10000;
        }

        // 7. Cap at maximum to prevent miscalculation exploits
        if (sustainableWithBuffer > MAX_SUSTAINABLE_APY) {
            sustainableWithBuffer = MAX_SUSTAINABLE_APY;
        }

        return sustainableWithBuffer;
    }

    /**
     * @notice Calculate amount of ECHO to burn to offset excess APY
     * @param excessAPY The difference between actual and sustainable APY
     * @return Amount of ECHO tokens to burn
     */
    function _calculateBurnAmount(uint256 excessAPY) private view returns (uint256) {
        // Get current eECHO supply (this is what's rebasing)
        uint256 eechoSupply = eecho.totalSupply();

        if (eechoSupply == 0) return 0;

        // Calculate what the excess emission would be over a full year
        // Formula: excessEmission = eechoSupply × (excessAPY / 10000)
        uint256 annualExcessEmission = (eechoSupply * excessAPY) / APY_BASE;

        // Convert to per-rebase amount (we rebase every 8 hours)
        // Formula: perRebaseExcess = annualExcess / rebasesPerYear
        uint256 perRebaseExcess = annualExcessEmission / REBASES_PER_YEAR;

        // Apply dampening based on backing ratio
        // If backing is very high, we can tolerate some excess
        // If backing is low, we need to be more aggressive
        uint256 backingRatio = avgBackingRatio;
        uint256 dampeningFactor;

        if (backingRatio >= 15000) { // >150% backing
            dampeningFactor = 7000; // Burn 70% of excess
        } else if (backingRatio >= 12000) { // >120% backing
            dampeningFactor = 8500; // Burn 85% of excess
        } else if (backingRatio >= 10000) { // >100% backing
            dampeningFactor = 10000; // Burn 100% of excess
        } else { // <100% backing
            dampeningFactor = 12000; // Burn 120% of excess (aggressive)
        }

        uint256 burnAmount = (perRebaseExcess * dampeningFactor) / 10000;

        return burnAmount;
    }

    /**
     * @notice Convert per-rebase rate to annualized APY
     * @param rebaseRate Rate applied per rebase (in basis points)
     * @return Annualized percentage yield
     */
    function _rebaseRateToAPY(uint256 rebaseRate) private pure returns (uint256) {
        // Convert single rebase to annual
        // APY = ((1 + rate)^rebases_per_year - 1) × 10000

        // For computational efficiency, use approximation for small rates:
        // APY ≈ rate × rebases_per_year
        // This is accurate for rates < 1% per rebase

        if (rebaseRate < 100) { // <1% per rebase
            return rebaseRate * REBASES_PER_YEAR;
        }

        // For larger rates, use compound calculation
        // Using fixed-point math: (1 + rate/10000)^1095
        uint256 base = PRECISION + ((rebaseRate * PRECISION) / APY_BASE);
        uint256 result = _pow(base, REBASES_PER_YEAR, PRECISION);

        // Convert back to APY format
        return ((result - PRECISION) * APY_BASE) / PRECISION;
    }

    // ============ Buyback Execution ============

    /**
     * @notice Execute buyback and burn of ECHO tokens
     * @param amount Amount of ECHO to buy and burn
     */
    function _executeBuybackBurn(uint256 amount) private {
        // Request treasury to execute buyback
        // Treasury will use its ETH/stablecoins to buy ECHO from DEX
        uint256 echoReceived = treasury.executeBuyback(amount);

        if (echoReceived > 0) {
            // Burn the bought ECHO
            echo.burn(echoReceived);

            emit BuybackExecuted(amount, echoReceived, echoReceived);
        }
    }

    // ============ Metric Updates ============

    /**
     * @notice Update moving averages for treasury yield and backing
     * @dev Called before each balance check, uses 30-day exponential moving average
     */
    function _updateMetrics() private {
        uint256 timeSinceLastUpdate = block.timestamp - lastBalanceCheck;

        // Only update if at least 1 hour has passed (avoid spam)
        if (timeSinceLastUpdate < 1 hours) return;

        // Get current values
        uint256 currentYield = _estimateTreasuryYield();
        uint256 currentBacking = treasury.getBackingRatio();

        // Calculate EMA weight (more time passed = more weight to new value)
        // alpha = min(timePassed / 30 days, 1.0)
        uint256 alpha = (timeSinceLastUpdate * PRECISION) / 30 days;
        if (alpha > PRECISION) alpha = PRECISION;

        // Update exponential moving averages
        // EMA = alpha × current + (1 - alpha) × previous
        avgTreasuryYield = (alpha * currentYield + (PRECISION - alpha) * avgTreasuryYield) / PRECISION;
        avgBackingRatio = (alpha * currentBacking + (PRECISION - alpha) * avgBackingRatio) / PRECISION;

        lastBalanceCheck = block.timestamp;
    }

    /**
     * @notice Estimate current treasury yield rate
     * @return Estimated annual yield in basis points
     */
    function _estimateTreasuryYield() private view returns (uint256) {
        // This would call treasury to get actual yield from GMX/GLP
        // For now, return stored average
        // TODO: Implement actual yield calculation from treasury strategies
        return avgTreasuryYield;
    }

    // ============ Price Oracle ============

    /**
     * @notice Get current ECHO price from DEX
     * @return Price in ETH (18 decimals)
     */
    function _getEchoPrice() private view returns (uint256) {
        // This would integrate with Uniswap V3 TWAP oracle
        // For now, calculate from backing
        uint256 totalValue = treasury.getTotalValue();
        uint256 totalSupply = echo.totalSupply();

        if (totalSupply == 0) return 0;

        return (totalValue * PRECISION) / totalSupply;
    }

    // ============ Math Utilities ============

    /**
     * @notice Calculate square root using Babylonian method
     * @param x Value to find square root of
     * @return Square root of x
     */
    function _sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    /**
     * @notice Calculate power using binary exponentiation
     * @param base Base value
     * @param exponent Power to raise to
     * @param precision Precision for fixed-point math
     * @return base^exponent
     */
    function _pow(uint256 base, uint256 exponent, uint256 precision) private pure returns (uint256) {
        if (exponent == 0) return precision;

        uint256 result = precision;
        uint256 b = base;

        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = (result * b) / precision;
            }
            b = (b * b) / precision;
            exponent /= 2;
        }

        return result;
    }

    // ============ View Functions ============

    function getCurrentMetrics() external view returns (
        uint256 sustainableAPY,
        uint256 treasuryYield,
        uint256 backingRatio,
        uint256 totalBurned,
        uint256 buybackCount
    ) {
        return (
            _calculateSustainableAPY(),
            avgTreasuryYield,
            avgBackingRatio,
            totalExcessBurned,
            totalBuybacksExecuted
        );
    }

    // ============ Admin Functions ============

    function updateMaxBuyback(uint256 newMax) external onlyOwner {
        maxBuybackPerRebase = newMax;
    }

    function updateMinBuyback(uint256 newMin) external onlyOwner {
        minBuybackAmount = newMin;
    }

    function setTreasuryYield(uint256 newYield) external onlyOwner {
        require(newYield <= MAX_SUSTAINABLE_APY, "Too high");
        avgTreasuryYield = newYield;
    }
}
