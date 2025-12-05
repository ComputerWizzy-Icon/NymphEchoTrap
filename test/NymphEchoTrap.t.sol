// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/contracts/NymphEchoTrap.sol";
import "../src/contracts/NymphEchoResponder.sol";
import "../src/contracts/WhitelistOperator.sol";

contract NymphEchoTrapTest is Test {
    address target = address(0x123);
    address watch = address(0x456);

    function testDeployTrap() public {
        // Deploy responder & whitelist
        NymphEchoResponder responder = new NymphEchoResponder();
        WhitelistOperator whitelist = new WhitelistOperator();

        // Deploy the trap
        NymphEchoTrap trap = new NymphEchoTrap(
            target,
            watch,
            address(responder),
            address(whitelist)
        );

        // Assert addresses
        assertEq(trap.target(), target);
        assertEq(trap.watchAddress(), watch);
        assertEq(address(trap.responder()), address(responder)); // cast to address
        assertEq(address(trap.whitelist()), address(whitelist)); // cast to address
    }
}
