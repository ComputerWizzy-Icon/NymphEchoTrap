// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/contracts/NymphEchoResponder.sol";
import "../src/contracts/NymphEchoTrap.sol";

contract DeployAll is Script {
    function run() external {
        bytes32 deployerKey = vm.envBytes32("PRIVATE_KEY");
        uint256 pk = uint256(deployerKey);

        vm.startBroadcast(pk);

        // Deploy responder
        NymphEchoResponder responder = new NymphEchoResponder();
        console.log("Responder deployed at:", address(responder));

        // Deploy trap (no constructor params)
        NymphEchoTrap trap = new NymphEchoTrap();
        console.log("Trap deployed at:", address(trap));

        vm.stopBroadcast();
    }
}
