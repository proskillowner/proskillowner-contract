// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/SG.sol";

interface ISG {
    function addressLpValue(address user) external view returns (uint256);
}

contract BotTest is Test {
    Bot public bot;

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ISG private constant SG = ISG(0xa28dB960e32833f582bA5F6338880bf239f2a966);

    receive() external payable {}

    function setUp() public {}

    function test() public {
        address zero = address(0x8894E0a0c962CB723c1976a4421c95949bE2D4E3);
        address owner = address(0x79b4A4093c4A4e8D1Af7Ff1FE6caE42C3c2cf781);
        address user1 = address(0x77664aC59958AAe048347f90868b8BBDF5d8701b);
        address user2 = address(0x979AC8a713c1B367C546e4f0AE796f613319F133);

        // vm.startPrank(user1, user1);
        // bot = new Bot();
        bot = Bot(payable(0xEFfbBF562b52A7D7b3593A6BBe715D67c16DF8f4));

        // vm.warp(block.timestamp + 18 hours);

        // bot.transferOwnership(user1);
        // bot.approve();
        // bot.setAdder(user1);
        // bot.setRemover(user2);

        // vm.startPrank(zero, zero);
        // USDT.transfer(address(bot), 800 * 10 ** USDT.decimals());

        // vm.startPrank(zero, zero);
        // payable(user1).transfer(1 ether);

        // vm.startPrank(zero, zero);
        // payable(user2).transfer(1 ether);

        // vm.startPrank(owner, owner);
        // bot.buy(400 * 10 ** USDT.decimals());

        for (uint256 i = 0; i < 0; i++) {
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
    }
}
