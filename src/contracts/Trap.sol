// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./WhitelistOperator.sol";

contract Trap {
    WhitelistOperator public whitelist;

    event TrapTriggered(address indexed operator, string reason);
    event ProtectedAction(address indexed operator, uint256 id);

    constructor(address whitelistAddress) {
        whitelist = WhitelistOperator(whitelistAddress);
    }

    modifier onlyAllowed() {
        require(whitelist.allowed(msg.sender), "operator not whitelisted");
        _;
    }

    function triggerTrap(string calldata reason) external onlyAllowed {
        emit TrapTriggered(msg.sender, reason);
    }

    function protectedAction(uint256 id) external onlyAllowed {
        emit ProtectedAction(msg.sender, id);
    }
}
