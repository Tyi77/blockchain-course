// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import {Test} from "forge-std/Test.sol";
import {CatToken} from "../contracts/CatToken.sol";
import {DogToken} from "../contracts/DogToken.sol";
import {TokenTrade} from "../contracts/TokenTrade.sol";

contract TokenTradeTest is Test{
    CatToken catToken;
    DogToken dogToken;
    TokenTrade tokenTrade;

    uint256 oneCatToken;
    uint256 oneDogToken;

    function setUp() public {
        catToken = new CatToken();
        dogToken = new DogToken();
        
        oneCatToken = 10 ** catToken.decimals();
        oneDogToken = 10 ** dogToken.decimals();
        
        tokenTrade = new TokenTrade(address(catToken), address(dogToken));
    }

    function test_OneTrade() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Give alice some cat tokens and give bob some dog tokens
        catToken.transfer(alice, 500 * oneCatToken);
        dogToken.transfer(bob, 200 * oneDogToken);

        // alice setup the trade
        vm.startPrank(alice);
        catToken.approve(address(tokenTrade), 500 * oneCatToken);

        vm.expectEmit();
        emit TokenTrade.SetupTrade(0, alice, address(catToken), 100 * oneCatToken, 40 * oneDogToken, block.timestamp + 3 days);
        tokenTrade.setupTrade(
            address(catToken),
            100 * oneCatToken,
            40 * oneDogToken,
            block.timestamp + 3 days
        );
        vm.stopPrank();

        // bob settle the trade
        vm.startPrank(bob);
        dogToken.approve(address(tokenTrade), 200 * oneDogToken);

        vm.expectEmit();
        emit TokenTrade.SettleTrade(0, alice, bob);
        tokenTrade.settleTrade(0);

        vm.stopPrank();

        // the owner withdraw the fee
        tokenTrade.withdrawFee();

        // calculate the required fee
        uint256 requiredFee = 100 * oneCatToken / 1000;

        // check alice's tokens
        assertEq(catToken.balanceOf(alice), 400 * oneCatToken - requiredFee);
        assertEq(dogToken.balanceOf(alice), 40 * oneDogToken);
        // check bob's tokens
        assertEq(dogToken.balanceOf(bob), 160 * oneDogToken);
        assertEq(catToken.balanceOf(bob), 100 * oneCatToken);
        // check owner's tokens
        assertEq(catToken.balanceOf(address(this)), (100_000_000 * oneCatToken - 500 * oneCatToken + requiredFee));
        assertEq(dogToken.balanceOf(address(this)), (100_000_000 * oneDogToken - 200 * oneDogToken));
    }

    function test_SetupTrade_ZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0.");
        tokenTrade.setupTrade(address(catToken), 0, 40 * oneDogToken, block.timestamp + 1 days);
    }

    function test_SetupTrade_PastExpiry() public {
        vm.expectRevert("Expiry must be in the future.");
        tokenTrade.setupTrade(address(catToken), 100 * oneCatToken, 40 * oneDogToken, block.timestamp - 1);
    }

    function test_WithdrawNotOwner() public {
        address alice = makeAddr("alice");

        vm.prank(alice);
        vm.expectRevert("You are not the owner.");
        tokenTrade.withdrawFee();
    }

    function test_TradeExpiry() public {
        address alice = makeAddr("alice");

        // Give alice some cat tokens
        catToken.transfer(alice, 500 * oneCatToken);

        // alice approve and setup the trade
        vm.startPrank(alice);
        catToken.approve(address(tokenTrade), 500 * oneCatToken);

        vm.expectEmit();
        emit TokenTrade.SetupTrade(0, alice, address(catToken), 100 * oneCatToken, 40 * oneDogToken, block.timestamp + 3 days);
        tokenTrade.setupTrade(
            address(catToken),
            100 * oneCatToken,
            40 * oneDogToken,
            block.timestamp + 3 days // expired in 3 days
        );
        vm.stopPrank();

        // fast-forward time by 4 days
        vm.warp(block.timestamp + 4 days);

        // check expiry
        vm.prank(alice);
        tokenTrade.checkExpiry();

        // check alice's token
        assertEq(catToken.balanceOf(alice), 500 * oneCatToken);
        // check trade list
        (address seller,,,,) = tokenTrade.tradeList(0);
        assertEq(seller, address(0));
        // check seller trade
        uint256[] memory ids = tokenTrade.getSellerTrades(alice);
        for (uint256 i = 0; i < ids.length; ++i) {
            assertFalse(ids[i] == 0);
        }        
    }

    function test_SettleExpired() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Give alice some cat tokens and give bob some dog tokens
        catToken.transfer(alice, 500 * oneCatToken);
        dogToken.transfer(bob, 200 * oneDogToken);

        // alice approve and setup the trade
        vm.startPrank(alice);
        catToken.approve(address(tokenTrade), 500 * oneCatToken);

        vm.expectEmit();
        emit TokenTrade.SetupTrade(0, alice, address(catToken), 100 * oneCatToken, 40 * oneDogToken, block.timestamp + 3 days);
        tokenTrade.setupTrade(
            address(catToken),
            100 * oneCatToken,
            40 * oneDogToken,
            block.timestamp + 3 days // expired in 3 days
        );
        vm.stopPrank();

        // fast-forward time by 4 days
        vm.warp(block.timestamp + 4 days);

        // bob try to settle the expired trade
        vm.startPrank(bob);
        dogToken.approve(address(tokenTrade), 200 * oneDogToken);
        vm.expectRevert("Trade has expired."); // hope this reverts
        tokenTrade.settleTrade(0);
        vm.stopPrank();
    }

}