//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";

contract Bot is Ownable {
    IUniswapV2Router private constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    ERC20 private constant USDT_SG_PAIR = ERC20(0x65A9c67EABE166a2D08fC8035435DcF31b5ae41A);

    ERC20 private constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 private constant SG = ERC20(0xa28dB960e32833f582bA5F6338880bf239f2a966);

    address public adder;
    address public remover;

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function renounceOwnership() public virtual override onlyOwner {
        revert();
    }

    function withdrawERC20(address erc20, address to) public onlyOwner {
        IERC20(erc20).transfer(to, IERC20(erc20).balanceOf(address(this)));
    }

    function withdrawETH(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    function setAdder(address _adder) public onlyOwner {
        adder = _adder;
    }

    function setRemover(address _remover) public onlyOwner {
        remover = _remover;
    }

    function approve() public onlyOwner {
        USDT.approve(address(UNISWAP_ROUTER), type(uint256).max);
        SG.approve(address(UNISWAP_ROUTER), type(uint256).max);
        USDT_SG_PAIR.approve(address(UNISWAP_ROUTER), type(uint256).max);
    }

    function buy(uint256 amount) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(SG);
        UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount, 0, path, address(this), block.timestamp
        );
    }

    function sell(uint256 amount) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(SG);
        path[1] = address(USDT);
        UNISWAP_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount, 0, path, address(this), block.timestamp
        );
    }

    function addLiquidity() public {
        require(msg.sender == adder);
        UNISWAP_ROUTER.addLiquidity(
            address(USDT),
            address(SG),
            USDT.balanceOf(address(this)),
            SG.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function removeLiquidity() public {
        require(msg.sender == remover);
        UNISWAP_ROUTER.removeLiquidity(
            address(USDT), address(SG), USDT_SG_PAIR.balanceOf(address(this)), 0, 0, address(this), block.timestamp
        );
    }
}
