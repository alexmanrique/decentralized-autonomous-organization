// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DAOGoveranceToken} from "./DAOGoveranceToken.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IDAOTreasury {
    function approveProposal(uint256 proposalId) external;
    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external;
}

contract DAO is Ownable {
    DAOGoveranceToken public governanceToken;

    IDAOTreasury public treasury;

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
        address recipient;
        uint256 amount;
        address token;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 proposalThreshold;
    uint256 votingPeriod;
    uint256 quorumVotes;

    event ProposalCreated(
        uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime
    );
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event ConfigurationUpdated(uint256 proposalThreshold, uint256 votingPeriod, uint256 quorumVotes);

    /**
     * @dev Constructor
     * @param _governanceToken The address of the governance token
     * @param _proposalThreshold The minimum number of tokens required to create a proposal
     * @param _votingPeriod The duration of the voting period in seconds
     * @param _quorumVotes The minimum votes required for proposal to pass
     */
    constructor(
        address _governanceToken,
        address _treasury,
        uint256 _proposalThreshold,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) Ownable(msg.sender) {
        governanceToken = DAOGoveranceToken(_governanceToken);
        treasury = IDAOTreasury(_treasury);
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }

    function createProposal(string memory description, address recipient, uint256 amount, address token) external {
        require(governanceToken.getVotingPower(msg.sender) >= proposalThreshold, "Insufficient voting power");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");

        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.recipient = recipient;
        proposal.amount = amount;
        proposal.token = token;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.canceled = false;

        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp, block.timestamp + votingPeriod);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal not found");
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp < proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.canceled, "Proposal is canceled");
        require(!proposal.executed, "Proposal is executed");

        uint256 votes = governanceToken.getVotingPower(msg.sender);
        require(votes > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        proposal.votedFor[msg.sender] = support;

        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit Voted(proposalId, msg.sender, support, votes);
    }

    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "Proposal not found");
        require(proposal.proposer == msg.sender || msg.sender == owner(), "Only proposer or owner can cancel proposal");
        require(block.timestamp < proposal.startTime, "Voting has started");
        require(!proposal.executed, "Proposal is executed");
        require(!proposal.canceled, "Proposal is canceled");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal not found");
        require(block.timestamp >= proposal.endTime, "Voting has not ended");
        require(!proposal.executed, "Proposal is executed");
        require(!proposal.canceled, "Proposal is canceled");
        require(proposal.forVotes + proposal.againstVotes >= quorumVotes, "Quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "Proposal is not approved");

        proposal.executed = true;

        treasury.approveProposal(proposalId);

        treasury.spendFunds(proposalId, proposal.recipient, proposal.amount, proposal.token);

        emit ProposalExecuted(proposalId);
    }

    function setGovernanceToken(address _governanceToken) external onlyOwner {
        governanceToken = DAOGoveranceToken(_governanceToken);
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     * @return proposer Address of the proposer
     * @return description Description of the proposal
     * @return forVotes Number of votes for the proposal
     * @return againstVotes Number of votes against the proposal
     * @return startTime Start time of voting
     * @return endTime End time of voting
     * @return executed Whether the proposal has been executed
     * @return canceled Whether the proposal has been canceled
     * @return recipient Address to receive funds
     * @return amount Amount of funds to be spent
     * @return token Token address for the proposal
     */
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool canceled,
            address recipient,
            uint256 amount,
            address token
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled,
            proposal.recipient,
            proposal.amount,
            proposal.token
        );
    }

    /**
     * @dev Check if an address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     * @return hasVoted Whether the address has voted
     * @return votedFor Whether the address voted for the proposal (only meaningful if hasVoted is true)
     */
    function getVoteInfo(uint256 proposalId, address voter) external view returns (bool hasVoted, bool votedFor) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.hasVoted[voter], proposal.votedFor[voter]);
    }

    /**
     * @dev Update DAO configuration (only owner)
     * @param _proposalThreshold New proposal threshold
     * @param _votingPeriod New voting period
     * @param _quorumVotes New quorum votes
     */
    function updateConfiguration(uint256 _proposalThreshold, uint256 _votingPeriod, uint256 _quorumVotes)
        external
        onlyOwner
    {
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;

        emit ConfigurationUpdated(_proposalThreshold, _votingPeriod, _quorumVotes);
    }

    /**
     * @dev Set the treasury contract address (only owner)
     * @param _treasury New treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = IDAOTreasury(_treasury);
    }

    /**
     * @dev Check if a proposal has passed
     * @param proposalId ID of the proposal
     * @return passed Whether the proposal has passed
     */
    function proposalPassed(uint256 proposalId) external view returns (bool passed) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.proposer == address(0) || proposal.canceled || proposal.executed) {
            return false;
        }

        if (block.timestamp < proposal.endTime) {
            return false; // Voting not ended
        }

        if (proposal.forVotes + proposal.againstVotes < quorumVotes) {
            return false; // Quorum not reached
        }

        return proposal.forVotes > proposal.againstVotes;
    }
}
