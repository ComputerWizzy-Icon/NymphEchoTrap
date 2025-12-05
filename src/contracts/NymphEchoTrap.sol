// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NymphEchoResponder.sol";
import "./WhitelistOperator.sol";

contract NymphEchoTrap {
    // Public getters used by tests
    address public target;
    address public watchAddress;
    uint256 public lastCheckedBlock;

    // External contracts
    NymphEchoResponder public responder;
    WhitelistOperator public whitelist;

    constructor(
        address _target,
        address _watchAddress,
        address _responder,
        address _whitelist
    ) {
        target = _target;
        watchAddress = _watchAddress;
        responder = NymphEchoResponder(_responder);
        whitelist = WhitelistOperator(_whitelist);

        // initialize tracker
        lastCheckedBlock = block.number;
    }

    modifier onlyAllowed() {
        require(whitelist.allowed(msg.sender), "not allowed operator");
        _;
    }

    function check(
        bytes32 oldCodehash,
        bytes32 newCodehash,
        uint256 oldBal,
        uint256 newBal,
        uint256 lastBlock
    ) external onlyAllowed {
        string memory reason;

        if (oldCodehash != newCodehash) {
            reason = "codehash changed";
        } else if (oldBal != newBal) {
            reason = "balance changed";
        } else if (lastBlock != lastCheckedBlock) {
            reason = "block inconsistency";
        } else {
            reason = "no anomaly";
        }

        responder.respondWithEchoAlert(
            target,
            watchAddress,
            oldCodehash,
            newCodehash,
            oldBal,
            newBal,
            lastCheckedBlock,
            block.number,
            reason
        );

        lastCheckedBlock = block.number;
    }
}
