// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract NymphEchoTrap is ITrap {
    struct Sample {
        address target;
        address watch;
        bytes32 codehash;
        uint256 balance;
        uint256 blockNumber;
    }

    /**
     * ------------------------------------------------------------------
     * collect()
     * Drosera runner collects data from this function.
     * ------------------------------------------------------------------
     */
    function collect() external view override returns (bytes memory) {
        address target = address(this);
        address watch = msg.sender;

        bytes32 codeh;
        assembly {
            codeh := extcodehash(target)
        }

        Sample memory s = Sample({
            target: target,
            watch: watch,
            codehash: codeh,
            balance: target.balance,
            blockNumber: block.number
        });

        return abi.encode(s);
    }

    /**
     * ------------------------------------------------------------------
     * shouldRespond()
     * Pure deterministic response logic.
     * ------------------------------------------------------------------
     */
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        Sample memory newest = _decodeSafe(data[0]);
        Sample memory previous = _decodeSafe(data[1]);

        bool codeChanged = newest.codehash != previous.codehash;
        bool balanceChanged = newest.balance != previous.balance;
        bool blockJump = newest.blockNumber <= previous.blockNumber;

        if (!(codeChanged || balanceChanged || blockJump)) {
            return (false, "");
        }

        bytes memory payload = abi.encode(
            newest.target,
            newest.watch,
            previous.codehash,
            newest.codehash,
            previous.balance,
            newest.balance,
            previous.blockNumber,
            newest.blockNumber,
            _reason(codeChanged, balanceChanged, blockJump)
        );

        return (true, payload);
    }

    /**
     * ------------------------------------------------------------------
     * Helpers
     * ------------------------------------------------------------------
     */

    function _decodeSafe(
        bytes calldata raw
    ) internal pure returns (Sample memory) {
        if (raw.length == 0) {
            return
                Sample({
                    target: address(0),
                    watch: address(0),
                    codehash: 0,
                    balance: 0,
                    blockNumber: 0
                });
        }
        return abi.decode(raw, (Sample));
    }

    function _reason(
        bool codeChanged,
        bool balanceChanged,
        bool blockJump
    ) internal pure returns (string memory) {
        if (codeChanged) return "codehash changed";
        if (balanceChanged) return "balance changed";
        if (blockJump) return "block number anomaly";
        return "no anomaly";
    }
}
