// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract PulseStreams is ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IERC20;

    struct Stream {
        address sender;
        address recipient;
        address token;
        uint64  start;
        uint64  end;
        uint64  cliff;
        uint128 ratePerSec;
        uint128 deposited;
        uint128 withdrawn;
        bool    cancelable;
        bool    canceled;
    }

    error NotCancelable();
    error TokenNotWhitelisted();
    error AmountZero();
    error CapExceeded();
    error CliffNotReached();
    error NotRecipient();
    error InvalidTime();

    event StreamCreated(uint256 indexed id, address indexed sender, address indexed recipient, address token, uint128 amount, uint64 start, uint64 end, uint64 cliff, bool cancelable);
    event Withdrawn(uint256 indexed id, address indexed to, uint128 amount, uint128 fee);
    event TopUp(uint256 indexed id, uint128 amount, uint64 newEnd);
    event Canceled(uint256 indexed id, uint128 returnedToSender);

    address public immutable feesVault;
    uint256 public nextId = 1;

    mapping(uint256 => Stream) public streams;
    mapping(address => bool) public tokenWhitelist;

    uint16 public constant FEE_BPS = 50; // 0.5%

    constructor(address _feesVault) {
        feesVault = _feesVault;
    }

    function setTokenWhitelist(address token, bool allowed) external onlyOwner {
        tokenWhitelist[token] = allowed;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function createStream(
        address token,
        address recipient,
        uint128 totalAmount,
        uint64 start,
        uint64 end,
        uint64 cliff,
        bool cancelable
    ) external nonReentrant whenNotPaused returns (uint256 id) {
        if (!tokenWhitelist[token]) revert TokenNotWhitelisted();
        if (totalAmount == 0) revert AmountZero();
        if (end <= start) revert InvalidTime();
        if (cliff != 0 && (cliff < start || cliff > end)) revert InvalidTime();

        IERC20(token).safeTransferFrom(msg.sender, address(this), totalAmount);

        uint64 duration = end - start;
        uint128 rate = uint128(uint256(totalAmount) / uint256(duration));

        id = nextId++;
        streams[id] = Stream({
            sender: msg.sender,
            recipient: recipient,
            token: token,
            start: start,
            end: end,
            cliff: cliff,
            ratePerSec: rate,
            deposited: totalAmount,
            withdrawn: 0,
            cancelable: cancelable,
            canceled: false
        });

        emit StreamCreated(id, msg.sender, recipient, token, totalAmount, start, end, cliff, cancelable);
    }

    function balanceOf(uint256 id) public view returns (uint256 accrued, uint256 withdrawable) {
        Stream memory s = streams[id];
        if (s.recipient == address(0)) { return (0, 0); }

        uint64 t = uint64(block.timestamp);
        if (t < s.start || (s.cliff != 0 && t < s.cliff)) {
            return (0, 0);
        }

        uint64 effectiveEnd = s.end;
        if (t > effectiveEnd) t = effectiveEnd;

        uint64 elapsed = t - s.start;
        uint256 raw = uint256(elapsed) * uint256(s.ratePerSec);
        if (raw > s.deposited) raw = s.deposited;
        accrued = raw;
        if (accrued <= s.withdrawn) return (accrued, 0);
        withdrawable = accrued - s.withdrawn;
    }

    function withdraw(uint256 id, address to) external nonReentrant whenNotPaused {
        Stream storage s = streams[id];
        if (msg.sender != s.recipient) revert NotRecipient();
        (, uint256 available) = balanceOf(id);
        if (available == 0) revert CliffNotReached();

        uint256 fee = (available * FEE_BPS) / 10000;
        uint256 payout = available - fee;

        s.withdrawn += uint128(available);
        IERC20(s.token).safeTransfer(to, payout);
        if (fee > 0) {
            IERC20(s.token).safeTransfer(feesVault, fee);
        }
        emit Withdrawn(id, to, uint128(payout), uint128(fee));
    }

    function topUp(uint256 id, uint128 amount) external nonReentrant whenNotPaused {
        Stream storage s = streams[id];
        require(msg.sender == s.sender, "not sender");
        if (amount == 0) revert AmountZero();
        IERC20(s.token).safeTransferFrom(msg.sender, address(this), amount);
        s.deposited += amount;
        require(s.ratePerSec > 0, "rate=0");
        uint64 extra = uint64(uint256(amount + s.ratePerSec - 1) / uint256(s.ratePerSec)); // ceil
        s.end += extra;
        emit TopUp(id, amount, s.end);
    }

    function cancel(uint256 id) external nonReentrant whenNotPaused {
        Stream storage s = streams[id];
        if (!s.cancelable) revert NotCancelable();
        require(msg.sender == s.sender, "not sender");
        (, uint256 available) = balanceOf(id);
        if (available > 0) {
            s.withdrawn += uint128(available);
            IERC20(s.token).safeTransfer(s.recipient, available);
        }
        uint256 leftover = s.deposited - s.withdrawn;
        s.canceled = true;
        s.end = uint64(block.timestamp);
        if (leftover > 0) {
            IERC20(s.token).safeTransfer(s.sender, leftover);
        }
        emit Canceled(id, uint128(leftover));
    }
}
