// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DAO} from "../src/DAO.sol";
import {DAOGoveranceToken} from "../src/DAOGoveranceToken.sol";
import {DAOTreasury} from "../src/DAOTreasury.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DAOTest is Test {
    DAO public dao;
    DAOGoveranceToken public governanceToken;
    DAOTreasury public treasury;
    ERC20Mock public mockToken;

    uint256 public proposalThreshold;
    address aRecipient;
    address aToken;
    uint256 amountInput;
    string aDescription;
    uint256 aVotingPeriod;
    uint256 aQuorumVotes;

    function setUp() public {
        aRecipient = makeAddr("recipient");
        amountInput = 1000000000000000000000000;
        aDescription = "Test Proposal";
        aVotingPeriod = 1000000000000000000000000;
        governanceToken = new DAOGoveranceToken("Governance Token", "GOV", 1000000000000000000000000);
        mockToken = new ERC20Mock();
        aToken = address(mockToken);
        proposalThreshold = 1000000000000000000000000;
        aQuorumVotes = 1;
        // Create treasury with address(0) first, will be updated after DAO creation
        treasury = new DAOTreasury(address(this));
        // Create DAO with treasury address
        dao = new DAO(address(governanceToken), address(treasury), proposalThreshold, aVotingPeriod, aQuorumVotes);
        // Update treasury to reference the actual DAO
        treasury.setDao(address(dao));
    }

    function testCreateProposal() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        (
            address proposer,
            string memory description,
            ,
            ,
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

    function testVote_ProposalNotFound() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        vm.expectRevert("Proposal not found");
        dao.vote(0, true);
    }

    function testVote_ProposalCanceled() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        dao.cancelProposal(0);
        vm.expectRevert("Proposal is canceled");
        vm.warp(currentTime + 1);
        dao.vote(0, true);
    }

    function testVote_VotingNotStarted() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        vm.expectRevert("Voting not started");
        dao.vote(0, true);
    }

    function testVote_VotingEnded() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime + aVotingPeriod + 1);
        vm.expectRevert("Voting ended");
        dao.vote(0, true);
    }

    function testVote_VotingHasNotStarted() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        vm.expectRevert("Voting not started");
        dao.vote(0, true);
    }

    function testCancelProposal_VotingHasStarted() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime + 1);
        vm.expectRevert("Voting has started");
        dao.cancelProposal(0);
    }

    function testCancelProposal_ProposalCanceled() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        dao.cancelProposal(0);
        vm.expectRevert("Proposal is canceled");
        dao.cancelProposal(0);
    }

    function testCancelProposal_ProposalNotFound() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        vm.expectRevert("Proposal not found");
        dao.cancelProposal(0);
    }

    function testCancelProposal_NotProposer() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        vm.expectRevert("Only proposer or owner can cancel proposal");
        vm.startPrank(makeAddr("not proposer"));
        dao.cancelProposal(0);
        vm.stopPrank();
    }

    function testCancelProposalSuccess() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        uint256 currentTime = block.timestamp;
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(currentTime - 1);
        dao.cancelProposal(0);
        
        // Opción más limpia: Usar función helper
        assertEq(dao.isCanceled(0), true);
        
        // Opción alternativa: Usar el mapping público directamente con desestructuración parcial
        // El mapping público devuelve 12 valores: (id, proposer, description, forVotes, againstVotes, startTime, endTime, executed, canceled, recipient, amount, token)
        // (, , , , , , , , bool canceled, , , ) = dao.proposals(0);
        // assertEq(canceled, true);
    }

    function testExecuteProposal() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        // Fund the treasury with the mock token
        mockToken.mint(address(treasury), amountInput);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        vm.warp(block.timestamp + aVotingPeriod + 1);
        dao.executeProposal(0);
        assertEq(dao.isExecuted(0), true);
        // Verify the token was transferred to the recipient
        assertEq(mockToken.balanceOf(aRecipient), amountInput);
        assertEq(mockToken.balanceOf(address(treasury)), 0);
    }

    function testExecuteProposal_proposalNotFound() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        vm.expectRevert("Proposal not found");
        dao.executeProposal(0);
    }

    function testExecuteProposal_votingNotEnded() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        vm.warp(block.timestamp + aVotingPeriod - 1);
        vm.expectRevert("Voting has not ended");
        dao.executeProposal(0);
    }

    function testExecuteProposal_proposalAlreadyExecuted() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        vm.warp(block.timestamp + aVotingPeriod + 1);
        mockToken.mint(address(treasury), amountInput);
        dao.executeProposal(0);
        vm.expectRevert("Proposal is executed");
        dao.executeProposal(0);
    }

    function testSetGovernanceToken() public {
        dao.setGovernanceToken(address(governanceToken));
        assertEq(address(dao.governanceToken()), address(governanceToken));
    }

    function testGetProposal() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        (address proposer, string memory description, uint256 forVotes, uint256 againstVotes, uint256 startTime, uint256 endTime, bool executed, bool canceled, address recipient, uint256 amount, address token) = dao.getProposal(0);
        assertEq(proposer, address(this));
        assertEq(description, aDescription);
        assertEq(recipient, aRecipient);
        assertEq(amount, amountInput);
        assertEq(token, aToken);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + aVotingPeriod);
        assertEq(executed, false);
        assertEq(canceled, false);
    }

    function testGetVoteInfo() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        (bool hasVoted, bool votedFor) = dao.getVoteInfo(0, address(this));
        assertEq(hasVoted, true);
        assertEq(votedFor, true);
    }

    function testUpdateConfiguration() public {
        dao.updateConfiguration(proposalThreshold, aVotingPeriod, aQuorumVotes);
        assertEq(dao.getProposalThreshold(), proposalThreshold);
        assertEq(dao.getVotingPeriod(), aVotingPeriod);
        assertEq(dao.getQuorumVotes(), aQuorumVotes);
    }

    function testProposal_Passed() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, true);
        vm.warp(block.timestamp + aVotingPeriod + 1);
        assertEq(dao.proposalPassed(0), true);
    }

    function testProposalNotPassed_VotingNotEnded() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, false);
        vm.warp(block.timestamp + aVotingPeriod + 1);
        assertEq(dao.proposalPassed(0), false);
    }

    function testProposalNotPassed_QuorumNotReached() public {
        governanceToken.mint(address(this), proposalThreshold + 1);
        dao.createProposal(aDescription, aRecipient, amountInput, aToken);
        dao.vote(0, false);
        vm.warp(block.timestamp + aVotingPeriod + 1);
        assertEq(dao.proposalPassed(0), false);
    }

}
