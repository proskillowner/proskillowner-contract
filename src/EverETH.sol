//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IPancakeCallee.sol";

interface IEverETH is IERC20 {
    function claim() external;
}

interface IEverETHDividendTracker is IERC20 {
    function withdrawnDividendOf(address _owner) external returns (uint256);
    function withdrawableDividendOf(address account) external view returns (uint256);
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}

contract Bot is Ownable, IPancakeCallee {
    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant USDT_EverETH_PAIR = IUniswapV2Pair(0x7F5a011b3e0a0F8824f54059654ac52E7A3e47b9);

    IERC20 private constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 private constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IEverETH private constant EverETH = IEverETH(0x16dCc0eC78E91e868DCa64bE86aeC62bf7C61037);
    IERC20 private constant ETH = IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IEverETHDividendTracker private constant EverETH_Dividend_Tracker =
        IEverETHDividendTracker(0x1c54B7fDfd04Ec383B7a00f5D77Ed19b9ea6FE76);

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

    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        (uint256 borrowAmount) = abi.decode(data, (uint256));

        console.log("EverETH_Dividend_Tracker balance =>", EverETH_Dividend_Tracker.balanceOf(address(this)));
        console.log(
            "EverETH_Dividend_Tracker accumulativeDividendOf =>",
            EverETH_Dividend_Tracker.accumulativeDividendOf(address(this))
        );
        console.log(
            "EverETH_Dividend_Tracker withdrawnDividendOf =>",
            EverETH_Dividend_Tracker.withdrawnDividendOf(address(this))
        );
        console.log(
            "EverETH_Dividend_Tracker withdrawableDividendOf =>",
            EverETH_Dividend_Tracker.withdrawableDividendOf(address(this))
        );

        EverETH.claim();

        console.log("ETH balance =>", ETH.balanceOf(address(this)));

        // require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        // USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function main(uint256 a) public onlyOwner {
        bytes memory params = abi.encode(a);

        USDT_EverETH_PAIR.swap(a, 0, address(this), params);
    }
}
