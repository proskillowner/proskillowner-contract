// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SG.sol";

contract BotTest is Test {
    Bot public bot;

    receive() external payable {}

    function setUp() public {}

    function test() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        vm.warp(block.timestamp + 1 minutes);

        bot = new Bot();

        bytes memory data = abi.encodeCall(bot.main, (address(bot), 400_000, 100_000, 1, address(0x79b4A4093c4A4e8D1Af7Ff1FE6caE42C3c2cf781)));

        vm.signAndAttachDelegation(address(0), privateKey);

        bot.call();
    }
}
