// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITreasury.sol";

/**
 * @title RedemptionQueue
 * @notice Queue system for unstaking during high sell pressure
 * @dev Queue length scales with backing ratio (0-10 days)
 */
contract RedemptionQueue is Ownable {
    ITreasury public immutable treasury;

    struct QueueEntry {
        address user;
        uint256 amount;
        uint256 queueTime;
        uint256 availableTime;
    }

    mapping(address => QueueEntry) public queue;

    event Queued(address indexed user, uint256 amount, uint256 availableTime);
    event Processed(address indexed user, uint256 amount);

    constructor(address _treasury) Ownable(msg.sender) {
        treasury = ITreasury(_treasury);
    }

    function calculateQueueDays() public view returns (uint256) {
        uint256 backing = treasury.getBackingRatio();

        // ≥120% backing: 0 days (no queue when healthy)
        if (backing >= 12000) return 0;

        // ≤70% backing: 10 days (maximum protection)
        if (backing <= 7000) return 10;

        // 70-120% backing: Linear scale from 0 to 10 days
        // Formula: 10 × (120% - β) / 50%
        // Simplified: (12000 - backing) / 500
        // Range: 12000 - 7000 = 5000 (50%)
        uint256 queueDays = (12000 - backing) / 500;

        return queueDays > 10 ? 10 : queueDays;
    }

    function addToQueue(address user, uint256 amount) external onlyOwner {
        uint256 queueDays = calculateQueueDays();

        queue[user] = QueueEntry({
            user: user,
            amount: amount,
            queueTime: block.timestamp,
            availableTime: block.timestamp + (queueDays * 1 days)
        });

        emit Queued(user, amount, queue[user].availableTime);
    }

    function isAvailable(address user) external view returns (bool) {
        return block.timestamp >= queue[user].availableTime;
    }
}
