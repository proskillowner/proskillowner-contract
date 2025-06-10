// SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/FDC.sol";

import "@interfaces/IUniswapV2Router.sol";

interface IMint {
    function userLpValues(address) external view returns (uint256);
    function mintStartTimes(address) external view returns (uint256);
}

contract BotTest is Test {
    Bot public bot;
    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant FDC = ERC20(0xf0788dB035F1AEBF5E653f0692e72C0d34F9860C);
    IMint public constant MINT = IMint(0x50E27D405419de984d9EEe80068844A4ddA88D61);
    IUniswapV2Router public constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    receive() external payable {}

    function setUp() public {}

    function test() public {
        address zero = address(0xdead);
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address userAddress = vm.addr(privateKey);

        console.log("User address =>", userAddress);

        vm.startPrank(zero, zero);
        USDT.transfer(userAddress, 55 * 10 ** USDT.decimals());
        FDC.transfer(userAddress, 2500 * 10 ** FDC.decimals());

        vm.startPrank(userAddress, userAddress);

        bot = new Bot();
        bot.initialize();

        vm.signAndAttachDelegation(address(bot), privateKey);

        require(address(userAddress).code.length > 0, "no code");

        Bot(payable(address(userAddress))).main();

        uint256 usreLpValues = MINT.userLpValues(userAddress);
        console.log("User LP Values =>", usreLpValues / 1 ether);

        vm.warp(block.timestamp + 1 minutes);

        vm.signAndAttachDelegation(address(bot), privateKey);

        require(address(userAddress).code.length > 0, "no code");

        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(FDC);
        UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1 ether, 0, path, userAddress, block.timestamp
        );

        uint256 mintStartTime = MINT.mintStartTimes(userAddress);
        console.log("Mint Start Time =>", mintStartTime);
    }
}
