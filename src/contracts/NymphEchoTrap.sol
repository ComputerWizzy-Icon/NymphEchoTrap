// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

/// @notice Drosera-compatible stateless trap.
contract NymphEchoTrap is ITrap {
    /// @dev Burner EOA used for deterministic testing; replace with contract for real anomaly detection
    address public constant TARGET = 0x4B5525a09f287b5Af220c7BD982895FD821544fb;
    address public constant WATCH = 0x4B5525a09f287b5Af220c7BD982895FD821544fb;

    /// @notice Deterministic snapshot of TARGET
    function collect() external view override returns (bytes memory) {
        // Safety guard: never silently monitor zero addresses
        if (TARGET == address(0) || WATCH == address(0)) return bytes("");

        bytes32 codeh;
        assembly {
            codeh := extcodehash(TARGET)
        }

        uint256 bal = TARGET.balance;
        uint256 blk = block.number;

        return abi.encode(codeh, bal, blk);
    }

    /// @notice Compare newest sample vs previous sample
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        // 96-byte strict guard required by Drosera
        if (data.length < 2 || data[0].length < 96 || data[1].length < 96) {
            return (false, bytes(""));
        }

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
        bool blockJump = (curBlk < prevBlk);

        if (!(codeChanged || balanceChanged || blockJump)) {
            return (false, bytes(""));
        }

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
