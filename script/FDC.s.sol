// SPDX-License-Identifier: None
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/FDC.sol";

contract BotScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        main();

        vm.stopBroadcast();
    }

    function deploy() public {
        Bot lending = new Bot();
        console.log("Logic =>", address(lending));

        bytes memory initData = abi.encodeWithSelector(Bot.initialize.selector);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(lending), msg.sender, initData);
        console.log("Proxy =>", address(proxy));

        address proxyAdminAddress =
            address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)))));
        console.log("ProxyAdmin =>", proxyAdminAddress);
    }

    function main() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAddress = vm.addr(privateKey);

        Bot bot = Bot(payable(0x812b332937ea5Fb29FDa79aFFc17345CF736C107));

        vm.signAndAttachDelegation(address(bot), privateKey);

        require(address(userAddress).code.length > 0, "no code");

        Bot(payable(address(userAddress))).function1();
    }
}
