// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeesVault is Ownable2Step {
    using SafeERC20 for IERC20;

    event FeesReceived(address indexed token, uint256 amount);
    event Rebalanced(address indexed caller);
    event PLSBurned(uint256 amount);

    address public treasury;
    address public burn;
    address public router;
    address public usdl;
    address public wpls;

    constructor(address _treasury, address _burn, address _router, address _usdl, address _wpls) {
        treasury = _treasury;
        burn = _burn;
        router = _router;
        usdl = _usdl;
        wpls = _wpls;
    }

    function notifyFee(address token, uint256 amount) external {
        emit FeesReceived(token, amount);
    }

    function rebalance() external {
        emit Rebalanced(msg.sender);
    }

    function buyAndBurn() external {
        emit PLSBurned(0);
    }
}
