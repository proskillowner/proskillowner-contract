// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ud2x18} from "@prb/math/src/UD2x18.sol";
import {ud60x18} from "@prb/math/src/UD60x18.sol";
import {ISablierV2LockupTranched} from "./interfaces/ISablierV2LockupTranched.sol";
import {Broker, LockupTranched, UserPlays} from "./types/DataTypes.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function skim(address to) external;

    function sync() external;
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

contract RunWayERC20 is IERC20, Ownable, ERC2771Context {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    address public fundAddress;
    address public managerAddress;
    address public lpManager;
    address public poolAddress;
    address public removeLPAddress;
    uint256 public MAX_SUPPLY = 2_100_0000 * 10 ** 18;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public fundFee = 30;

    address public mainPair;

    uint8 public constant maxWinnersCount = 20;
    uint256 public limitAmount = 1000 * 1e18;
    uint256 public lastTxTime = 0;
    uint256 public endLastTxTime = 1800;
    mapping(uint8 => address) public winners;
    uint8 public winnersCount = 0;

    uint256 public minUsd = 200;
    uint256 public ViaBalance = 0;

    ISablierV2LockupTranched public LOCKUP_DYNAMIC;

    mapping(address => bool) private _feeWhiteList;
    mapping(address => bool) private _poolWhiteList;
    mapping(address => bool) public _swapPairList;

    uint256 private constant MAX = ~uint256(0);

    ISwapRouter public _swapRouter;
    bool private inSwap;

    TokenDistributor public _tokenDistributor;
    address private usdt;

    uint256 public startTradeBlock;

    address DEAD = 0x000000000000000000000000000000000000dEaD;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {
        _name = "RunWay";
        _symbol = "BRC";
        _decimals = 18;

        if (block.chainid == 56) {
            _swapRouter = ISwapRouter(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            );
            usdt = address(0x55d398326f99059fF775485246999027B3197955);
        } else if (block.chainid == 97) {
            _swapRouter = ISwapRouter(
                0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            );
            usdt = address(0x0D6a3DAf7E9D1f2e9ec0a0ab81B3CAF039F6B097);
        }

        mainPair = ISwapFactory(_swapRouter.factory()).createPair(
            address(this),
            usdt
        );
        _allowances[address(this)][address(_swapRouter)] = MAX;
        IERC20(usdt).approve(address(_swapRouter), MAX);

        fundAddress = 0x774c65641d7169123FB3814124F53f2654Be84b0;
        _swapPairList[mainPair] = true;

        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[address(LOCKUP_DYNAMIC)] = true;

        _tokenDistributor = new TokenDistributor(usdt);
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setFundAddress(address payable addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    event AdditionalLogicExecuted(
        address sender,
        address recipient,
        uint256 amount,
        string text
    );

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= MAX_SUPPLY, "Exceeds maximum supply");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function launch() external onlyOwner {
        require(0 == startTradeBlock);
        startTradeBlock = block.number;
    }

    function stoplaunch() external onlyOwner {
        startTradeBlock = 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isAddLiquidity() internal view returns (bool isAdd) {
        ISwapPair mainPairs = ISwapPair(mainPair);
        (uint r0, uint256 r1, ) = mainPairs.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPairs));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        ISwapPair mainPairs = ISwapPair(mainPair);
        (uint r0, uint256 r1, ) = mainPairs.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPairs));
        isRemove = r >= bal;
    }

    function _executeAdditionalLogic(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        emit AdditionalLogicExecuted(
            msg.sender,
            recipient,
            amount,
            "_executeAdditionalLogic"
        );
        if (!_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            if (recipient == mainPair) {
                IERC20 USDT = IERC20(usdt);
                uint256 initialBalance = USDT.balanceOf(
                    address(_tokenDistributor)
                );
                USDT.transferFrom(
                    address(_tokenDistributor),
                    address(lpManager),
                    initialBalance
                );
            }
        }
    }

    event TriggerSwap(address indexed from, uint256 indexed amount);
    event isPool(bool isAdd, bool isRemove);

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        IERC20 USDT = IERC20(usdt);

        bool takeFee = false;
        bool isRemove;
        bool isAdd;
        bool isSell;

        if (to == mainPair) {
            isAdd = _isAddLiquidity();
        } else if (from == mainPair) {
            isRemove = _isRemoveLiquidity();
        }
        emit isPool(isAdd, isRemove);

        if (from == mainPair || to == mainPair) {
            if (0 == startTradeBlock) {
                require(
                    _feeWhiteList[from] || _feeWhiteList[to],
                    "Trade not start"
                );
            }

            if (from == mainPair && !isRemove) {
                emit TriggerSwap(msg.sender, amount);
                if (_totalSupply + amount <= MAX_SUPPLY) {
                    if (amount > 0) {
                        _mint(address(poolAddress), amount.div(2));
                    }
                }
                if (
                    USDT.balanceOf(address(this)) >= limitAmount &&
                    lastTxTime > 0 &&
                    winnersCount > 0
                ) {
                    execute();
                }
                if (amount >= minBuyAmountToWin()) {
                    addHolder(to);
                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
            }

            if (_swapPairList[to]) {
                isSell = true;
            }
        }
        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    event placesLog(uint8);

    function execute() private lockTheSwap {
        IERC20 USDT = IERC20(usdt);
        uint256 timeDiff = block.timestamp - lastTxTime;

        if (timeDiff >= endLastTxTime) {
            uint8 places = 20;
            if (places > winnersCount) places = winnersCount;
            uint256[] memory prizesArray = calculatePrizes(places);
            emit placesLog(places);
            for (uint8 i = 0; i < places; i++) {
                if (winners[i] != address(0) && prizesArray[i] > 0) {
                    bool success = USDT.transfer(winners[i], prizesArray[i]);
                    require(success, "Transfer failed");
                }
            }
            winnersCount = 0;
        }
    }

    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
        if (size > 0) {
            return;
        }

        lastTxTime = block.timestamp;
        winnersCount = winnersCount < maxWinnersCount
            ? winnersCount + 1
            : maxWinnersCount;
        for (uint8 i = winnersCount - 1; i >= 1; i--) {
            winners[i] = winners[i - 1];
        }
        winners[0] = payable(adr);
    }

    event tokenTransferLog(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    );
    event AutoNukeLP();

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        emit tokenTransferLog(sender, recipient, tAmount, takeFee);
        uint256 feeAmount;
        if (takeFee) {
            if (isSell) {
                uint256 circular = (tAmount * fundFee) / 100;
                feeAmount = circular;
                _takeTransfer(sender, address(this), feeAmount);

                uint256 lpBurnFrequency = tAmount - feeAmount;

                swapTokenForFund(circular);

                autoBurnLiquidity(lpBurnFrequency);

                _executeAdditionalLogic(sender, recipient, tAmount);

                emit AutoNukeLP();
            }
        }

        tAmount = tAmount - feeAmount;
        _takeTransfer(sender, recipient, tAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        IERC20 USDT = IERC20(usdt);
        uint256 initialBalance = USDT.balanceOf(address(_tokenDistributor));

        swapTokensForUsdt(tokenAmount);

        uint256 newBalance = ((USDT.balanceOf(address(_tokenDistributor)) -
            initialBalance) * 1667) / 10000;

        USDT.transferFrom(
            address(_tokenDistributor),
            address(this),
            newBalance
        );
    }

    event LiquidityBurned(address indexed pair, uint256 amount);

    function autoBurnLiquidity(uint256 amount) private {
        uint256 liquidityPairBalance = balanceOf(mainPair);
        if (liquidityPairBalance < amount) {
            return;
        }

        if (amount > 0) {
            _basicTransfer(mainPair, address(DEAD), amount);

            ISwapPair pair = ISwapPair(mainPair);
            pair.sync();
            emit LiquidityBurned(mainPair, amount);
            return;
        }
    }

    function swapTokensForUsdt(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function isFeeWhiteList(address addr) external view returns (bool) {
        return _feeWhiteList[addr];
    }

    function isPoolWhiteList(address addr) external view returns (bool) {
        return _poolWhiteList[addr];
    }

    receive() external payable {}

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setPooWhiteList(address addr, bool enable) external onlyOwner {
        _poolWhiteList[addr] = enable;
    }

    function setPoolAddress(address addr) external onlyOwner {
        poolAddress = address(addr);
        _feeWhiteList[addr] = true;
    }

    function setManagerAddress(address addr) external onlyOwner {
        managerAddress = address(addr);
        _feeWhiteList[addr] = true;
    }

    function setLpManagerAddress(address addr) external onlyOwner {
        lpManager = address(addr);
        _feeWhiteList[addr] = true;
    }

    function setFundFee(uint256 amount) external onlyOwner {
        fundFee = amount;
    }

    function setRemoveLPAddress(address addr) external onlyOwner {
        removeLPAddress = address(addr);
    }

    function setLockup_Dynamic(address addr) external onlyOwner {
        LOCKUP_DYNAMIC = ISablierV2LockupTranched(addr);
        _feeWhiteList[addr] = true;
    }

    event PriceLog(uint256 amount);

    event LpAmount(uint amount0, uint amount1);
    event LogTrustedForwarder(address _msgSender);

    function createStream(
        uint128 amount,
        uint256 TokenId,
        uint256 inviter
    ) external {
        require(amount > 0, "Transfer amount must be greater than zero");

        emit LogTrustedForwarder(_msgSender());

        IERC20 USDT = IERC20(usdt);

        USDT.transferFrom(msg.sender, address(this), amount);
        (uint256 reserveA, uint256 reserveB, address token) = __getReserves();

        if (_poolWhiteList[_msgSender()]) {
            uint256 minAmount;
            uint256 usdtAmount = amount;
            if (reserveA <= 0 || reserveB <= 0) {
                minAmount = usdtAmount.mul(20);
            } else {
                uint256 currentPrice = uint256(reserveA).mul(1e18).div(
                    uint256(reserveB)
                );
                emit PriceLog(currentPrice);
                minAmount = usdtAmount.mul(1e18).div(currentPrice);
            }
            _mint(address(this), minAmount);

            uint256 runWayAmount = minAmount;

            uint256 liquidity = _addLiquidity(runWayAmount, usdtAmount);
        } else {
            uint256 totalAmount = (amount * 40) / 100;
            uint256 usdtAmount = totalAmount / 2;
            uint256 upPairAmount = (amount * 5) / 100;
            uint256 minAmount;

            emit LpAmount(reserveA, reserveB);
            emit PriceLog(totalAmount);

            if (reserveA <= 0 || reserveB <= 0) {
                minAmount = usdtAmount.mul(10);
            } else {
                uint256 currentPrice = uint256(reserveA).mul(1e18).div(
                    uint256(reserveB)
                );
                emit PriceLog(currentPrice);
                minAmount = usdtAmount.mul(1e18).div(currentPrice);
            }
            emit PriceLog(minAmount);
            _mint(address(this), minAmount);

            uint256 runWayAmount = minAmount;

            uint256 liquidity = _addLiquidity(runWayAmount, usdtAmount);

            USDT.approve(address(this), amount);

            USDT.transfer(address(mainPair), upPairAmount);
            ISwapPair(mainPair).sync();

            USDT.transferFrom(address(this), address(fundAddress), usdtAmount);

            emit PriceLog(upPairAmount);
            emit PriceLog(liquidity);

            USDT.approve(address(LOCKUP_DYNAMIC), amount);

            uint256 poolAmount = amount - totalAmount - upPairAmount;

            uint256 deposited = amount - totalAmount;

            LockupTranched.CreateLimitDeltas memory params;

            if (TokenId != 0) {
                params.sender = _msgSender();
                params.recipient = address(_msgSender());
                params.balance = deposited.mul(2);
                params.amount = 0;
                params.lptoken = liquidity;
                params.deposited = amount;
                params.referredBy = inviter;
                params.asset = USDT;
                params.poolAmount = poolAmount;
                LOCKUP_DYNAMIC.depositedLimitDeltas(params, TokenId);
            } else {
                params.sender = _msgSender();
                params.recipient = address(_msgSender());
                params.balance = deposited.mul(2);
                params.amount = 0;
                params.lptoken = liquidity;
                params.deposited = amount;
                params.referredBy = inviter;
                params.asset = USDT;
                params.poolAmount = poolAmount;
                LOCKUP_DYNAMIC.createLimitDeltas(params);
            }
        }
    }

    function updatePrice() public view returns (uint256 currentPrice) {
        (uint reserveA, uint reserveB, address token) = __getReserves();
        currentPrice = uint256(reserveA).mul(1e18).div(uint256(reserveB));
    }

    function __getReserves()
        public
        view
        returns (uint256 rOther, uint256 rThis, address token)
    {
        ISwapPair mainPairs = ISwapPair(mainPair);
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = mainPairs.getReserves();
        address token0 = mainPairs.token0();
        if (token0 == address(usdt)) {
            rOther = reserve0;
            rThis = reserve1;
        } else {
            rOther = reserve1;
            rThis = reserve0;
        }
        token = token0;
    }

    event LiquidityAddedLog(
        uint256 runWayAmount,
        uint256 usdtAmount,
        uint256 liquidity
    );

    function _addLiquidity(
        uint256 runWayAmount,
        uint256 usdtAmount
    ) private returns (uint256) {
        (uint256 amountA, uint256 amountB, uint256 liquidity) = _swapRouter
            .addLiquidity(
                address(this),
                address(usdt),
                runWayAmount,
                usdtAmount,
                0,
                0,
                removeLPAddress,
                block.timestamp
            );

        emit LiquidityAddedLog(amountA, amountB, liquidity);

        return liquidity;
    }

    function setLimitAmount(uint256 amount) public onlyOwner {
        limitAmount = amount;
    }

    function setMinUsd(uint256 amount) public onlyOwner {
        minUsd = amount;
    }

    function setEndlastTime(uint256 time) public onlyOwner {
        endLastTxTime = time;
    }

    function calculatePrizes(
        uint8 places
    ) private view returns (uint256[] memory) {
        require(places > 0, "at least one winner is required");
        require(places <= maxWinnersCount, "too many winners");
        IERC20 USDT = IERC20(usdt);

        uint256[] memory prizes = new uint256[](places);

        uint256 initBalance = USDT.balanceOf(address(this));

        if (initBalance >= limitAmount) {
            uint256 avgPrize = limitAmount / maxWinnersCount;
            for (uint8 i = 0; i < places; i++) {
                prizes[i] = avgPrize;
            }
        }
        return prizes;
    }

    function minBuyAmountToWin() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(this);
        return _swapRouter.getAmountsOut(minUsd * (1 ether), path)[1];
    }

    function ToWins() public view returns (uint256[] memory) {
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(this);
        return _swapRouter.getAmountsOut(minUsd * (1 ether), path);
    }

    function claimBalance() external {
        require(managerAddress == msg.sender, "!Funder");
        payable(managerAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external {
        require(managerAddress == msg.sender, "!Funder");
        IERC20(token).transfer(to, amount);
    }
}
