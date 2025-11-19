// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IeECHO.sol";
import "../interfaces/IECHO.sol";

/**
 * @title eECHO
 * @notice Rebasing wrapper for staked ECHO tokens
 * @dev Uses elastic supply with dynamic APY based on backing ratio
 *
 * Key Features:
 * - Elastic supply that rebases every 8 hours
 * - Dynamic APY: 0-30,000% based on backing ratio (self-regulating)
 * - High backing (>150%) → Aggressive APY to attract capital
 * - Low backing (<90%) → APY drops fast to slow emissions
 * - 1:1 wrapping/unwrapping with ECHO
 */
contract eECHO is ERC20, Ownable, ReentrancyGuard, IeECHO {
    // ============ State Variables ============

    // Core contracts
    IECHO public immutable echo;

    // Rebase configuration
    uint256 public constant REBASE_FREQUENCY = 8 hours;
    uint256 public constant REBASES_PER_YEAR = 1095; // 365 * 3

    // Dynamic APY configuration (self-regulating based on backing)
    uint256 public lastRebaseTime;
    uint256 public override epoch;

    // Backing ratio (updated by treasury, in basis points: 10000 = 100%)
    uint256 public override backingRatio = 10000; // 100% default

    // Elastic supply mechanics
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000 * 10**18;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    // Authorized contracts
    address public treasury;

    // ============ Constructor ============

    constructor(address _echo) ERC20("Staked Echo", "eECHO") Ownable(msg.sender) {
        require(_echo != address(0), "Zero address");
        echo = IECHO(_echo);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        lastRebaseTime = block.timestamp;
    }

    // ============ Configuration ============

    function setTreasury(address _treasury) external onlyOwner {
        require(treasury == address(0), "Already set");
        require(_treasury != address(0), "Zero address");
        treasury = _treasury;
    }

    // ============ Wrapping/Unwrapping ============

    /**
     * @notice Wrap ECHO to receive eECHO
     * @param echoAmount Amount of ECHO to wrap
     * @return eEchoAmount Amount of eECHO minted
     */
    function wrap(uint256 echoAmount)
        external
        override
        nonReentrant
        returns (uint256 eEchoAmount)
    {
        require(echoAmount > 0, "Zero amount");

        // Transfer ECHO from user
        require(echo.transferFrom(msg.sender, address(this), echoAmount), "Transfer failed");

        // Mint eECHO 1:1 (initially)
        eEchoAmount = echoAmount;
        uint256 gonAmount = eEchoAmount * _gonsPerFragment;

        _gonBalances[msg.sender] += gonAmount;
        _totalSupply += eEchoAmount;

        emit Transfer(address(0), msg.sender, eEchoAmount);
        return eEchoAmount;
    }

    /**
     * @notice Unwrap eECHO to receive ECHO
     * @param eEchoAmount Amount of eECHO to unwrap
     * @return echoAmount Amount of ECHO returned
     */
    function unwrap(uint256 eEchoAmount)
        external
        override
        nonReentrant
        returns (uint256 echoAmount)
    {
        require(eEchoAmount > 0, "Zero amount");
        require(balanceOf(msg.sender) >= eEchoAmount, "Insufficient balance");

        // Burn eECHO
        uint256 gonAmount = eEchoAmount * _gonsPerFragment;
        _gonBalances[msg.sender] -= gonAmount;
        _totalSupply -= eEchoAmount;

        // Return ECHO 1:1
        echoAmount = eEchoAmount;
        require(echo.transfer(msg.sender, echoAmount), "Transfer failed");

        emit Transfer(msg.sender, address(0), eEchoAmount);
        return echoAmount;
    }

    // ============ Rebase Logic ============

    /**
     * @notice Trigger rebase (can be called by anyone)
     * @return New total supply
     */
    function rebase() external override returns (uint256) {
        require(block.timestamp >= lastRebaseTime + REBASE_FREQUENCY, "Too soon");

        uint256 rebaseRate = getCurrentRebaseRate();

        if (rebaseRate == 0) {
            // No rebase if dampened to 0
            lastRebaseTime = block.timestamp;
            epoch++;
            return _totalSupply;
        }

        // Calculate supply increase
        uint256 supplyDelta = (_totalSupply * rebaseRate) / 1e18;
        _totalSupply += supplyDelta;

        // Update gons per fragment
        if (_totalSupply > 0) {
            _gonsPerFragment = TOTAL_GONS / _totalSupply;
        }

        lastRebaseTime = block.timestamp;
        epoch++;

        emit Rebase(epoch, _totalSupply);
        return _totalSupply;
    }

    /**
     * @notice Calculate current rebase rate with dynamic APY
     * @return Rebase rate in 1e18 precision (scaled by 1e18)
     * @dev CRITICAL: Uses COMPOUND growth formula, not linear!
     * @dev Formula: rebaseRate = (1 + APY)^(1/1095) - 1
     * @dev Uses lookup table for gas efficiency and accuracy
     */
    function getCurrentRebaseRate() public view override returns (uint256) {
        // Get dynamic APY based on backing ratio (in basis points)
        uint256 currentAPY = calculateDynamicAPY(backingRatio);

        // Convert APY to per-rebase rate using compound growth
        // Pre-calculated: (1 + APY)^(1/1095) - 1 for common APY values
        uint256 rebaseRateBPS; // Rate in basis points (10000 = 100%)

        // Lookup table for compound rebase rates
        if (currentAPY >= 280000) {
            rebaseRateBPS = 57; // ~0.57% for 30,000% APY
        } else if (currentAPY >= 180000) {
            rebaseRateBPS = 49; // ~0.49% for 18,000% APY
        } else if (currentAPY >= 80000) {
            rebaseRateBPS = 41; // ~0.41% for 8,000% APY
        } else if (currentAPY >= 30000) {
            rebaseRateBPS = 31; // ~0.31% for 3,000% APY
        } else if (currentAPY >= 10000) {
            rebaseRateBPS = 21; // ~0.21% for 1,000% APY
        } else if (currentAPY >= 5000) {
            rebaseRateBPS = 15; // ~0.15% for 500% APY
        } else if (currentAPY >= 1000) {
            rebaseRateBPS = 9;  // ~0.09% for 100% APY
        } else {
            // For very low APYs, linear approximation is close enough
            rebaseRateBPS = currentAPY / 1095;
        }

        // Convert to 1e18 precision
        return (rebaseRateBPS * 1e18) / 10000;
    }

    /**
     * @notice Calculate dynamic APY based on backing ratio
     * @dev Implements exponential response curve:
     *      - High backing (>150%) → Aggressive APY to attract capital
     *      - 100-90% backing → Gradual slowdown (still attractive)
     *      - <90% backing → Fast drop to slow emissions
     *      - <70% backing → Emergency mode
     * @param _backingRatio Backing ratio in basis points (10000 = 100%)
     * @return APY in basis points (10000 = 100%)
     */
    function calculateDynamicAPY(uint256 _backingRatio) public pure returns (uint256) {
        if (_backingRatio >= 20000) {
            // >200% backing: MAXIMUM AGGRESSION
            // 30,000% APY - go absolutely crazy
            return 3000000;

        } else if (_backingRatio >= 15000) {
            // 150-200% backing: Very aggressive
            // Scale from 12,000% to 30,000%
            // Formula: 12000 + (backing - 150) × 360
            uint256 excess = _backingRatio - 15000;
            return 1200000 + (excess * 360 / 100);

        } else if (_backingRatio >= 12000) {
            // 120-150% backing: Aggressive
            // Scale from 8,000% to 12,000%
            uint256 excess = _backingRatio - 12000;
            return 800000 + (excess * 133 / 100);

        } else if (_backingRatio >= 10000) {
            // 100-120% backing: Still attractive
            // Scale from 5,000% to 8,000%
            uint256 excess = _backingRatio - 10000;
            return 500000 + (excess * 150 / 100);

        } else if (_backingRatio >= 9000) {
            // 90-100% backing: GRADUAL DROP (still attractive for buying)
            // Drop from 5,000% to 3,500%
            // Still high enough to attract new capital
            uint256 deficit = 10000 - _backingRatio;
            return 500000 - (deficit * 150 / 100); // 15% drop per 1% backing

        } else if (_backingRatio >= 8000) {
            // 80-90% backing: Moderate slowdown
            // Drop from 3,500% to 2,500%
            uint256 deficit = 9000 - _backingRatio;
            return 350000 - (deficit * 100 / 100);

        } else if (_backingRatio >= 7000) {
            // 70-80% backing: Stronger slowdown
            // Drop from 2,500% to 2,000%
            // THIS is the "knife catch"
            uint256 deficit = 8000 - _backingRatio;
            return 250000 - (deficit * 50 / 100);

        } else {
            // <70% backing: EMERGENCY STOP
            // Minimal emissions to prevent total collapse
            // Scale down to 0% at 50% backing
            if (_backingRatio <= 5000) return 0;

            uint256 deficit = 7000 - _backingRatio;
            uint256 apy = 200000 - (deficit * 10 / 100);
            return apy > 0 ? apy : 0;
        }
    }

    /**
     * @notice Update backing ratio (only treasury)
     * @param newRatio New backing ratio in basis points
     */
    function updateBackingRatio(uint256 newRatio) external override {
        require(msg.sender == treasury, "Only treasury");

        uint256 oldRatio = backingRatio;
        backingRatio = newRatio;

        emit BackingRatioUpdated(oldRatio, newRatio);
    }

    // ============ View Functions ============

    function nextRebaseTime() external view override returns (uint256) {
        return lastRebaseTime + REBASE_FREQUENCY;
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return _gonBalances[account] / _gonsPerFragment;
    }

    function transfer(address to, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[msg.sender] -= gonAmount;
        _gonBalances[to] += gonAmount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override(ERC20, IERC20)
        returns (uint256)
    {
        return _allowedFragments[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        _allowedFragments[from][msg.sender] -= amount;

        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[from] -= gonAmount;
        _gonBalances[to] += gonAmount;

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override(ERC20, IERC20)
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}
