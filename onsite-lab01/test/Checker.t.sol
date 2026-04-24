// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {Test} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/IDEX.sol";
import {AToken} from "../contracts/AToken.sol";
import {BToken} from "../contracts/BToken.sol";
import {Tyi77DEX} from "../contracts/Tyi77DEX.sol";

contract CheckerTest is Test {
    address tokenA;
    address tokenB;
    address dex;
    string studentId = "313553029";
    uint256 rate = 5;

    uint256 constant TOKEN = 1e18;

    event Passed(string studentId, address indexed caller);
    event PassedBonus(string studentId, address indexed caller);

    mapping(string => bool) public passed;
    mapping(string => bool) public passedBonus;
    mapping(address => bool) public callerUsed;
    mapping(address => bool) public callerUsedBonus;

    function setUp() public {
        tokenA = address(new AToken());
        tokenB = address(new BToken());
        dex = address(new Tyi77DEX(tokenA, tokenB, 5));
    }

    function test_Check(
    ) public {

        require(bytes(studentId).length > 0, "Student ID required");
        require(!passed[studentId], "Student ID already passed");
        require(!callerUsed[msg.sender], "Wallet already used");
        require(rate > 0, "Rate must be positive");

        IERC20 a = IERC20(tokenA);
        IERC20 b = IERC20(tokenB);
        IDEX d = IDEX(dex);

        uint256 liqA = 100 * TOKEN * rate;
        uint256 liqB = 100 * TOKEN;
        uint256 swapAmtA = 10 * TOKEN * rate;
        uint256 swapAmtB = 10 * TOKEN;

        require(
            a.balanceOf(address(this)) >= liqA + swapAmtA,
            "Send more tokenA to checker"
        );
        require(
            b.balanceOf(address(this)) >= liqB + swapAmtB,
            "Send more tokenB to checker"
        );

        a.approve(dex, type(uint256).max);
        b.approve(dex, type(uint256).max);

        // Test 1: addLiquidity updates reserves correctly
        (uint256 r0A, uint256 r0B) = d.getReserves();
        d.addLiquidity(liqA, liqB);
        (uint256 r1A, uint256 r1B) = d.getReserves();
        require(r1A == r0A + liqA, "addLiquidity: reserveA mismatch");
        require(r1B == r0B + liqB, "addLiquidity: reserveB mismatch");

        // Record invariant k after adding liquidity
        uint256 kAfterLiq = r1A + rate * r1B;

        // Test 2: swap A -> B at the correct rate
        uint256 bBefore = b.balanceOf(address(this));
        d.swap(tokenA, swapAmtA);
        require(
            b.balanceOf(address(this)) - bBefore == swapAmtB,
            "swap A->B: wrong output amount"
        );

        // Verify invariant k unchanged after swap
        (uint256 rSwap1A, uint256 rSwap1B) = d.getReserves();
        require(
            rSwap1A + rate * rSwap1B == kAfterLiq,
            "swap A->B: invariant k changed"
        );

        // Test 3: swap B -> A at the correct rate
        uint256 aBefore = a.balanceOf(address(this));
        d.swap(tokenB, swapAmtB);
        require(
            a.balanceOf(address(this)) - aBefore == swapAmtA,
            "swap B->A: wrong output amount"
        );

        // Verify invariant k unchanged after swap
        (uint256 rSwap2A, uint256 rSwap2B) = d.getReserves();
        require(
            rSwap2A + rate * rSwap2B == kAfterLiq,
            "swap B->A: invariant k changed"
        );

        // Test 4: reserves are consistent after round-trip swaps
        require(rSwap2A == r1A, "Reserves A inconsistent after swaps");
        require(rSwap2B == r1B, "Reserves B inconsistent after swaps");

        passed[studentId] = true;
        callerUsed[msg.sender] = true;
        emit Passed(studentId, msg.sender);
    }
}