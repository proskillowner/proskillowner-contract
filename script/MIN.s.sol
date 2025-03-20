// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MIN.sol";

contract BotScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Bot bot = new Bot();
        bot.main(24_000_000, address(0x79b4A4093c4A4e8D1Af7Ff1FE6caE42C3c2cf781));

        vm.stopBroadcast();
    }
}
