// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SimpleDEX.sol";

/// @title VulnerableRebalancer
/// @notice A treasury management contract that maintains a balanced portfolio
///         of TokenA and TokenB. Allows anyone to swap tokens with the treasury
///         at the current market price, incentivizing external actors to keep
///         the portfolio balanced.
contract VulnerableRebalancer {
    SimpleDEX public dex;
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public treasuryA;
    uint256 public treasuryB;
    uint256 public initialTreasuryValue;

    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _dex, address _tokenA, address _tokenB) {
        dex = SimpleDEX(_dex);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Initialize the treasury with token balances. Called once by the factory.
    /// @param amountA Amount of TokenA in treasury.
    /// @param amountB Amount of TokenB in treasury.
    function initializeTreasury(uint256 amountA, uint256 amountB) external {
        require(treasuryA == 0 && treasuryB == 0, "Already initialized");
        treasuryA = amountA;
        treasuryB = amountB;
        initialTreasuryValue = amountA + amountB;
    }

    /// @notice Returns the price of TokenA denominated in TokenB,
    ///         derived from the DEX reserves.
    function getPrice() public view returns (uint256) {
        (uint256 resA, uint256 resB) = dex.getReserves();
        require(resA > 0, "No liquidity");
        return (resB * 1e18) / resA;
    }

    /// @notice Returns the total treasury value denominated in TokenB.
    function getTreasuryValue() public view returns (uint256) {
        uint256 price = getPrice();
        uint256 valueA = (treasuryA * price) / 1e18;
        return valueA + treasuryB;
    }

    /// @notice Swap TokenA for TokenB with the treasury at the current market price.
    /// @param amountIn The amount of TokenA to sell to the treasury.
    function swapAForB(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");
        uint256 price = getPrice();
        uint256 amountOut = (amountIn * price) / 1e18;
        require(amountOut <= treasuryB, "Insufficient treasury balance");

        tokenA.transferFrom(msg.sender, address(this), amountIn);
        treasuryA += amountIn;
        treasuryB -= amountOut;
        tokenB.transfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenA), amountIn, amountOut);
    }

    /// @notice Swap TokenB for TokenA with the treasury at the current market price.
    /// @param amountIn The amount of TokenB to sell to the treasury.
    function swapBForA(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");
        uint256 price = getPrice();
        uint256 amountOut = (amountIn * 1e18) / price;
        require(amountOut <= treasuryA, "Insufficient treasury balance");

        tokenB.transferFrom(msg.sender, address(this), amountIn);
        treasuryB += amountIn;
        treasuryA -= amountOut;
        tokenA.transfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenB), amountIn, amountOut);
    }
}
