// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IECHO
 * @notice Interface for the ECHO token contract
 */
interface IECHO is IERC20 {
    /**
     * @notice Emitted when staking ratio is updated
     * @param oldRatio Previous staking ratio
     * @param newRatio New staking ratio
     */
    event StakingRatioUpdated(uint256 oldRatio, uint256 newRatio);

    /**
     * @notice Emitted when whitelist status changes
     * @param account The account whose status changed
     * @param status New whitelist status
     */
    event WhitelistUpdated(address indexed account, bool status);

    /**
     * @notice Emitted when tokens are burned
     * @param from Address from which tokens were burned
     * @param amount Amount of tokens burned
     */
    event Burned(address indexed from, uint256 amount);

    /**
     * @notice Update the current staking ratio (only callable by staking contract)
     * @param newRatio New staking ratio in basis points (8800 = 88%)
     */
    function updateStakingRatio(uint256 newRatio) external;

    /**
     * @notice Set whitelist status for an address (DEXs, bridges, etc.)
     * @param account Address to update
     * @param status New whitelist status
     */
    function setWhitelist(address account, bool status) external;

    /**
     * @notice Mint new tokens (only callable by authorized minters)
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burn tokens
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Get current tax rate based on staking ratio
     * @return Current tax rate in basis points
     */
    function getCurrentTaxRate() external view returns (uint256);

    /**
     * @notice Get total amount of tokens burned
     * @return Total burned
     */
    function totalBurned() external view returns (uint256);

    /**
     * @notice Check if address is whitelisted
     * @param account Address to check
     * @return True if whitelisted
     */
    function isWhitelisted(address account) external view returns (bool);
}
