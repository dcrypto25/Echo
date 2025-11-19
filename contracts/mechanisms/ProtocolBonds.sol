// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IECHO.sol";
import "../interfaces/IeECHO.sol";

interface IBondingCurve {
    function totalEchoSold() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
}

interface IPriceOracle {
    function getECHOPrice() external view returns (uint256);
}

/**
 * @title ProtocolBonds
 * @notice OHM-style bonds - users deposit assets for discounted ECHO
 * @dev Continuously builds treasury by accepting ETH and stablecoins
 *
 * Features:
 * - 5% discount on all bonds
 * - 1-day vesting period (as eECHO)
 * - Auto-enables 1 week after bonding curve completes
 * - Accepts: ETH, USDC, USDT, DAI
 * - All proceeds → Treasury
 */
contract ProtocolBonds is Ownable, ReentrancyGuard {
    // ============ State Variables ============

    IECHO public immutable echo;
    IeECHO public immutable eEcho;
    address public immutable treasury;
    IBondingCurve public immutable bondingCurve;

    // Pricing (in USD terms: 1e18 = $1)
    IPriceOracle public priceOracle;
    uint256 public constant DISCOUNT_PERCENT = 500; // 5% discount (in basis points)
    uint256 public fixedPrice; // Fixed price in USD (1e18 = $1), 0 = use oracle
    uint256 public constant BONDING_CURVE_FINAL_PRICE = 0.015e18; // $0.015 USD

    // ETH price oracle for ETH payments
    address public ethPriceOracle; // Chainlink ETH/USD oracle

    // Vesting
    uint256 public constant VESTING_PERIOD = 1 days;

    // Activation
    bool public bondsEnabled;
    uint256 public bondingCurveCompletionTime;
    uint256 public constant ACTIVATION_DELAY = 7 days; // 1 week after bonding ends

    // Accepted tokens (Arbitrum addresses)
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    mapping(address => bool) public acceptedTokens;
    mapping(address => uint256) public tokenPrices; // In ETH terms (1e18 = 1 ETH)

    // Bond tracking
    struct Bond {
        uint256 echoAmount;      // Amount of ECHO being vested
        uint256 vestingEnd;      // When vesting completes
        bool claimed;            // Whether bond has been claimed
    }

    mapping(address => Bond[]) public userBonds;

    uint256 public totalBonded;      // Total value bonded (in USD terms)
    uint256 public totalEchoBonded;  // Total ECHO given via bonds

    // ============ Events ============

    event BondCreated(
        address indexed user,
        address indexed token,
        uint256 depositAmount,
        uint256 echoAmount,
        uint256 vestingEnd
    );

    event BondClaimed(
        address indexed user,
        uint256 bondId,
        uint256 echoAmount
    );

    event BondsEnabled(uint256 timestamp);
    event BondingCurveCompleted(uint256 timestamp);

    // ============ Constructor ============

    constructor(
        address _echo,
        address _eEcho,
        address _treasury,
        address _bondingCurve
    ) Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        require(_eEcho != address(0), "Zero address");
        require(_treasury != address(0), "Zero address");
        require(_bondingCurve != address(0), "Zero address");

        echo = IECHO(_echo);
        eEcho = IeECHO(_eEcho);
        treasury = _treasury;
        bondingCurve = IBondingCurve(_bondingCurve);

        // Set initial fixed price (matches bonding curve final price)
        fixedPrice = BONDING_CURVE_FINAL_PRICE;

        // Set accepted tokens
        acceptedTokens[address(0)] = true; // ETH
        acceptedTokens[WETH] = true;
        acceptedTokens[USDC] = true;
        acceptedTokens[USDT] = true;
        acceptedTokens[DAI] = true;

        // Set initial prices in USD terms (1e18 = $1)
        tokenPrices[address(0)] = 3000e18;     // ETH ≈ $3000 (use oracle in production)
        tokenPrices[WETH] = 3000e18;           // WETH ≈ $3000 (use oracle in production)
        tokenPrices[USDC] = 1e18;              // USDC = $1
        tokenPrices[USDT] = 1e18;              // USDT = $1
        tokenPrices[DAI] = 1e18;               // DAI = $1
    }

    // ============ Bond Creation ============

    /**
     * @notice Bond ETH for ECHO
     */
    function bondETH() external payable nonReentrant returns (uint256 bondId) {
        require(isBondsActive(), "Bonds not active");
        require(msg.value > 0, "Zero payment");

        // Convert ETH to USD value
        uint256 usdValue = _convertToUSD(msg.value, address(0));
        uint256 echoAmount = _calculateBondAmount(usdValue, address(0));

        bondId = _createBond(msg.sender, echoAmount);

        // Forward ETH to treasury
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "ETH transfer failed");

        emit BondCreated(msg.sender, address(0), msg.value, echoAmount, block.timestamp + VESTING_PERIOD);

        return bondId;
    }

    /**
     * @notice Bond ERC20 token for discounted ECHO
     * @param token Token address
     * @param amount Amount to bond
     */
    function bondToken(address token, uint256 amount)
        external
        nonReentrant
        returns (uint256 bondId)
    {
        require(isBondsActive(), "Bonds not active");
        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Zero amount");

        // Transfer tokens to treasury
        IERC20(token).transferFrom(msg.sender, treasury, amount);

        // Calculate ECHO amount (convert token to USD, then USD to ECHO)
        uint256 usdValue = _convertToUSD(amount, token);
        uint256 echoAmount = _calculateBondAmount(usdValue, token);

        bondId = _createBond(msg.sender, echoAmount);

        emit BondCreated(msg.sender, token, amount, echoAmount, block.timestamp + VESTING_PERIOD);

        return bondId;
    }

    function _createBond(address user, uint256 echoAmount) private returns (uint256 bondId) {
        // Mint ECHO for bond
        echo.mint(address(this), echoAmount);

        // Approve and wrap to eECHO
        echo.approve(address(eEcho), echoAmount);
        eEcho.wrap(echoAmount);

        // Create bond record
        Bond memory newBond = Bond({
            echoAmount: echoAmount,
            vestingEnd: block.timestamp + VESTING_PERIOD,
            claimed: false
        });

        userBonds[user].push(newBond);
        bondId = userBonds[user].length - 1;

        totalEchoBonded += echoAmount;

        return bondId;
    }

    // ============ Bond Claiming ============

    /**
     * @notice Claim vested bond
     * @param bondId Bond ID to claim
     */
    function claimBond(uint256 bondId) external nonReentrant {
        require(bondId < userBonds[msg.sender].length, "Invalid bond ID");

        Bond storage bond = userBonds[msg.sender][bondId];
        require(!bond.claimed, "Already claimed");
        require(block.timestamp >= bond.vestingEnd, "Still vesting");

        bond.claimed = true;

        // Transfer eECHO to user
        require(eEcho.transfer(msg.sender, bond.echoAmount), "Transfer failed");

        emit BondClaimed(msg.sender, bondId, bond.echoAmount);
    }

    /**
     * @notice Claim multiple vested bonds
     * @param bondIds Array of bond IDs to claim
     */
    function claimBonds(uint256[] calldata bondIds) external nonReentrant {
        uint256 totalClaim = 0;

        for (uint256 i = 0; i < bondIds.length; i++) {
            uint256 bondId = bondIds[i];
            require(bondId < userBonds[msg.sender].length, "Invalid bond ID");

            Bond storage bond = userBonds[msg.sender][bondId];

            if (!bond.claimed && block.timestamp >= bond.vestingEnd) {
                bond.claimed = true;
                totalClaim += bond.echoAmount;
                emit BondClaimed(msg.sender, bondId, bond.echoAmount);
            }
        }

        require(totalClaim > 0, "Nothing to claim");
        require(eEcho.transfer(msg.sender, totalClaim), "Transfer failed");
    }

    // ============ Price Calculation ============

    /**
     * @notice Calculate bond amount based on USD value
     * @param usdValue USD value (1e18 = $1)
     * @return echoAmount Amount of ECHO to receive
     */
    function _calculateBondAmount(uint256 usdValue, address /* token */)
        private
        view
        returns (uint256 echoAmount)
    {
        // Get current ECHO price in USD
        uint256 echoPriceUSD = _getECHOPrice();

        // Calculate ECHO amount: usdValue / echoPriceUSD
        uint256 echoAtMarket = (usdValue * 1e18) / echoPriceUSD;

        // Apply 5% discount ONLY if not in fixed price mode
        if (fixedPrice > 0) {
            // Fixed price mode: no discount
            echoAmount = echoAtMarket;
        } else {
            // Oracle mode: apply 5% discount
            uint256 discountMultiplier = 10000 + DISCOUNT_PERCENT; // 10500 (105%)
            echoAmount = (echoAtMarket * discountMultiplier) / 10000;
        }

        return echoAmount;
    }

    function _getECHOPrice() private view returns (uint256) {
        // If fixed price is set, use it (no discount)
        if (fixedPrice > 0) {
            return fixedPrice;
        }

        // If oracle is set, use it (with discount applied in _calculateBondAmount)
        if (address(priceOracle) != address(0)) {
            return priceOracle.getECHOPrice();
        }

        // Fallback: use bonding curve final price
        return BONDING_CURVE_FINAL_PRICE;
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

    // ============ Activation Logic ============

    /**
     * @notice Check if bonding curve is complete and mark completion
     */
    function checkBondingCurveCompletion() public {
        if (bondingCurveCompletionTime == 0) {
            if (bondingCurve.totalEchoSold() >= bondingCurve.MAX_SUPPLY()) {
                bondingCurveCompletionTime = block.timestamp;
                emit BondingCurveCompleted(block.timestamp);
            }
        }
    }

    /**
     * @notice Check if bonds are currently active
     */
    function isBondsActive() public view returns (bool) {
        if (!bondsEnabled) return false;
        if (bondingCurveCompletionTime == 0) return false;
        return block.timestamp >= bondingCurveCompletionTime + ACTIVATION_DELAY;
    }

    /**
     * @notice Enable bonds (owner only, or auto after delay)
     */
    function enableBonds() external onlyOwner {
        require(!bondsEnabled, "Already enabled");
        bondsEnabled = true;
        emit BondsEnabled(block.timestamp);
    }

    /**
     * @notice Disable bonds (emergency only)
     */
    function disableBonds() external onlyOwner {
        bondsEnabled = false;
    }

    // ============ View Functions ============

    /**
     * @notice Get all bonds for a user
     */
    function getUserBonds(address user) external view returns (Bond[] memory) {
        return userBonds[user];
    }

    /**
     * @notice Get claimable bonds for a user
     */
    function getClaimableBonds(address user) external view returns (uint256[] memory) {
        Bond[] memory bonds = userBonds[user];
        uint256 claimableCount = 0;

        // Count claimable
        for (uint256 i = 0; i < bonds.length; i++) {
            if (!bonds[i].claimed && block.timestamp >= bonds[i].vestingEnd) {
                claimableCount++;
            }
        }

        // Build array
        uint256[] memory claimable = new uint256[](claimableCount);
        uint256 index = 0;

        for (uint256 i = 0; i < bonds.length; i++) {
            if (!bonds[i].claimed && block.timestamp >= bonds[i].vestingEnd) {
                claimable[index++] = i;
            }
        }

        return claimable;
    }

    /**
     * @notice Get bond quote for a deposit
     * @param depositAmount Amount to deposit
     * @param token Token address (0 for ETH)
     */
    function getBondQuote(uint256 depositAmount, address token)
        external
        view
        returns (uint256 echoAmount, uint256 vestingEnd)
    {
        uint256 usdValue = _convertToUSD(depositAmount, token);
        echoAmount = _calculateBondAmount(usdValue, token);
        vestingEnd = block.timestamp + VESTING_PERIOD;
    }

    /**
     * @notice Time until bonds activate
     */
    function timeUntilActivation() external view returns (uint256) {
        if (!bondsEnabled) return type(uint256).max;
        if (bondingCurveCompletionTime == 0) return type(uint256).max;

        uint256 activationTime = bondingCurveCompletionTime + ACTIVATION_DELAY;
        if (block.timestamp >= activationTime) return 0;

        return activationTime - block.timestamp;
    }

    // ============ Admin Functions ============

    /**
     * @notice Set price oracle and switch to oracle mode (with 5% discount)
     * @param _oracle Oracle address
     */
    function setPriceOracle(address _oracle) external onlyOwner {
        priceOracle = IPriceOracle(_oracle);
        fixedPrice = 0; // Switch to oracle mode
    }

    /**
     * @notice Set fixed price mode (no discount)
     * @param _price Fixed price in ETH (18 decimals)
     */
    function setFixedPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be > 0");
        fixedPrice = _price;
    }

    /**
     * @notice Switch to oracle mode (5% discount on market price)
     */
    function enableOracleMode() external onlyOwner {
        require(address(priceOracle) != address(0), "Oracle not set");
        fixedPrice = 0;
    }

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

    // Emergency withdraw (only if something goes wrong)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = treasury.call{value: balance}("");
            require(success, "Withdraw failed");
        }
    }

    receive() external payable {}
}
