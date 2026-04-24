// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFlashBorrower.sol";

/// @title FlashLoanPool
/// @notice A simple flash loan provider for multiple tokens. Borrow any amount
///         for the duration of a single transaction, as long as it is returned
///         by the end of the callback.
contract FlashLoanPool {
    event FlashLoan(address indexed borrower, address token, uint256 amount);

    /// @notice Borrow tokens for the duration of one transaction.
    /// @param token The token to borrow.
    /// @param amount The amount to borrow.
    /// @param data Arbitrary data passed to the borrower's callback.
    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        require(balBefore >= amount, "Insufficient balance");

        IERC20(token).transfer(msg.sender, amount);
        IFlashBorrower(msg.sender).onFlashLoan(token, amount, data);

        require(
            IERC20(token).balanceOf(address(this)) >= balBefore,
            "Flash loan not repaid"
        );

        emit FlashLoan(msg.sender, token, amount);
    }
}
