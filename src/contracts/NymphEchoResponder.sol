// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NymphEchoResponder {
    event EchoIncident(
        address indexed target,
        address indexed watchAddr,
        bytes32 oldCodehash,
        bytes32 newCodehash,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 oldBlock,
        uint256 newBlock
    );

    /// @notice Called by Drosera relay
    function respondWithEchoAlert(
        address _target,
        address _watchAddr,
        bytes32 _oldCodeh,
        bytes32 _newCodeh,
        uint256 _oldBal,
        uint256 _newBal,
        uint256 _oldBlock,
        uint256 _newBlock
    ) external {
        emit EchoIncident(
            _target,
            _watchAddr,
            _oldCodeh,
            _newCodeh,
            _oldBal,
            _newBal,
            _oldBlock,
            _newBlock
        );
    }
}
