// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {DAO} from "./DAO.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract DAOTreasury is Ownable {
    using SafeERC20 for IERC20;
    // DAO contract reference
    DAO public dao;

    //Mapping to track approved spending proposals
    mapping(uint256 => bool) public approvedProposals;

    //Mapping to track executed spending proposals
    mapping(uint256 => bool) public executedProposals;

    // Events
    event ProposalApproved(uint256 indexed proposalId);
    event FundsSpend(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event DAOSet(address indexed dao);
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed recipient);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _dao) Ownable(msg.sender) {
        dao = DAO(_dao);
    }

    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
    }

    function setDao(address _dao) external onlyOwner {
        require(_dao != address(0), "Invalid DAO address");
        dao = DAO(_dao);
        emit DAOSet(_dao);
    }

    function approveProposal(uint256 proposalId) external {
        require(msg.sender == address(dao), "Only DAO can approve proposals");
        require(!approvedProposals[proposalId], "Proposal already approved");
        approvedProposals[proposalId] = true;
        emit ProposalApproved(proposalId);
    }

    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external {
        require(msg.sender == address(dao), "Only DAO can execute proposals");
        require(approvedProposals[proposalId], "Proposal not approved");
        require(!executedProposals[proposalId], "Proposal already executed");
        require(amount > 0, "Amount must be greater than zero");
        require(recipient != address(0), "Invalid recipient address");
        executedProposals[proposalId] = true;
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient balance");
            (bool success,) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient balance");
            tokenContract.safeTransfer(recipient, amount);
        }
        emit ProposalExecuted(proposalId);
    }

    function fundTreasury() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function fundTreasuryWithToken(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(token != address(0), "Invalid token address");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient balance");

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit TreasuryFunded(msg.sender, amount);
    }

    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function emergencyWithdraw(address token, uint256 amount, address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");

        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient balance");
            (bool success,) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.balanceOf(address(this)) >= amount, "Insufficient balance");
            require(tokenContract.transfer(recipient, amount), "Token transfer failed");
        }

        require(IERC20(token).transfer(recipient, amount), "Transfer failed");
        emit EmergencyWithdraw(token, amount, recipient);
    }
}
