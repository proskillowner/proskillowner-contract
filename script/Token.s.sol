// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract TokenScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Token usdt = new Token("Tether USD", "USDT");
        console.log("USDT address =>", address(usdt));

        Token usdc = new Token("USD Coin", "USDC");
        console.log("USDC address =>", address(usdc));

        vm.stopBroadcast();
    }
}
