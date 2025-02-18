// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/XCash.sol";
import "../src/Bridge.sol";
import "./Constant.sol";

contract XcashDeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        XCash xcash = new XCash(Constant.XCASH_NAME, Constant.XCASH_SYMBOL);
        console.log("XCash =>", address(xcash));

        Bridge bridge = Bridge(vm.envAddress("BRIDGE"));

        xcash.setBridge(address(bridge));
        bridge.setXcash(address(xcash));

        vm.stopBroadcast();
    }
}
