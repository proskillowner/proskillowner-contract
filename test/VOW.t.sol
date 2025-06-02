// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VOW.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        vm.warp(block.timestamp + 9 hours);

        bot = new Bot();
        bot.main{value: 0.001 ether}(50_000, 0, 100_000, address(0xF9EBAe14da49077203A8cbc76791679DC32b9435));
    }
}
