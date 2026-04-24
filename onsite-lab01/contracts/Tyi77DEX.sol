// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tyi77DEX {
    // two tokens
    IERC20 public aToken;
    IERC20 public bToken;

    // Pool parameters and exchanging parameter
    uint256 public totalA;
    uint256 public totalB;
    uint256 public r;
    uint256 public k;

    // owner
    address public owner;

    // fee
    uint256 public feeA;
    uint256 public feeB;

    constructor(address _aToken, address _bToken, uint256 _r) {
        aToken = IERC20(_aToken);
        bToken = IERC20(_bToken);
        totalA = 0;
        totalB = 0;
        r = _r;
        k = 0;
        owner = 0x3AD64ABb43D793025a2f2bD9d615fa1447008bFD;
        feeA = 0;
        feeB = 0;
    }


    function addLiquidity(uint256 amountA, uint256 amountB) external {
        // Transfer A and B into the pool
        aToken.transferFrom(msg.sender, address(this), amountA);
        totalA += amountA;
        bToken.transferFrom(msg.sender, address(this), amountB);
        totalB += amountB;

        // Update the liquidity
        k = totalA + r * totalB;
    }

    function swap(address tokenIn, uint256 amountIn) external {
        IERC20 inputToken = IERC20(tokenIn);
        if (inputToken == aToken) {
            uint256 outputAmount = (amountIn * 999 / 1000) / r;
            // Check B Token liquidity
            require(outputAmount <= totalB, "B token liquidity is not enough");
            
            // Input A Token
            aToken.transferFrom(msg.sender, address(this), amountIn);
            totalA += amountIn * 999 / 1000;
            feeA += amountIn / 1000;

            // Output B Token
            bToken.transfer(msg.sender, outputAmount);
            totalB -= outputAmount;
        } else if (inputToken == bToken) {
            uint256 outputAmount = (amountIn * 999 / 1000) * r;
            // Check A Token liquidity
            require(outputAmount <= totalA, "A token liquidity is not enough");
            
            // Input B Token
            bToken.transferFrom(msg.sender, address(this), amountIn);
            totalB += amountIn * 999 / 1000;
            feeB += amountIn / 1000;

            // Output A Token
            aToken.transfer(msg.sender, outputAmount);
            totalA -= outputAmount;
        } else {
            revert("Wrong Token Address");
        }
    }
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB) {
        return (totalA, totalB);
    }
    function feeRecipient() external view returns (address) {
        return owner;
    }
    function withdrawFee() external {
        require(msg.sender == owner, "You're not an owner.");

        aToken.transfer(msg.sender, feeA);
        feeA = 0;
        bToken.transfer(msg.sender, feeB);
        feeB = 0;
    }
}