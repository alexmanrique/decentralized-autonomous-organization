// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract DAOGoveranceToken is ERC20, Ownable {
    mapping(address => bool) public hasDelegated;
    mapping(address => address) public delegates;
    mapping(address => uint256) public delegatedVotes;

    event VotingPowerDelegated(address indexed delegator, address indexed delegate, uint256 amount);
    event VotingPowerUndelegated(address indexed delegator, address indexed delegate, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {}

    function getVotingPower(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    function delegateVotingPower(address delegate, uint256 amount) external {
        require(delegate != address(0), "Cannot delegate to zero address");
        require(delegate != msg.sender, "Cannot delegate to yourself");
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _transfer(msg.sender, delegate, amount);

        delegates[msg.sender] = delegate;
        delegatedVotes[delegate] += amount;
        hasDelegated[msg.sender] = true;

        emit VotingPowerDelegated(msg.sender, delegate, amount);
    }

    function undelegateVotingPower(uint256 amount) external {
        require(hasDelegated[msg.sender], "No delegation found");
        require(amount > 0, "Amount must be greater than zero");
        require(delegatedVotes[delegates[msg.sender]] >= amount, "Insufficient voting power");

        address delegate = delegates[msg.sender];
        _transfer(delegate, msg.sender, amount);

        delegatedVotes[delegate] -= amount;

        if (delegatedVotes[delegate] == 0) {
            hasDelegated[msg.sender] = false;
            delete delegates[msg.sender];
        }
        emit VotingPowerUndelegated(msg.sender, delegate, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
