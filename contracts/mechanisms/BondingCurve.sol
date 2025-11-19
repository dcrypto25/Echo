// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IECHO.sol";

/**
 * @title BondingCurve
 * @notice Fair launch mechanism for ECHO token via exponential bonding curve
 * @dev Accepts ETH and stablecoins, all proceeds go to treasury
 *
 * Price Formula: price = initial_price * (1 + supply/max_supply)^5.64
 * Starting at $0.0003, ending at $0.015 (50x increase)
 * This creates optimal price discovery: massive early advantage, sustainable completion
 * Expected treasury raised: ~$9,500
 */
contract BondingCurve is Ownable, ReentrancyGuard {
    // ============ State Variables ============

    IECHO public immutable echo;
    address public immutable treasury;

    // Curve parameters (in USD: 1e18 = $1)
    uint256 public constant INITIAL_PRICE = 0.0003e18; // $0.0003 USD
    uint256 public constant FINAL_PRICE = 0.015e18;     // $0.015 USD (50x increase)
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18;

    uint256 public totalEchoSold;
    uint256 public launchTime;

    // Anti-bot protection (first 24 hours)
    uint256 public maxBuyAmount = 10_000 * 10**18; // 10K ECHO max per tx
    uint256 public constant ANTI_BOT_PERIOD = 24 hours;

    // Accepted payment tokens (Arbitrum addresses)
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    mapping(address => bool) public acceptedTokens;

    // Token prices in USD (1e18 = $1)
    mapping(address => uint256) public tokenPrices;

    // ============ Events ============

    event Purchase(
        address indexed buyer,
        uint256 echoAmount,
        uint256 cost,
        address paymentToken
    );

    event Launch(uint256 timestamp);

    // ============ Constructor ============

    constructor(address _echo, address _treasury) Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        require(_treasury != address(0), "Zero address");

        echo = IECHO(_echo);
        treasury = _treasury;

        // Set accepted tokens
        acceptedTokens[address(0)] = true; // ETH
        acceptedTokens[WETH] = true;
        acceptedTokens[USDC] = true;
        acceptedTokens[USDT] = true;
        acceptedTokens[DAI] = true;

        // Set initial prices in USD (1e18 = $1)
        tokenPrices[address(0)] = 3000e18;     // ETH ≈ $3000 (update via governance)
        tokenPrices[WETH] = 3000e18;           // WETH ≈ $3000 (update via governance)
        tokenPrices[USDC] = 1e18;              // USDC = $1
        tokenPrices[USDT] = 1e18;              // USDT = $1
        tokenPrices[DAI] = 1e18;               // DAI = $1
    }

    // ============ Launch ============

    function launch() external onlyOwner {
        require(launchTime == 0, "Already launched");
        launchTime = block.timestamp;
        emit Launch(block.timestamp);
    }

    // ============ Purchase Functions ============

    /**
     * @notice Buy ECHO with ETH
     */
    function buyWithETH() external payable nonReentrant returns (uint256 echoAmount) {
        require(launchTime > 0, "Not launched");
        require(msg.value > 0, "Zero payment");

        // Convert ETH to USD value
        uint256 usdValue = _convertToUSD(msg.value, address(0));
        echoAmount = _calculateEchoAmount(usdValue, address(0));
        _executePurchase(msg.sender, echoAmount, msg.value, address(0));

        // Forward ETH to treasury
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "ETH transfer failed");

        return echoAmount;
    }

    /**
     * @notice Buy ECHO with ERC20 token
     * @param token Token address
     * @param amount Amount of tokens to spend
     */
    function buyWithToken(address token, uint256 amount)
        external
        nonReentrant
        returns (uint256 echoAmount)
    {
        require(launchTime > 0, "Not launched");
        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Zero amount");

        // Transfer tokens from user
        IERC20(token).transferFrom(msg.sender, treasury, amount);

        // Calculate ECHO amount (convert to USD first)
        uint256 usdValue = _convertToUSD(amount, token);
        echoAmount = _calculateEchoAmount(usdValue, token);

        _executePurchase(msg.sender, echoAmount, amount, token);

        return echoAmount;
    }

    // ============ Internal Functions ============

    function _executePurchase(
        address buyer,
        uint256 echoAmount,
        uint256 cost,
        address paymentToken
    ) private {
        // Anti-bot check (first 24 hours)
        if (block.timestamp < launchTime + ANTI_BOT_PERIOD) {
            require(echoAmount <= maxBuyAmount, "Exceeds max buy");
        }

        require(totalEchoSold + echoAmount <= MAX_SUPPLY, "Exceeds max supply");

        // Update sold amount
        totalEchoSold += echoAmount;

        // Transfer ECHO to buyer
        require(echo.transfer(buyer, echoAmount), "Transfer failed");

        emit Purchase(buyer, echoAmount, cost, paymentToken);
    }

    /**
     * @notice Calculate ECHO amount for a given payment
     * @param usdValue Value in USD (1e18 = $1)
     * @return echoAmount Amount of ECHO to receive
     */
    function _calculateEchoAmount(uint256 usdValue, address /* token */)
        private
        view
        returns (uint256 echoAmount)
    {
        // Binary search to find amount
        // We need to integrate the curve: ∫ price(s) ds from totalEchoSold to totalEchoSold + amount

        uint256 low = 0;
        uint256 high = MAX_SUPPLY - totalEchoSold;
        uint256 mid;

        // 50 iterations = ~15 decimal precision
        for (uint256 i = 0; i < 50; i++) {
            mid = (low + high) / 2;
            uint256 cost = _integrateCurve(totalEchoSold, totalEchoSold + mid);

            if (cost < usdValue) {
                low = mid;
            } else if (cost > usdValue) {
                high = mid;
            } else {
                return mid;
            }

            if (high - low <= 1e10) break; // Close enough
        }

        return low;
    }

    /**
     * @notice Integrate bonding curve from start to end supply
     * @param start Starting supply
     * @param end Ending supply
     * @return Total cost in USD (1e18 = $1)
     */
    function _integrateCurve(uint256 start, uint256 end) private pure returns (uint256) {
        if (start >= end) return 0;

        // Simplified numerical integration (trapezoidal rule)
        uint256 steps = 100;
        uint256 stepSize = (end - start) / steps;
        uint256 sum = 0;

        for (uint256 i = 0; i < steps; i++) {
            uint256 s1 = start + i * stepSize;
            uint256 s2 = start + (i + 1) * stepSize;

            uint256 p1 = _curvePrice(s1);
            uint256 p2 = _curvePrice(s2);

            sum += ((p1 + p2) * stepSize) / 2;
        }

        return sum / 1e18; // Adjust for precision
    }

    /**
     * @notice Calculate price at a given supply level
     * @param supply Current supply
     * @return Price in USD (1e18 = $1)
     */
    function _curvePrice(uint256 supply) private pure returns (uint256) {
        if (supply >= MAX_SUPPLY) return FINAL_PRICE;

        // price = INITIAL_PRICE * (1 + supply/MAX_SUPPLY)^5.64
        // Using approximation for exponent 5.64 ≈ 2^2.5
        uint256 ratio = (supply * 1e18) / MAX_SUPPLY; // supply ratio in 1e18
        uint256 onePlusRatio = 1e18 + ratio;

        // Calculate (1 + ratio)^5.64 ≈ (1 + ratio)^5.5
        // = (1 + ratio)^5 * (1 + ratio)^0.5
        // = ((1 + ratio)^2)^2 * (1 + ratio) * sqrt(1 + ratio)

        uint256 squared = (onePlusRatio * onePlusRatio) / 1e18;
        uint256 toTheFourth = (squared * squared) / 1e18;
        uint256 toTheFifth = (toTheFourth * onePlusRatio) / 1e18;

        // Approximate sqrt(1 + ratio) using Babylonian method (good enough for our purposes)
        uint256 sqrtTerm = _sqrt(onePlusRatio * 1e18) / 1e9;

        uint256 result = (toTheFifth * sqrtTerm) / 1e18;

        return (INITIAL_PRICE * result) / 1e18;
    }

    /**
     * @notice Integer square root (Babylonian method)
     * @param x Value to find square root of
     * @return Square root
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
     * @notice Convert token amount to USD value
     * @param amount Token amount
     * @param token Token address
     * @return USD value (1e18 = $1)
     */
    function _convertToUSD(uint256 amount, address token) private view returns (uint256) {
        // Get token price in USD
        uint256 priceInUSD = tokenPrices[token];

        // Adjust for decimals
        uint256 adjustedAmount = amount;
        if (token == USDC || token == USDT) {
            // USDC/USDT have 6 decimals, convert to 18
            adjustedAmount = amount * 1e12;
        } else if (token == address(0) || token == WETH) {
            // ETH/WETH have 18 decimals already
            adjustedAmount = amount;
        }
        // DAI has 18 decimals already

        // Calculate USD value
        return (adjustedAmount * priceInUSD) / 1e18;
    }

    // ============ View Functions ============

    /**
     * @notice Get current price per ECHO
     * @return Price in USD (1e18 = $1)
     */
    function getCurrentPrice() external view returns (uint256) {
        return _curvePrice(totalEchoSold);
    }

    /**
     * @notice Calculate ECHO amount for a given payment
     * @param paymentAmount Amount of payment token
     * @param paymentToken Token address (0 for ETH)
     * @return ECHO amount
     */
    function getEchoAmount(uint256 paymentAmount, address paymentToken)
        external
        view
        returns (uint256)
    {
        uint256 usdValue = _convertToUSD(paymentAmount, paymentToken);
        return _calculateEchoAmount(usdValue, paymentToken);
    }

    /**
     * @notice Get cost for a specific ECHO amount
     * @param echoAmount Amount of ECHO desired
     * @return Cost in USD (1e18 = $1)
     */
    function getCost(uint256 echoAmount) external view returns (uint256) {
        require(totalEchoSold + echoAmount <= MAX_SUPPLY, "Exceeds max supply");
        return _integrateCurve(totalEchoSold, totalEchoSold + echoAmount);
    }

    // ============ Admin Functions ============

    /**
     * @notice Update token price in USD (GOVERNANCE ONLY)
     * @param token Token address
     * @param priceInUSD Price in USD (1e18 = $1)
     */
    function updateTokenPrice(address token, uint256 priceInUSD) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        tokenPrices[token] = priceInUSD;
    }

    /**
     * @notice Update ETH price in USD (GOVERNANCE ONLY)
     * @param priceInUSD ETH price in USD (1e18 = $1)
     * @dev Use Chainlink oracle or governance vote to update
     */
    function updateETHPrice(uint256 priceInUSD) external onlyOwner {
        require(priceInUSD > 0, "Price must be > 0");
        tokenPrices[address(0)] = priceInUSD;
        tokenPrices[WETH] = priceInUSD;
    }

    function updateMaxBuyAmount(uint256 newMax) external onlyOwner {
        maxBuyAmount = newMax;
    }

    // Emergency withdraw (only if something goes wrong)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = treasury.call{value: balance}("");
            require(success, "Withdraw failed");
        }
    }

    receive() external payable {
        // Allow receiving ETH
    }
}
