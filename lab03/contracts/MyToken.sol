// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MyToken is ERC20 { // Inherent ERC20 to make my own token
    mapping(address => uint256) public nonces; // To prevent replay attack.

    constructor() ERC20 ("MyToken", "MT") { // Call ERC20 constructor
        // Mint the token
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(block.timestamp <= deadline, "expired");
        require(nonce == nonces[owner], "wrong nonce");
        nonces[owner]++;

        bytes32 hash = keccak256( // Calculate the hash
            abi.encodePacked(
                owner,
                spender,
                value,
                nonce,
                deadline,
                address(this)
            )
        );
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash); // Convert the hash into message hash.
        address signer = ECDSA.recover(message, signature); // Calculate the signer from message and signature.

        // Check wheter the token owner is the signer.
        require(signer == owner, "invalid signature");

        // If the signature is valid and all checks pass, update the allowance
        _approve(owner, spender, value);
    }
}