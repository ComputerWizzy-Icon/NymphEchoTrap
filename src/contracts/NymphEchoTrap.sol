// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/// @notice Drosera-compatible stateless trap.
contract NymphEchoTrap is ITrap {
    /// @dev Replace with the real addresses you want to monitor.
    address public constant TARGET = 0x0000000000000000000000000000000000000000;
    address public constant WATCH = 0x0000000000000000000000000000000000000000;

    struct Sample {
        bytes32 codehash;
        uint256 balance;
        uint256 blockNumber;
    }

    /// @notice Deterministic snapshot of TARGET/WATCH.
    function collect() external view override returns (bytes memory) {
        bytes32 codeh;
        assembly {
            codeh := extcodehash(TARGET)
        }

        uint256 bal = WATCH.balance;
        uint256 blk = block.number;

        return abi.encode(codeh, bal, blk);
    }

    /// @notice Compare newest sample vs previous sample.
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        // Must have at least two valid samples
        if (data.length < 2 || data[0].length == 0 || data[1].length == 0) {
            return (false, "");
        }

        // Decode: (bytes32 codehash, uint256 balance, uint256 blockNumber)
        (bytes32 curCode, uint256 curBal, uint256 curBlk) = abi.decode(
            data[0],
            (bytes32, uint256, uint256)
        );
        (bytes32 prevCode, uint256 prevBal, uint256 prevBlk) = abi.decode(
            data[1],
            (bytes32, uint256, uint256)
        );

        bool codeChanged = (curCode != prevCode);
        bool balanceChanged = (curBal != prevBal);

        // Correct logic: detect true block regression only
        bool blockJump = (curBlk < prevBlk);

        if (!(codeChanged || balanceChanged || blockJump)) {
            return (false, "");
        }

        // EXACT 8-field payload to match responder + TOML
        bytes memory payload = abi.encode(
            TARGET,
            WATCH,
            prevCode,
            curCode,
            prevBal,
            curBal,
            prevBlk,
            curBlk
        );

        return (true, payload);
    }
}
