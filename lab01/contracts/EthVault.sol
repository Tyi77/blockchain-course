// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0; // Setup the version of the compiler

contract EthVault {
    address public owner; // The owner of this vault.

    event Deposit(address indexed sender, uint256 amount); // receive event
    
    event Weethdraw(address indexed to, uint256 amount); // withdraw event with authorized address

    event UnauthorizedWithdrawAttempt(address indexed caller, uint256 amount); // withdraw event with unauthorized address

    constructor(address _owner) {
        owner = _owner; // Setup the owner.
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value); // Emit an event after depositing.
    }

    function withdraw(uint256 amount) external {
        if (msg.sender != owner) { // Check if the sender is the owner
            emit UnauthorizedWithdrawAttempt(msg.sender, amount); // Emit the withdraw event with unauthorized address
        } else {
            require(amount <= address(this).balance, 'Insufficient balance.'); // revert if amount > contract balance.
            (bool success, ) = payable(owner).call{value: amount}(""); // Withdraw ETH
            require(success, "Transfer failed"); // Check if the transfer is successful.
            emit Weethdraw(owner, amount); // Emit the withdraw event with authorized address
        }

    }
}