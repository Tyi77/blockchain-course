// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SimpleDEX.sol";
import "../interfaces/IFlashBorrower.sol";

/// @title VulnerableLiquidator
/// @notice A lending protocol with liquidation support. Users deposit TokenA
///         as collateral and borrow TokenB. Undercollateralized positions
///         can be liquidated by anyone, with a liquidation bonus as incentive.
contract VulnerableLiquidator {
    SimpleDEX public dex;
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public constant LTV = 80;
    uint256 public constant LIQUIDATION_THRESHOLD = 100; // liquidatable when collateral value < debt
    uint256 public constant LIQUIDATION_BONUS = 5; // 5% bonus for liquidators

    struct Position {
        uint256 collateral; // TokenA
        uint256 debt;       // TokenB
    }

    mapping(address => Position) public positions;

    event PositionOpened(address indexed user, uint256 collateral, uint256 debt);
    event Liquidated(address indexed borrower, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);
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

    /// @notice Open a borrowing position. Deposits TokenA and borrows TokenB.
    /// @param collateralAmount Amount of TokenA to deposit.
    /// @param borrowAmount Amount of TokenB to borrow.
    function openPosition(uint256 collateralAmount, uint256 borrowAmount) external {
        require(collateralAmount > 0, "No collateral");
        require(borrowAmount > 0, "No borrow");

        tokenA.transferFrom(msg.sender, address(this), collateralAmount);

        uint256 price = getPrice();
        uint256 collateralValue = (collateralAmount * price) / 1e18;
        uint256 maxBorrow = (collateralValue * LTV) / 100;
        require(borrowAmount <= maxBorrow, "Exceeds LTV");
        require(borrowAmount <= tokenB.balanceOf(address(this)), "Insufficient liquidity");

        positions[msg.sender] = Position({
            collateral: collateralAmount,
            debt: borrowAmount
        });

        tokenB.transfer(msg.sender, borrowAmount);

        emit PositionOpened(msg.sender, collateralAmount, borrowAmount);
    }

    /// @notice Check whether a position is healthy.
    /// @param user The address of the borrower.
    /// @return True if the position is healthy (collateral value >= debt).
    function isHealthy(address user) public view returns (bool) {
        Position memory pos = positions[user];
        if (pos.debt == 0) return true;

        uint256 price = getPrice();
        uint256 collateralValue = (pos.collateral * price) / 1e18;
        return collateralValue >= pos.debt;
    }

    /// @notice Liquidate an undercollateralized position. The liquidator repays
    ///         the borrower's debt and receives the collateral plus a bonus.
    /// @param borrower The address of the borrower to liquidate.
    function liquidate(address borrower) external {
        Position memory pos = positions[borrower];
        require(pos.debt > 0, "No position");
        require(!isHealthy(borrower), "Position is healthy");

        // Liquidator repays the full debt
        tokenB.transferFrom(msg.sender, address(this), pos.debt);

        // Liquidator receives collateral + bonus
        uint256 bonus = (pos.collateral * LIQUIDATION_BONUS) / 100;
        uint256 totalSeized = pos.collateral + bonus;

        // Ensure protocol has enough TokenA for the bonus
        uint256 available = tokenA.balanceOf(address(this));
        if (totalSeized > available) {
            totalSeized = available;
        }

        delete positions[borrower];
        tokenA.transfer(msg.sender, totalSeized);

        emit Liquidated(borrower, msg.sender, pos.debt, totalSeized);
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
