// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IeECHO
 * @notice Interface for the eECHO rebasing token contract
 */
interface IeECHO is IERC20 {
    /**
     * @notice Emitted when a rebase occurs
     * @param epoch Current rebase number
     * @param totalSupply New total supply after rebase
     */
    event Rebase(uint256 indexed epoch, uint256 totalSupply);

    /**
     * @notice Emitted when backing ratio is updated
     * @param oldRatio Previous backing ratio
     * @param newRatio New backing ratio
     */
    event BackingRatioUpdated(uint256 oldRatio, uint256 newRatio);

    /**
     * @notice Wrap ECHO tokens to receive eECHO
     * @param echoAmount Amount of ECHO to wrap
     * @return eEchoAmount Amount of eECHO minted
     */
    function wrap(uint256 echoAmount) external returns (uint256 eEchoAmount);

    /**
     * @notice Unwrap eECHO tokens to receive ECHO
     * @param eEchoAmount Amount of eECHO to unwrap
     * @return echoAmount Amount of ECHO returned
     */
    function unwrap(uint256 eEchoAmount) external returns (uint256 echoAmount);

    /**
     * @notice Trigger a rebase (callable by anyone, but only succeeds if time elapsed)
     * @return New total supply
     */
    function rebase() external returns (uint256);

    /**
     * @notice Update backing ratio (only callable by treasury)
     * @param newRatio New backing ratio in basis points
     */
    function updateBackingRatio(uint256 newRatio) external;

    /**
     * @notice Get current rebase rate based on backing
     * @return Rebase rate in 1e18 precision
     */
    function getCurrentRebaseRate() external view returns (uint256);

    /**
     * @notice Get next rebase time
     * @return Timestamp of next rebase
     */
    function nextRebaseTime() external view returns (uint256);

    /**
     * @notice Get current backing ratio
     * @return Backing ratio in basis points
     */
    function backingRatio() external view returns (uint256);

    /**
     * @notice Get current epoch number
     * @return Current epoch
     */
    function epoch() external view returns (uint256);
}
