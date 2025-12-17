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
- **Delegation**: Token holders can delegate their voting power to other addresses
- **Undelegation**: Delegators can reclaim their delegated voting power

**Key Functions:**
- `mint(address to, uint256 amount)`: Mint new tokens (owner only)
- `burn(uint256 amount)`: Burn tokens from sender's balance
- `delegateVotingPower(address delegate, uint256 amount)`: Delegate voting power to another address
- `undelegateVotingPower(uint256 amount)`: Reclaim delegated voting power
- `getVotingPower(address account)`: Get the voting power of an address

### DAOTreasury.sol

A secure treasury contract that holds and manages funds (both ETH and ERC20 tokens) for the DAO. It includes:

- **Fund Management**: Accept deposits of ETH and ERC20 tokens
- **Proposal Execution**: Execute approved spending proposals from the DAO
- **Security**: Only the DAO contract can approve and execute proposals
- **Emergency Controls**: Owner can perform emergency withdrawals if needed

**Key Functions:**
- `deposit()`: Deposit ETH to the treasury
- `fundTreasury()`: Public function to fund treasury with ETH
- `fundTreasuryWithToken(address token, uint256 amount)`: Fund treasury with ERC20 tokens
- `approveProposal(uint256 proposalId)`: Approve a proposal (DAO only)
- `spendFunds(uint256 proposalId, address recipient, uint256 amount, address token)`: Execute approved proposal spending
- `emergencyWithdraw(address token, uint256 amount, address recipient)`: Emergency withdrawal (owner only)

### DAO.sol

The main governance contract that orchestrates the entire DAO system. It handles:

- **Proposal Creation**: Token holders with sufficient voting power can create proposals
- **Voting**: Token holders vote on proposals with their voting power
- **Proposal Execution**: Successful proposals are executed through the treasury
- **Configuration**: Configurable thresholds, voting periods, and quorum requirements

**Key Functions:**
- `createProposal(string description, address recipient, uint256 amount, address token)`: Create a new spending proposal
- `vote(uint256 proposalId, bool support)`: Vote for or against a proposal
- `executeProposal(uint256 proposalId)`: Execute a successful proposal
- `cancelProposal(uint256 proposalId)`: Cancel a proposal (proposer or owner only)
- `setGovernanceToken(address _governanceToken)`: Update governance token address (owner only)
- `setTreasury(address _treasury)`: Update treasury address (owner only)

**Proposal Requirements:**
- Minimum voting power threshold to create proposals
- Configurable voting period
- Quorum requirement (minimum votes needed)
- Majority vote required for approval

## Features

- ✅ Token-based governance with delegation
- ✅ Secure treasury management
- ✅ Proposal creation and voting system
- ✅ Quorum and threshold enforcement
- ✅ Support for both ETH and ERC20 token spending
- ✅ Emergency controls for treasury management
- ✅ Built with OpenZeppelin contracts for security

## Technology Stack

- **Solidity**: ^0.8.30
- **Foundry**: Ethereum development framework
- **OpenZeppelin Contracts**: v5.5.0 (security-audited smart contract library)

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

## Architecture

```
┌─────────────────────┐
│  DAOGoveranceToken  │
│   (ERC20 Token)     │
└──────────┬──────────┘
           │
           │ Voting Power
           │
┌──────────▼──────────┐
│       DAO           │
│  (Governance Core)  │
└──────────┬──────────┘
           │
           │ Approves & Executes
           │
┌──────────▼──────────┐
│   DAOTreasury       │
│   (Fund Manager)    │
└─────────────────────┘
```

## Development

### Project Structure

```
dao/
├── src/
│   ├── DAOGoveranceToken.sol    # Governance token contract
│   ├── DAOTreasury.sol           # Treasury contract
│   └── DAO.sol                   # Main DAO contract
├── test/                         # Test files
├── script/                       # Deployment scripts
├── lib/                          # Dependencies
│   └── openzeppelin-contracts/   # OpenZeppelin contracts
└── foundry.toml                  # Foundry configuration
```

## Security Considerations

- This project uses OpenZeppelin's audited contracts
- All external calls use SafeERC20 for token transfers
- Access control is enforced through Ownable and custom modifiers
- Treasury operations are restricted to approved DAO proposals
- Emergency withdrawal functions are available for owner

## License

MIT

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## Help

For more information on Foundry commands:

```shell
forge --help
anvil --help
cast --help
```
