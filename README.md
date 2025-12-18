# DAO Governance System

A decentralized autonomous organization (DAO) system built with Solidity and Foundry. This project implements a complete governance framework with token-based voting, proposal management, and treasury control.

## Overview

This DAO system consists of three main smart contracts that work together to enable decentralized governance:

- **DAOGoveranceToken**: ERC20 governance token with delegation capabilities
- **DAOTreasury**: Secure treasury contract for managing funds and executing approved proposals
- **DAO**: Main governance contract handling proposals, voting, and execution

## Contracts

### DAOGoveranceToken.sol

An ERC20 token contract that serves as the governance token for the DAO. It includes:

- **Token Management**: Standard ERC20 functionality with minting and burning
- **Voting Power**: Each token holder's balance represents their voting power
- **Delegation**: Token holders can delegate their voting power to other addresses by transferring tokens
- **Undelegation**: Delegators can reclaim their delegated voting power

**Key Functions:**
- `mint(address to, uint256 amount)`: Mint new tokens (owner only)
- `burn(uint256 amount)`: Burn tokens from sender's balance
- `delegateVotingPower(address delegate, uint256 amount)`: Delegate voting power to another address by transferring tokens
- `undelegateVotingPower(uint256 amount)`: Reclaim delegated voting power
- `getVotingPower(address account)`: Get the voting power of an address (returns balance)

**Events:**
- `VotingPowerDelegated(address indexed delegator, address indexed delegate, uint256 amount)`
- `VotingPowerUndelegated(address indexed delegator, address indexed delegate, uint256 amount)`

### DAOTreasury.sol

A secure treasury contract that holds and manages funds (both ETH and ERC20 tokens) for the DAO. It includes:

- **Fund Management**: Accept deposits of ETH and ERC20 tokens
- **Proposal Execution**: Execute approved spending proposals from the DAO
- **Security**: Only the DAO contract can approve and execute proposals
- **Emergency Controls**: Owner can perform emergency withdrawals if needed

**Key Functions:**
- `deposit()`: Deposit ETH to the treasury
- `fundTreasury()`: Public function to fund treasury with ETH (payable)
- `fundTreasuryWithToken(address token, uint256 amount)`: Fund treasury with ERC20 tokens
- `approveProposal(uint256 proposalId)`: Approve a proposal (DAO only)
- `spendFunds(uint256 proposalId, address recipient, uint256 amount, address token)`: Execute approved proposal spending
- `emergencyWithdraw(address token, uint256 amount, address recipient)`: Emergency withdrawal (owner only)
- `setDao(address _dao)`: Set the DAO contract address (owner only)

**Events:**
- `ProposalApproved(uint256 indexed proposalId)`
- `FundsSpend(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token)`
- `TreasuryFunded(address indexed sender, uint256 amount)`
- `DAOSet(address indexed dao)`
- `EmergencyWithdraw(address indexed token, uint256 amount, address indexed recipient)`
- `ProposalExecuted(uint256 indexed proposalId)`

**Note:** The treasury supports both ETH (address(0)) and ERC20 tokens for spending proposals.

### DAO.sol

The main governance contract that orchestrates the entire DAO system. It handles:

- **Proposal Creation**: Token holders with sufficient voting power can create proposals
- **Voting**: Token holders vote on proposals with their voting power
- **Proposal Execution**: Successful proposals are executed through the treasury
- **Configuration**: Configurable thresholds, voting periods, and quorum requirements
- **Proposal Management**: Cancel proposals, check proposal status, and view proposal details

**Key Functions:**

**Proposal Management:**
- `createProposal(string description, address recipient, uint256 amount, address token)`: Create a new spending proposal
  - Requires: Voting power >= proposal threshold, non-empty description, valid recipient, amount > 0
- `vote(uint256 proposalId, bool support)`: Vote for or against a proposal
  - Requires: Proposal exists, voting period active, not already voted, proposal not canceled/executed
- `executeProposal(uint256 proposalId)`: Execute a successful proposal
  - Requires: Voting ended, quorum reached, majority vote, proposal not executed/canceled
- `cancelProposal(uint256 proposalId)`: Cancel a proposal (proposer or owner only, before voting starts)

**View Functions:**
- `getProposal(uint256 proposalId)`: Get complete proposal details
- `getVoteInfo(uint256 proposalId, address voter)`: Check if an address has voted and their vote direction
- `proposalPassed(uint256 proposalId)`: Check if a proposal has passed (view function)
- `isCanceled(uint256 proposalId)`: Check if a proposal is canceled
- `isExecuted(uint256 proposalId)`: Check if a proposal is executed
- `getProposalThreshold()`: Get the minimum tokens required to create a proposal
- `getVotingPeriod()`: Get the voting period duration in seconds
- `getQuorumVotes()`: Get the minimum votes required for proposal to pass

**Configuration (Owner Only):**
- `updateConfiguration(uint256 _proposalThreshold, uint256 _votingPeriod, uint256 _quorumVotes)`: Update DAO configuration parameters
- `setGovernanceToken(address _governanceToken)`: Update governance token address
- `setTreasury(address _treasury)`: Update treasury address

**Proposal Requirements:**
- **Proposal Threshold**: Minimum voting power required to create a proposal
- **Voting Period**: Duration of the voting period in seconds (configurable)
- **Quorum**: Minimum total votes (for + against) required for proposal to pass
- **Majority**: More votes "for" than "against" required for approval

**Events:**
- `ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime)`
- `Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes)`
- `ProposalExecuted(uint256 indexed proposalId)`
- `ProposalCanceled(uint256 indexed proposalId)`
- `ConfigurationUpdated(uint256 proposalThreshold, uint256 votingPeriod, uint256 quorumVotes)`

## Features

- ✅ Token-based governance with delegation
- ✅ Secure treasury management
- ✅ Proposal creation and voting system
- ✅ Quorum and threshold enforcement
- ✅ Support for both ETH and ERC20 token spending
- ✅ Emergency controls for treasury management
- ✅ Encapsulation: Private state variables with explicit getter functions
- ✅ Comprehensive proposal status checking
- ✅ Built with OpenZeppelin contracts for security
- ✅ Full test coverage

## Technology Stack

- **Solidity**: ^0.8.30
- **Foundry**: Ethereum development framework
- **OpenZeppelin Contracts**: v5.5.0 (security-audited smart contract library)

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd decentralized-autonomous-organization

# Install dependencies (Foundry will automatically install from foundry.toml)
forge install

# Build the project
forge build

# Run tests
forge test
```

## Architecture

```
┌─────────────────────┐
│  DAOGoveranceToken  │
│   (ERC20 Token)     │
│                     │
│  - Mint/Burn        │
│  - Delegation       │
│  - Voting Power     │
└──────────┬──────────┘
           │
           │ Voting Power
           │ (balanceOf)
           │
┌──────────▼──────────┐
│       DAO           │
│  (Governance Core)  │
│                     │
│  - Proposals        │
│  - Voting           │
│  - Execution        │
│  - Configuration    │
└──────────┬──────────┘
           │
           │ Approves & Executes
           │
┌──────────▼──────────┐
│   DAOTreasury       │
│   (Fund Manager)    │
│                     │
│  - ETH/ERC20        │
│  - Spending         │
│  - Emergency        │
└─────────────────────┘
```

## Usage Example

### 1. Deploy Contracts

```solidity
// Deploy governance token
DAOGoveranceToken token = new DAOGoveranceToken("Governance Token", "GOV", 1000000 * 10**18);

// Deploy treasury (initially with temporary owner)
DAOTreasury treasury = new DAOTreasury(address(owner));

// Deploy DAO
uint256 proposalThreshold = 1000 * 10**18;
uint256 votingPeriod = 7 days;
uint256 quorumVotes = 100 * 10**18;
DAO dao = new DAO(address(token), address(treasury), proposalThreshold, votingPeriod, quorumVotes);

// Link treasury to DAO
treasury.setDao(address(dao));
```

### 2. Create a Proposal

```solidity
// User must have voting power >= proposalThreshold
token.mint(user, proposalThreshold);
dao.createProposal(
    "Fund development team",
    developerAddress,
    50000 * 10**18,
    address(token)
);
```

### 3. Vote on Proposal

```solidity
// Token holders vote with their voting power
dao.vote(proposalId, true);  // Vote for
dao.vote(proposalId, false); // Vote against
```

### 4. Execute Proposal

```solidity
// After voting period ends and proposal passes
dao.executeProposal(proposalId);
// Treasury automatically transfers funds to recipient
```

### 5. Check Proposal Status

```solidity
// Get full proposal details
(address proposer, string memory description, uint256 forVotes, ...) = dao.getProposal(proposalId);

// Check if proposal passed
bool passed = dao.proposalPassed(proposalId);

// Check vote info
(bool hasVoted, bool votedFor) = dao.getVoteInfo(proposalId, voterAddress);
```

## Development

### Project Structure

```
decentralized-autonomous-organization/
├── src/
│   ├── DAOGoveranceToken.sol    # Governance token contract
│   ├── DAOTreasury.sol           # Treasury contract
│   └── DAO.sol                   # Main DAO contract
├── test/
│   └── DAO.t.sol                 # Comprehensive test suite
├── lib/                          # Dependencies
│   ├── forge-std/                # Foundry standard library
│   └── openzeppelin-contracts/   # OpenZeppelin contracts
├── foundry.toml                  # Foundry configuration
└── README.md                     # This file
```

### Running Tests

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testCreateProposal

# Run with verbose output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

### Test Coverage

The test suite includes comprehensive coverage for:

- ✅ Proposal creation (success and failure cases)
- ✅ Voting (success and failure cases)
- ✅ Proposal execution
- ✅ Proposal cancellation
- ✅ Configuration updates
- ✅ Treasury operations
- ✅ Edge cases and error handling

#### Coverage Report

Current test coverage statistics:

```
╭---------------------------+------------------+------------------+-----------------+----------------╮
| File                      | % Lines          | % Statements     | % Branches      | % Funcs        |
+====================================================================================================+
| src/DAO.sol               | 93.68% (89/95)   | 94.05% (79/84)   | 75.51% (37/49)  | 93.75% (15/16) |
|---------------------------+------------------+------------------+-----------------+----------------|
| src/DAOGoveranceToken.sol | 100.00% (26/26)  | 100.00% (22/22)  | 53.33% (8/15)   | 100.00% (5/5)  |
|---------------------------+------------------+------------------+-----------------+----------------|
| src/DAOTreasury.sol       | 96.00% (48/50)   | 97.78% (44/45)   | 54.17% (26/48)  | 88.89% (8/9)   |
|---------------------------+------------------+------------------+-----------------+----------------|
| Total                     | 95.32% (163/171) | 96.03% (145/151) | 63.39% (71/112) | 93.33% (28/30) |
╰---------------------------+------------------+------------------+-----------------+----------------╯
```

To generate the coverage report, run:
```bash
forge coverage
```

## Security Considerations

- **OpenZeppelin Contracts**: This project uses OpenZeppelin's audited contracts for security
- **Access Control**: All external calls use proper access control (Ownable, custom modifiers)
- **SafeERC20**: Token transfers use SafeERC20 for safe token operations
- **Treasury Security**: Treasury operations are restricted to approved DAO proposals only
- **Emergency Controls**: Emergency withdrawal functions are available for owner (use with caution)
- **Encapsulation**: State variables are private with explicit getter functions for better control
- **Input Validation**: All functions include proper input validation and require statements
- **Reentrancy**: Safe patterns used throughout (checks-effects-interactions)

## Configuration Parameters

The DAO can be configured with the following parameters:

- **Proposal Threshold**: Minimum voting power required to create a proposal
- **Voting Period**: Duration of voting period in seconds (e.g., 7 days = 604800)
- **Quorum Votes**: Minimum total votes required for a proposal to pass

These can be updated by the owner using `updateConfiguration()`.

## License

MIT

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Help

For more information on Foundry commands:

```shell
forge --help
anvil --help
cast --help
```

## Contributing

When contributing to this project, please ensure:

1. All tests pass: `forge test`
2. Code follows Solidity style guide
3. Add tests for new functionality
4. Update documentation as needed
