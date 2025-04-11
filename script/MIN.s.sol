// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MIN.sol";

contract BotScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Bot bot = new Bot();
        bot.main(24_000_000, address(0xF9EBAe14da49077203A8cbc76791679DC32b9435));

        vm.stopBroadcast();
    }
}
