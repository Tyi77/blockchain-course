// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDEX {
    function addLiquidity(uint256 amountA, uint256 amountB) external;
    function swap(address tokenIn, uint256 amountIn) external;
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB);
    function feeRecipient() external view returns (address);
    function withdrawFee() external;
}
