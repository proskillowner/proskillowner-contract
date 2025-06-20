// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/QAI.sol";

interface IQaiHome2 {
    function userAllOrderMap(address user, uint256 id) external view returns (uint256);
}

contract BotTest is Test {
    Bot public bot;

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    receive() external payable {}

    function setUp() public {}

    function test() public {
        address zero = address(0xdead);
        address parent = 0x0B09199aA76c8b45B30340489636DbFE347E9613;
        IQaiHome2 qaiHome = IQaiHome2(0x8BdD52f80C55FBF73Cf21335709eb8096099bD86);

        bot = new Bot();

        vm.startPrank(zero);
        USDT.transfer(address(bot), 1000 * 10 ** USDT.decimals());
        WBNB.transfer(address(bot), 1 * 10 ** WBNB.decimals());

        vm.startPrank(bot.owner());

        bot.function1(parent);
        bot.function2(500, 1, 3);

        vm.warp(block.timestamp + 60 days);

        uint256 oid = qaiHome.userAllOrderMap(address(bot), 0);

        bot.function3(6_000_000, oid);
    }
}
