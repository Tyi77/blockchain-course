// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AToken is ERC20 { // Inherent ERC20 to make my own token  
    constructor() ERC20 ("AToken", "AT") { // Call ERC20 constructor
        // Mint the token
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }
}