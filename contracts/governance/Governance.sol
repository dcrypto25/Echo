// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStaking.sol";

/**
 * @title Governance
 * @notice DAO governance with voting based on staked ECHO
 * @dev Voting power = stakedAmount × lockTimeRemaining
 * @dev Simple governance implementation - would use OpenZeppelin Governor in production
 */
contract Governance is Ownable {
    IStaking public immutable staking;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant EXECUTION_DELAY = 2 days;
    uint256 public constant QUORUM = 1000; // 10%

    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _staking) Ownable(msg.sender) {
        staking = IStaking(_staking);
    }

    function propose(string calldata description) external returns (uint256) {
        uint256 proposalId = ++proposalCount;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        // Voting power = staked amount (simple model)
        // In future: could multiply by lock time remaining for more power
        uint256 weight = staking.getStakedBalance(msg.sender);
        require(weight > 0, "No stake");

        if (support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    function execute(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime + EXECUTION_DELAY, "Timelock active");
        require(!proposal.executed, "Already executed");
        require(proposal.forVotes > proposal.againstVotes, "Not passed");

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }
}
