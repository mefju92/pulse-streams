// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PulseStreams.sol";
import "../src/FeesVault.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        FeesVault fv = new FeesVault(address(0x1), address(0xdead), address(0x2), address(0x3), address(0x4));
        PulseStreams ps = new PulseStreams(address(fv));
        vm.stopBroadcast();
    }
}
