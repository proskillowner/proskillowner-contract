// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EverETH.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        bot = new Bot();
        bot.main(100_000_000_000_000 * 1e9);
    }
}
