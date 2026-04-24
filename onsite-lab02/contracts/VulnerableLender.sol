// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SimpleDEX.sol";
import "../interfaces/IFlashBorrower.sol";

/// @title VulnerableLender
/// @notice A lending protocol that allows users to deposit collateral (TokenA)
///         and borrow against it (TokenB). The collateral is valued using the
///         on-chain DEX price feed.
contract VulnerableLender {
    SimpleDEX public dex;
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public constant LTV = 80; // 80% loan-to-value

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;

    uint256 public totalLendingPool;

    event Deposited(address indexed user, uint256 collateralAmount, uint256 borrowed);
    event Repaid(address indexed user, uint256 amount);
    event FlashLoan(address indexed borrower, address token, uint256 amount);

    constructor(address _dex, address _tokenA, address _tokenB) {
        dex = SimpleDEX(_dex);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Returns the price of TokenA denominated in TokenB,
    ///         derived from the DEX reserves.
    function getPrice() public view returns (uint256) {
        (uint256 resA, uint256 resB) = dex.getReserves();
        require(resA > 0, "No liquidity");
        return (resB * 1e18) / resA;
    }

    /// @notice Deposit TokenA as collateral and borrow TokenB.
    /// @param collateralAmount The amount of TokenA to deposit.
    function depositAndBorrow(uint256 collateralAmount) external {
        require(collateralAmount > 0, "Amount must be > 0");

        tokenA.transferFrom(msg.sender, address(this), collateralAmount);
        collateral[msg.sender] += collateralAmount;

        uint256 price = getPrice();
        uint256 collateralValue = (collateral[msg.sender] * price) / 1e18;
        uint256 maxBorrow = (collateralValue * LTV) / 100;
        uint256 availableToBorrow = maxBorrow - debt[msg.sender];

        require(availableToBorrow > 0, "Nothing to borrow");
        uint256 borrowAmount = availableToBorrow;

        if (borrowAmount > tokenB.balanceOf(address(this))) {
            borrowAmount = tokenB.balanceOf(address(this));
        }

        debt[msg.sender] += borrowAmount;
        tokenB.transfer(msg.sender, borrowAmount);

        emit Deposited(msg.sender, collateralAmount, borrowAmount);
    }

    /// @notice Repay borrowed TokenB and withdraw collateral.
    /// @param amount The amount of TokenB to repay.
    function repay(uint256 amount) external {
        require(debt[msg.sender] >= amount, "Repaying too much");

        tokenB.transferFrom(msg.sender, address(this), amount);
        debt[msg.sender] -= amount;

        if (debt[msg.sender] == 0) {
            uint256 col = collateral[msg.sender];
            collateral[msg.sender] = 0;
            tokenA.transfer(msg.sender, col);
        }

        emit Repaid(msg.sender, amount);
    }

    /// @notice Borrow tokens for the duration of one transaction.
    /// @param token The token to borrow (must be TokenA or TokenB).
    /// @param amount The amount to borrow.
    /// @param data Arbitrary data passed to the borrower's callback.
    function flashLoan(address token, uint256 amount, bytes calldata data) external {
        require(token == address(tokenA) || token == address(tokenB), "Invalid token");

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
