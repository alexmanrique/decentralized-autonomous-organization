// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DAO} from "../src/DAO.sol";
import {DAOGoveranceToken} from "../src/DAOGoveranceToken.sol";
import {DAOTreasury} from "../src/DAOTreasury.sol";

contract DAOTest is Test {
    DAO public dao;
    DAOGoveranceToken public governanceToken;
    DAOTreasury public treasury;

    uint256 public proposalThreshold;
    address aRecipient;
    address aToken;
    uint256 amountInput;
    string aDescription;

    function setUp() public {
        aRecipient = makeAddr("recipient");
        aToken = makeAddr("token");
        amountInput = 1000000000000000000000000;
        aDescription = "Test Proposal";
        governanceToken = new DAOGoveranceToken("Governance Token", "GOV", 1000000000000000000000000);
        treasury = new DAOTreasury(address(dao));
        proposalThreshold = 1000000000000000000000000;
        dao = new DAO(
            address(governanceToken),
            address(treasury),
            proposalThreshold,
            1000000000000000000000000,
            1000000000000000000000000
        );
    }

    function testCreateProposal() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        (
            address proposer,
            string memory description,,,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool canceled,
            address recipient,
            uint256 amount,
            address token
        ) = dao.getProposal(0);

        assertEq(dao.proposalCount(), 1);
        assertEq(proposer, address(this));
        assertEq(description, aDescription);
        assertEq(recipient, aRecipient);
        assertEq(amount, amountInput);
        assertEq(token, aToken);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 1000000000000000000000000);
        assertEq(executed, false);
        assertEq(canceled, false);
    }

    function testCreateProposal_InsufficientVotingPower() public {
        vm.expectRevert("Insufficient voting power");
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
    }

    function testCreateProposal_InvalidRecipient() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        vm.expectRevert("Invalid recipient address");
        dao.createProposal(aDescription, address(0), amountInput, aToken);
    }

    function testVote() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        (bool hasVoted, bool votedFor) = dao.getVoteInfo(0, address(this));
        assertEq(hasVoted, true);
        assertEq(votedFor, true);
    }

    function testVote_InvalidProposal() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        vm.expectRevert("Proposal not found");
        dao.vote(0, true);
    }

    function testVote_AlreadyVoted() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        vm.expectRevert("Already voted");
        dao.vote(0, true);
    }

}
