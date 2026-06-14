// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ComplianceGate} from "./ComplianceGate.sol";

contract MockLendingPool is ComplianceGate {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;

    uint256 public totalDeposits;
    uint256 public totalBorrowed;

    event Deposited(address indexed account, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed account, uint256 amount, uint256 timestamp);
    event Borrowed(address indexed account, uint256 amount, uint256 timestamp);
    event Repaid(address indexed account, uint256 amount, uint256 timestamp);

    error InsufficientBalance();
    error InsufficientLiquidity();
    error ZeroAmount();

    constructor(address _complianceRegistry) ComplianceGate(_complianceRegistry) {}

    function deposit(bytes32[] calldata _proof) external payable onlyCompliant(_proof) {
        if (msg.value == 0) revert ZeroAmount();

        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    function withdraw(uint256 _amount, bytes32[] calldata _proof) external onlyCompliant(_proof) {
        if (_amount == 0) revert ZeroAmount();
        if (deposits[msg.sender] < _amount) revert InsufficientBalance();

        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }

    function borrow(uint256 _amount, bytes32[] calldata _proof) external onlyCompliant(_proof) {
        if (_amount == 0) revert ZeroAmount();
        if (address(this).balance < _amount) revert InsufficientLiquidity();

        borrowed[msg.sender] += _amount;
        totalBorrowed += _amount;

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Borrowed(msg.sender, _amount, block.timestamp);
    }

    function repay(bytes32[] calldata _proof) external payable onlyCompliant(_proof) {
        if (msg.value == 0) revert ZeroAmount();
        if (borrowed[msg.sender] < msg.value) revert InsufficientBalance();

        borrowed[msg.sender] -= msg.value;
        totalBorrowed -= msg.value;

        emit Repaid(msg.sender, msg.value, block.timestamp);
    }

    receive() external payable {}
}