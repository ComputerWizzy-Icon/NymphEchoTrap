// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WhitelistOperator {
    address public owner;
    mapping(address => bool) public allowed;
    event OperatorToggled(address operator, bool allowedFlag);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOperator(address op, bool flag) external onlyOwner {
        allowed[op] = flag;
        emit OperatorToggled(op, flag);
    }
}
