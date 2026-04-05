// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Lab05Proxy is ERC1967Proxy {
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) payable {}
}
