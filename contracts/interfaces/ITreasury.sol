// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITreasury
 * @notice Interface for the Treasury (Forge Reserve) contract
 */
interface ITreasury {
    /**
     * @notice Emitted when assets are deposited
     * @param token Token address (or zero for ETH)
     * @param amount Amount deposited
     */
    event Deposited(address indexed token, uint256 amount);

    /**
     * @notice Emitted when backing ratio is updated
     * @param oldRatio Previous backing ratio
     * @param newRatio New backing ratio
     */
    event BackingRatioUpdated(uint256 oldRatio, uint256 newRatio);

    /**
     * @notice Emitted when buyback is executed
     * @param amount Amount of ECHO bought and burned
     * @param cost Cost in treasury assets
     */
    event BuybackExecuted(uint256 amount, uint256 cost);

    /**
     * @notice Deposit assets to treasury
     * @param token Token address (zero address for ETH)
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external payable;

    /**
     * @notice Execute buyback when price is below floor
     * @param maxAmount Maximum amount of treasury to spend
     * @return echoAmount Amount of ECHO bought and burned
     */
    function executeBuyback(uint256 maxAmount) external returns (uint256 echoAmount);

    /**
     * @notice Deploy funds to yield strategy
     * @param strategy Address of yield strategy
     * @param amount Amount to deploy
     */
    function deployToYield(address strategy, uint256 amount) external;

    /**
     * @notice Withdraw from yield strategy
     * @param strategy Address of yield strategy
     * @param amount Amount to withdraw
     */
    function withdrawFromYield(address strategy, uint256 amount) external;

    /**
     * @notice Get current backing ratio
     * @return Backing ratio in basis points (10000 = 100%)
     */
    function getBackingRatio() external view returns (uint256);

    /**
     * @notice Get total treasury value in USD
     * @return Total value
     */
    function getTotalValue() external view returns (uint256);

    /**
     * @notice Get liquid assets value
     * @return Liquid assets value
     */
    function getLiquidValue() external view returns (uint256);

    /**
     * @notice Get yield-earning assets value
     * @return Yield assets value
     */
    function getYieldValue() external view returns (uint256);

    /**
     * @notice Calculate runway in days
     * @return Days of runway at current APY
     */
    function getRunway() external view returns (uint256);

    /**
     * @notice Check if buyback should be triggered
     * @return True if buyback conditions are met
     */
    function shouldExecuteBuyback() external view returns (bool);
}
