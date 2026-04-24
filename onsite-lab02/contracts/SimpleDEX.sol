// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleDEX
/// @notice A constant-product automated market maker for two ERC20 tokens.
///         Implements the x * y = k invariant.
contract SimpleDEX {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event Swap(address indexed user, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Add liquidity to the pool. Both tokens must be provided.
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    /// @notice Swap one token for the other using the constant-product formula.
    /// @param tokenIn The address of the token being sold.
    /// @param amountIn The amount of the input token.
    function swap(address tokenIn, uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");
        require(
            tokenIn == address(tokenA) || tokenIn == address(tokenB),
            "Invalid token"
        );

        bool isAtoB = tokenIn == address(tokenA);
        (IERC20 inputToken, IERC20 outputToken) = isAtoB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        (uint256 reserveIn, uint256 reserveOut) = isAtoB
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        inputToken.transferFrom(msg.sender, address(this), amountIn);

        // constant-product: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
        uint256 amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut > 0, "Insufficient output");
        require(amountOut <= reserveOut, "Insufficient liquidity");

        outputToken.transfer(msg.sender, amountOut);

        if (isAtoB) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    /// @notice Returns the current reserves of both tokens.
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}
