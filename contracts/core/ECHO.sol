// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IECHO.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IBondingCurve {
    function getCurrentPrice() external view returns (uint256);
}

/**
 * @title ECHO
 * @notice Main ERC20 token with adaptive transfer tax and auto-swap
 * @dev Tax rate adjusts based on staking ratio to incentivize staking
 *
 * Key Features:
 * - Adaptive transfer tax (4-15% based on staking ratio)
 * - Auto-swap on ALL transfers: 50% ECHO kept, 50% swapped to ETH
 * - All tax revenue goes to Treasury (mixed ECHO + ETH)
 * - Whitelist for staking/treasury operations (no tax)
 * - Mintable for rebasing and referral rewards (no hard cap)
 */
contract ECHO is ERC20, Ownable, ReentrancyGuard, IECHO {
    // ============ State Variables ============

    // Tax configuration (in basis points: 100 = 1%)
    uint256 public constant BASE_TAX_RATE = 400;           // 4% base tax
    uint256 public constant MAX_TAX_RATE = 1500;           // 15% max tax
    uint256 public constant TARGET_STAKING_RATIO = 9000;   // 90% target

    // Auto-swap configuration
    uint256 public constant SWAP_THRESHOLD_USD = 50 * 10**18; // Min $50 USD worth to trigger swap
    bool private inSwap;                                       // Reentrancy guard for swaps

    // Current state
    uint256 public currentStakingRatio;   // In basis points (8800 = 88%)
    uint256 public override totalBurned;  // Total tokens burned

    // Contract addresses
    address public treasury;              // Treasury contract
    address public stakingContract;       // Staking contract (can update ratio)
    address public bondingCurve;          // Bonding curve for price oracle
    address public uniswapV2Router;       // Uniswap router for auto-swap
    address public uniswapV2Pair;         // ECHO-ETH pair

    // Whitelist mapping (staking, treasury - no tax)
    mapping(address => bool) private _whitelist;

    // DEX pair mapping (for detecting sells)
    mapping(address => bool) public isDEXPair;

    // Minter role mapping (contracts that can mint ECHO)
    mapping(address => bool) public isMinter;

    // ============ Constructor ============

    /**
     * @notice Initialize ECHO token
     * @param initialSupply Initial token supply (will be minted via bonding curve)
     */
    constructor(uint256 initialSupply) ERC20("EchoForge", "ECHO") Ownable(msg.sender) {
        // Mint initial supply to bonding curve contract (set later)
        // For now, mint to deployer (will transfer to bonding curve)
        _mint(msg.sender, initialSupply * 10**decimals());

        // Initialize staking ratio to 0 (no one staking yet)
        currentStakingRatio = 0;
    }

    // ============ Configuration Functions ============

    /**
     * @notice Set Treasury address (one-time)
     * @param _treasury Address of Treasury contract
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(treasury == address(0), "Already set");
        require(_treasury != address(0), "Zero address");
        treasury = _treasury;
        _whitelist[_treasury] = true; // Treasury is whitelisted
    }

    /**
     * @notice Set Bonding Curve address (one-time)
     * @param _bondingCurve Address of Bonding Curve contract
     */
    function setBondingCurve(address _bondingCurve) external onlyOwner {
        require(bondingCurve == address(0), "Already set");
        require(_bondingCurve != address(0), "Zero address");
        bondingCurve = _bondingCurve;
    }

    /**
     * @notice Set Uniswap router and pair (one-time)
     * @param _router Uniswap V2 router address
     * @param _pair ECHO-ETH pair address
     */
    function setUniswapAddresses(address _router, address _pair) external onlyOwner {
        require(uniswapV2Router == address(0), "Already set");
        require(_router != address(0) && _pair != address(0), "Zero address");
        uniswapV2Router = _router;
        uniswapV2Pair = _pair;
        isDEXPair[_pair] = true;
        _whitelist[_router] = true;
    }

    /**
     * @notice Set DEX pair status
     * @param pair Pair address
     * @param status True if DEX pair
     */
    function setDEXPair(address pair, bool status) external onlyOwner {
        isDEXPair[pair] = status;
    }

    /**
     * @notice Set Staking contract address (one-time)
     * @param _stakingContract Address of Staking contract
     */
    function setStakingContract(address _stakingContract) external onlyOwner {
        require(stakingContract == address(0), "Already set");
        require(_stakingContract != address(0), "Zero address");
        stakingContract = _stakingContract;
        _whitelist[_stakingContract] = true; // Staking is whitelisted
    }

    /**
     * @notice Update whitelist status for an address
     * @param account Address to update
     * @param status New whitelist status
     */
    function setWhitelist(address account, bool status) external override onlyOwner {
        _whitelist[account] = status;
        emit WhitelistUpdated(account, status);
    }

    /**
     * @notice Grant minter role to an address (GOVERNANCE ONLY)
     * @param account Address to grant minter role
     */
    function grantMinterRole(address account) external onlyOwner {
        require(account != address(0), "Zero address");
        isMinter[account] = true;
    }

    /**
     * @notice Revoke minter role from an address (GOVERNANCE ONLY)
     * @param account Address to revoke minter role from
     */
    function revokeMinterRole(address account) external onlyOwner {
        isMinter[account] = false;
    }

    /**
     * @notice Mint new ECHO tokens (only callable by authorized minters)
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external override {
        require(isMinter[msg.sender], "Not authorized to mint");
        require(to != address(0), "Zero address");
        _mint(to, amount);
    }

    // ============ Core Transfer Logic ============

    /**
     * @notice Transfer tokens with adaptive tax
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transfer(address to, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        _transferWithTax(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice TransferFrom with adaptive tax
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        _spendAllowance(from, msg.sender, amount);
        _transferWithTax(from, to, amount);
        return true;
    }

    /**
     * @notice Internal transfer with tax logic and auto-swap
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _transferWithTax(address from, address to, uint256 amount) private {
        // Check if whitelisted (no tax)
        if (_whitelist[from] || _whitelist[to] || inSwap) {
            _transfer(from, to, amount);
            return;
        }

        // Calculate tax
        uint256 tax = _calculateTax(amount);

        // Collect tax to contract
        if (tax > 0) {
            _transfer(from, address(this), tax);

            // Trigger auto-swap on ANY transfer (not just sells)
            // This swaps 50% ECHO to ETH, sends both to treasury
            if (!inSwap && uniswapV2Router != address(0)) {
                _autoSwapAndSend();
            }
        }

        // Transfer remaining amount to recipient
        uint256 amountAfterTax = amount - tax;
        _transfer(from, to, amountAfterTax);
    }

    /**
     * @notice Auto-swap 50% of accumulated ECHO tax to ETH, send all to treasury
     * @dev Called on all transfers when threshold is met
     * @dev Swaps 50% ECHO → ETH, sends both ECHO and ETH to treasury
     */
    function _autoSwapAndSend() private {
        uint256 contractBalance = balanceOf(address(this));

        // Check if contract balance meets USD threshold ($50+)
        if (bondingCurve != address(0)) {
            uint256 currentPrice = IBondingCurve(bondingCurve).getCurrentPrice();
            uint256 balanceUSD = (contractBalance * currentPrice) / 1e18;
            if (balanceUSD < SWAP_THRESHOLD_USD) return;
        } else {
            return; // No bonding curve set, skip swap
        }

        inSwap = true;

        // Split: 50% keep as ECHO, 50% swap to ETH
        uint256 halfToSwap = contractBalance / 2;
        uint256 halfToKeep = contractBalance - halfToSwap;

        // Swap ECHO for ETH
        if (halfToSwap > 0) {
            _swapECHOForETH(halfToSwap);
        }

        // Send ECHO to treasury
        if (halfToKeep > 0 && treasury != address(0)) {
            _transfer(address(this), treasury, halfToKeep);
        }

        // Send ETH to treasury
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0 && treasury != address(0)) {
            (bool success, ) = treasury.call{value: ethBalance}("");
            require(success, "ETH transfer failed");
        }

        inSwap = false;
    }

    /**
     * @notice Swap ECHO for ETH via Uniswap
     * @param amount Amount of ECHO to swap
     */
    function _swapECHOForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(uniswapV2Router).WETH();

        _approve(address(this), uniswapV2Router, amount);

        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // Receive ETH from Uniswap swaps
    receive() external payable {}

    /**
     * @notice Calculate tax based on current staking ratio
     * @param amount Amount being transferred
     * @return tax Total tax amount (all goes to treasury, 50% as ECHO, 50% as ETH)
     */
    function _calculateTax(uint256 amount) private view returns (uint256 tax) {
        // Start with base tax rate
        uint256 taxRate = BASE_TAX_RATE;

        // Increase tax if staking ratio is below target
        if (currentStakingRatio < TARGET_STAKING_RATIO) {
            // Calculate deficit
            uint256 ratioDeficit = TARGET_STAKING_RATIO - currentStakingRatio;

            // Additional tax scales linearly from 0% to 11% (MAX - BASE)
            // ratioDeficit can be 0-9000 (0-90%)
            // Additional tax: (deficit / 9000) * 1100 = 0-1100 basis points
            uint256 additionalTax = (ratioDeficit * (MAX_TAX_RATE - BASE_TAX_RATE)) /
                TARGET_STAKING_RATIO;

            taxRate += additionalTax;

            // Cap at max rate
            if (taxRate > MAX_TAX_RATE) {
                taxRate = MAX_TAX_RATE;
            }
        }

        // Calculate total tax (all goes to treasury, 50% ECHO + 50% ETH via auto-swap)
        tax = (amount * taxRate) / 10000;

        return tax;
    }

    // ============ Staking Ratio Update ============

    /**
     * @notice Update staking ratio (only callable by staking contract)
     * @param newRatio New staking ratio in basis points
     */
    function updateStakingRatio(uint256 newRatio) external override {
        require(msg.sender == stakingContract, "Only staking contract");
        require(newRatio <= 10000, "Invalid ratio");

        uint256 oldRatio = currentStakingRatio;
        currentStakingRatio = newRatio;

        emit StakingRatioUpdated(oldRatio, newRatio);
    }

    // ============ Burn Function ============

    /**
     * @notice Burn tokens (callable by anyone for their own tokens)
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
        totalBurned += amount;
        emit Burned(msg.sender, amount);
    }

    /**
     * @notice Burn tokens from an address (requires allowance)
     * @param from Address to burn from
     * @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        totalBurned += amount;
        emit Burned(from, amount);
    }

    // ============ View Functions ============

    /**
     * @notice Get current tax rate based on staking ratio
     * @return Tax rate in basis points
     */
    function getCurrentTaxRate() external view override returns (uint256) {
        uint256 tax = _calculateTax(10000); // Calculate for 10000 to get rate
        return tax; // Will be in basis points
    }

    /**
     * @notice Check if an address is whitelisted
     * @param account Address to check
     * @return True if whitelisted
     */
    function isWhitelisted(address account) external view override returns (bool) {
        return _whitelist[account];
    }

    /**
     * @notice Get circulating supply (total supply - burned)
     * @return Circulating supply
     */
    function circulatingSupply() external view returns (uint256) {
        return totalSupply();
    }
}
