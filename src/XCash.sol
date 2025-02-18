// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract XCash is ERC20, Ownable, AccessControl {
    address public bridgeAddress;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    modifier onlyBridge() {
        require(msg.sender == bridgeAddress, "Not bridge");
        _;
    }

    function setBridge(address _bridgeAddress) public onlyOwner {
        bridgeAddress = _bridgeAddress;
    }

    function mint(address account, uint256 value) public onlyBridge {
        _mint(account, value);
    }

    function burn(address account, uint256 value) public onlyBridge {
        require(balanceOf(account) >= value, "Insufficient balance");

        _burn(account, value);
    }
}
