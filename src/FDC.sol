//SPDX-License-Identifier: None
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";

//   Logic => 0xe74a63325801eA977597e50B589BaFB809a36eF4
//   Proxy => 0x812b332937ea5Fb29FDa79aFFc17345CF736C107
//   ProxyAdmin => 0x7B55616B7aF4012D4cb45cb9a064894eDD0223DE

contract Bot is OwnableUpgradeable {
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

    function function1() public {
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

    function function2() public {
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
