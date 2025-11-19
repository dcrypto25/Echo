// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ITreasury.sol";

/**
 * @title InsuranceVault
 * @notice Emergency backup fund activated when backing < 50%
 * @dev Separate vault that can only be tapped by DAO vote in emergencies
 */
contract InsuranceVault is Ownable, ReentrancyGuard {
    ITreasury public immutable treasury;

    uint256 public totalDeposits;
    uint256 public constant ACTIVATION_THRESHOLD = 5000; // 50% backing

    mapping(address => uint256) public deposits;

    event Deposited(address indexed from, uint256 amount);
    event EmergencyDeployed(uint256 amount, string reason);

    constructor(address _treasury) Ownable(msg.sender) {
        treasury = ITreasury(_treasury);
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function emergencyDeploy(uint256 amount, string calldata reason)
        external
        onlyOwner
        nonReentrant
    {
        require(treasury.getBackingRatio() < ACTIVATION_THRESHOLD, "Not emergency");
        require(address(this).balance >= amount, "Insufficient funds");

        (bool success, ) = address(treasury).call{value: amount}("");
        require(success, "Transfer failed");

        emit EmergencyDeployed(amount, reason);
    }

    receive() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
