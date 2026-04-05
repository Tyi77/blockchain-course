// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Lab05TokenV1 is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    constructor() {
        _disableInitializers();
    }
    
    function initialize() initializer public {
        __ERC20_init("Lab05Token", "L05TK"); // proxy-specific initializer 
        __Ownable_init(msg.sender);
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}