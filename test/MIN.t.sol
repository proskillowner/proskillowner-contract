// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MIN.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        vm.warp(block.timestamp + 10 hours);

        bot = new Bot();
        bot.main(24_000_000, address(0x79b4A4093c4A4e8D1Af7Ff1FE6caE42C3c2cf781));
    }
}
