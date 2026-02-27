// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0; // Setup the version of the compiler

import {EthVault} from "../contracts/EthVault.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract EthVaultTest is Test {
    EthVault ethVault;

    function setUp() public {
        ethVault = new EthVault(address(this));
    }

    receive() external payable {}

    // == Group A ==
    function test_SingleDeposit() public {
        uint256 depositAmount = 1 ether; // Testing Eth amount

        // one-time deposit
        vm.expectEmit();
        emit EthVault.Deposit(address(this), depositAmount);

        (bool success, ) = payable(address(ethVault)).call{value: depositAmount}("");
        require(success, "Deposit failed"); // Check if the transfer is successful.
    
        // Check balance amount
        assertEq(address(ethVault).balance, depositAmount);
    }

    function test_MultipleDeposits() public {
        uint256 depositAmount = 1 ether; // Testing Eth amount

        uint8 count = uint8(vm.randomUint(2, 10));
        console.log("Number of Deposits: ", count);
        for (uint8 i = 0; i < count; ++i) {
            vm.expectEmit();
            emit EthVault.Deposit(address(this), depositAmount);

            (bool success, ) = payable(address(ethVault)).call{value: depositAmount}("");
            require(success, "Deposit failed"); // Check if the transfer is successful.
        }
    
        // Check balance amount
        assertEq(address(ethVault).balance, depositAmount * count);
    }

    function test_DifferentSenders() public {
        uint256 depositAmount = 1 ether; // Testing Eth amount

        address alice = makeAddr("alice"); // Generate a sender
        address bob = makeAddr("bob");
        uint256 aliceBalance = vm.randomUint(2, 10) * 1 ether;
        uint256 bobBalance = vm.randomUint(2, 10) * 1 ether;
        vm.deal(alice, aliceBalance); // Give alice and bob random ethers respectively
        vm.deal(bob, bobBalance);

        // alice
        vm.expectEmit();
        emit EthVault.Deposit(alice, depositAmount);

        vm.prank(alice); // Change the msg.sender to alice temporarily
        (bool salice, ) = payable(address(ethVault)).call{value: depositAmount}("");
        require(salice, "Alice Deposit failed.");

        // bob
        vm.expectEmit();
        emit EthVault.Deposit(bob, depositAmount);

        vm.prank(bob); // Change the msg.sender to alice temporarily
        (bool sbob, ) = payable(address(ethVault)).call{value: depositAmount}("");
        require(sbob, "Bob Deposit failed.");

        // Check the amount
        assertEq(alice.balance, aliceBalance - depositAmount);
        assertEq(bob.balance, bobBalance - depositAmount);
        assertEq(address(ethVault).balance, 2 ether);
    }

    // == Group B ==
    function test_OwnerWithdraw() public {
        // Give ethVault 100 ethers
        uint256 ethVaultOriginalBalance = 100 ether;
        vm.deal(address(ethVault), ethVaultOriginalBalance);

        // 1. Withdraw partial amount
        uint256 withdrawAmount = vm.randomUint(1, ethVaultOriginalBalance / 2);
        vm.expectEmit();
        emit EthVault.Weethdraw(address(this), withdrawAmount);

        ethVault.withdraw(withdrawAmount);

        // Check balance
        assertEq(address(ethVault).balance, ethVaultOriginalBalance - withdrawAmount);

        // 2. Withdraw full(remaining) balance
        uint256 fullBalanceOfVault = address(ethVault).balance;
        vm.expectEmit();
        emit EthVault.Weethdraw(address(this), fullBalanceOfVault);

        ethVault.withdraw(fullBalanceOfVault);

        // Check if the vault is empty
        assertEq(address(ethVault).balance, 0);
    }
    
    // == Group C ==
    function test_UnauthorizedWithdraw() public {
        // Give ethVault 100 ethers
        uint256 ethVaultOriginalBalance = 100 ether;
        vm.deal(address(ethVault), ethVaultOriginalBalance);

        // Generate an unauthorized account
        address alice = makeAddr("alice");
        
        uint256 withdrawAmount = vm.randomUint(1, ethVaultOriginalBalance / 2);
        vm.expectEmit();
        emit EthVault.UnauthorizedWithdrawAttempt(alice, withdrawAmount);

        vm.prank(alice);
        ethVault.withdraw(withdrawAmount);

        // Check balance
        assertEq(address(ethVault).balance, ethVaultOriginalBalance);
    }

    // == Group D ==
    function test_WithdrawMoreThanBalance() public {
        // Give ethVault 100 ethers
        uint256 ethVaultOriginalBalance = 100 ether;
        vm.deal(address(ethVault), ethVaultOriginalBalance);

        // Withdraw more than vault's balance
        vm.expectRevert();
        ethVault.withdraw(101 ether);
    }

    function test_WithdrawZero() public {
        // Give ethVault 100 ethers
        uint256 ethVaultOriginalBalance = 100 ether;
        vm.deal(address(ethVault), ethVaultOriginalBalance);

        // Withdraw zero
        vm.expectEmit();
        emit EthVault.Weethdraw(address(this), 0);
        ethVault.withdraw(0);

        // Check balance
        assertEq(address(ethVault).balance, ethVaultOriginalBalance);
    }

    function test_MultipleDepositsAndWithdraw() public {
        // Multiple Deposits
        uint256 depositAmount = 1 ether;
        
        uint8 count = uint8(vm.randomUint(2, 10));
        console.log("Number of Deposits: ", count);
        for (uint8 i = 0; i < count; ++i) {
            vm.expectEmit();
            emit EthVault.Deposit(address(this), depositAmount);

            (bool success, ) = payable(address(ethVault)).call{value: depositAmount}("");
            require(success, "Deposit failed"); // Check if the transfer is successful.
        }

        // Withdraw partial balance
        uint256 withdrawAmount = vm.randomUint(1, address(ethVault).balance);
        vm.expectEmit();
        emit EthVault.Weethdraw(address(this), withdrawAmount);

        ethVault.withdraw(withdrawAmount);

        // Withdraw more than balance
        uint256 overdrawAmount = address(ethVault).balance + 1 ether;

        vm.expectRevert();
        ethVault.withdraw(overdrawAmount);

        // Check balance
        assertEq(address(ethVault).balance, count * 1 ether - withdrawAmount);
    }
}

