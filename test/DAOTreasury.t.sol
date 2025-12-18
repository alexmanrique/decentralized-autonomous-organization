// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DAOTreasury} from "../src/DAOTreasury.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DAOTreasuryTest is Test {
    DAOTreasury public treasury;

    uint256 public constant DEPOSIT_AMOUNT = 1 ether; // 1 ETH

    function setUp() public {
        treasury = new DAOTreasury(address(this));
    }

    function testDeposit() public {
        treasury.deposit{value: DEPOSIT_AMOUNT}();
        assertEq(address(treasury).balance, DEPOSIT_AMOUNT);
    }

    function testSetDao() public {
        address dao = makeAddr("dao");
        treasury.setDao(dao);
        assertEq(address(treasury.dao()), dao);
    }

    function testApproveProposal() public {
        uint256 proposalId = 1;
        treasury.approveProposal(proposalId);
        assertEq(treasury.approvedProposals(proposalId), true);
    }

    function testSpendFunds() public {
        // First, deposit funds to the treasury
        treasury.deposit{value: DEPOSIT_AMOUNT}();
        assertEq(address(treasury).balance, DEPOSIT_AMOUNT);

        uint256 proposalId = 1;
        address recipient = makeAddr("recipient");
        uint256 amount = 1 ether;
        address token = address(0);

        // Approve the proposal (must be called from DAO address)
        vm.prank(address(this));
        treasury.approveProposal(proposalId);
        assertEq(treasury.approvedProposals(proposalId), true);

        // Execute spendFunds (must be called from DAO address)
        vm.prank(address(this));
        treasury.spendFunds(proposalId, recipient, amount, token);

        //funds have been transfered to the recipient
        assertEq(address(treasury).balance, 0);
        assertEq(recipient.balance, amount);
    }

    function testFundTreasury() public {
        treasury.fundTreasury{value: DEPOSIT_AMOUNT}();
        assertEq(address(treasury).balance, DEPOSIT_AMOUNT);
    }

    function testFundTreasuryWithToken() public {
        // Create a mock ERC20 token
        ERC20Mock token = new ERC20Mock();
        uint256 amount = 1 ether;

        // Mint tokens to the test contract
        token.mint(address(this), amount);
        assertEq(token.balanceOf(address(this)), amount);

        // Approve the treasury to spend tokens
        token.approve(address(treasury), amount);

        // Fund the treasury with tokens
        treasury.fundTreasuryWithToken(address(token), amount);

        // Verify the treasury has the tokens (not ETH)
        assertEq(token.balanceOf(address(treasury)), amount);
        assertEq(token.balanceOf(address(this)), 0);
    }
}
