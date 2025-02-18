// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/XCash.sol";
import "../src/Bridge.sol";

contract BridgeDeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Bridge bridge = new Bridge();
        console.log("Bridge =>", address(bridge));

        XCash xcash = XCash(vm.envAddress("XCASH"));

        xcash.setBridge(address(bridge));
        bridge.setXcash(address(xcash));

        vm.stopBroadcast();
    }
}
