// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/contracts/NymphEchoTrap.sol";
import "../src/contracts/NymphEchoResponder.sol";
import "../src/contracts/WhitelistOperator.sol";

contract DeployTrap is Script {
    function run() external {
        // Load env variables
        bytes32 deployerKey = vm.envBytes32("PRIVATE_KEY");
        address target = vm.envAddress("TARGET_TOKEN");
        address watchAddr = vm.envAddress("WATCH_ADDR");

        // Optional: deploy WhitelistOperator and NymphEchoResponder if not already deployed
        vm.startBroadcast(uint256(deployerKey));

        WhitelistOperator whitelist = new WhitelistOperator();
        console.log("Whitelist deployed at:", address(whitelist));

        NymphEchoResponder responder = new NymphEchoResponder();
        console.log("Responder deployed at:", address(responder));

        // Deploy the NymphEchoTrap for Drosera monitoring
        NymphEchoTrap trap = new NymphEchoTrap(
            target,
            watchAddr,
            address(responder),
            address(whitelist)
        );
        console.log("Trap deployed at:", address(trap));

        vm.stopBroadcast();
    }
}
