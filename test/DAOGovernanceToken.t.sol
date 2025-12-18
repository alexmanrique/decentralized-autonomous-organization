// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {DAOGoveranceToken} from "../src/DAOGoveranceToken.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract DAOGoveranceTokenTest is Test {
    DAOGoveranceToken public governanceToken;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 1 million tokens
    uint256 public constant ZERO_BALANCE = 0;

    function setUp() public {
        governanceToken = new DAOGoveranceToken("Governance Token", "GOV", INITIAL_SUPPLY);
    }

    function testMint() public {
        governanceToken.mint(address(this), INITIAL_SUPPLY);
        assertEq(governanceToken.balanceOf(address(this)), INITIAL_SUPPLY);
    }

    function testBurn() public {
        governanceToken.mint(address(this), INITIAL_SUPPLY);
        governanceToken.burn(INITIAL_SUPPLY);
        assertEq(governanceToken.balanceOf(address(this)), ZERO_BALANCE);
    }

    function testDelegateVotingPower() public {
        address delegate = makeAddr("delegate");
        governanceToken.mint(address(this), INITIAL_SUPPLY);
        governanceToken.delegateVotingPower(delegate, INITIAL_SUPPLY);
        assertEq(governanceToken.balanceOf(delegate), INITIAL_SUPPLY);
        assertEq(governanceToken.delegatedVotes(delegate), INITIAL_SUPPLY);
    }

    function testUndelegateVotingPower() public {
        address delegate = makeAddr("delegate");
        governanceToken.mint(address(this), INITIAL_SUPPLY);
        governanceToken.delegateVotingPower(delegate, INITIAL_SUPPLY);
        governanceToken.undelegateVotingPower(INITIAL_SUPPLY);
        assertEq(governanceToken.balanceOf(delegate), ZERO_BALANCE);
        assertEq(governanceToken.delegatedVotes(delegate), ZERO_BALANCE);
    }
}
