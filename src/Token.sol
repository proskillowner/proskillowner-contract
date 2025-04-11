//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(uint256 value) public {
        _mint(msg.sender, value);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }
}
