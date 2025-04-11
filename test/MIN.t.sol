// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MIN.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        vm.warp(block.timestamp + 9 hours);

        bot = new Bot();
        bot.main(20_500_000, address(0xF9EBAe14da49077203A8cbc76791679DC32b9435));
    }
}
