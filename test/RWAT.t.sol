// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWAT.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        bot = new Bot();
        bot.main(
            500_000,
            200_000,
            address(0x255667C1E1964b2C75B1Ca0a157033F9Eb779676),
            address(0xF9EBAe14da49077203A8cbc76791679DC32b9435)
        );
    }
}
