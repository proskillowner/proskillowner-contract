// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/USDT.sol";
import "./Constant.sol";

contract UsdtDeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        USDT usdt = new USDT(Constant.USDT_NAME, Constant.USDT_SYMBOL);
        console.log("USDT =>", address(usdt));

        vm.stopBroadcast();
    }
}
