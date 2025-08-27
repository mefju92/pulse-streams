// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {PulseStreams} from "./PulseStreams.sol";

contract MerkleStreamDistributor is Ownable2Step {
    event DistributorCreated(bytes32 merkleRoot, address token, uint256 totalPrefund);
    event StreamInitialized(address indexed account, uint256 amount);
    event UnclaimedSwept(address indexed to, uint256 amount);

    address public immutable pulseStreams;

    constructor(address _pulseStreams) {
        pulseStreams = _pulseStreams;
    }
}
