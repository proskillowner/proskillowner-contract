// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MEMEBTC.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        bot = new Bot();

        vm.startPrank(address(0xdead));
        bot.USDT().transfer(address(bot), 2000 * 10 ** bot.USDT().decimals());
        vm.stopPrank();

        bot.bind();

        bot.stake(1000);

        vm.warp(block.timestamp + 25 hours);

        bot.claim();

        bot.main(500_000, address(0xF9EBAe14da49077203A8cbc76791679DC32b9435));
    }
}
