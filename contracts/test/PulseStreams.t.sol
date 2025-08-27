// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PulseStreams.sol";
import "../src/FeesVault.sol";

contract PulseStreamsTest is Test {
    FeesVault fv;
    PulseStreams ps;

    function setUp() public {
        fv = new FeesVault(address(0x1), address(0xdead), address(0x2), address(0x3), address(0x4));
        ps = new PulseStreams(address(fv));
    }

    function testDeploy() public {
        assertTrue(address(ps) != address(0));
        assertEq(ps.feesVault(), address(fv));
    }
}
