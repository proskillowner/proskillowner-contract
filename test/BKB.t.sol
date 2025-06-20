// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BKB.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        bot = new Bot();
        bot.main{value: 0.1 ether}(600, 200, address(0xF9EBAe14da49077203A8cbc76791679DC32b9435));
    }
}
