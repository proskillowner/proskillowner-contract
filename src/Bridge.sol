// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {XCash} from "./XCash.sol";

contract Bridge is Ownable {
    XCash public xcash;

    event FromXRP(string from, address to, uint256 value);
    event ToXRP(address from, string to, uint256 value);

    constructor() Ownable(msg.sender) {}

    function setXcash(address xcashAddress) public {
        xcash = XCash(xcashAddress);
    }

    function fromXRP(string calldata from, address to, uint256 value) public onlyOwner {
        require(value > 0, "Invalid value");

        xcash.mint(to, value);
        emit FromXRP(from, to, value);
    }

    function toXRP(string calldata to, uint256 value) public {
        require(value > 0, "Invalid value");

        xcash.burn(msg.sender, value);
        emit ToXRP(msg.sender, to, value);
    }
}
