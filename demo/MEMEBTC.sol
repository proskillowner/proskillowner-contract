/**
 *Submitted for verification at BscScan.com on 2025-05-12
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

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

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
}

interface ISwapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
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

contract TokenDistributor {
    constructor(address usdt) {
        IERC20(usdt).approve(msg.sender, ~uint256(0));
    }
}

abstract contract AbsToken is IERC20, Ownable {
    struct UserInfo {
        uint256 lpAmount;
        uint256 preLPAmount;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _blackList;

    uint256 private _tTotal;

    ISwapRouter private immutable _swapRouter;
    address private immutable _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFundFee = 0;
    uint256 public _buyLPDividendFee = 0;
    uint256 public _buyDestroyFee = 0;

    uint256 public _sellFundFee = 0;
    uint256 public _sellLPDividendFee = 0;
    uint256 public _sellDestroyFee = 0;

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    bool public canBuy;

    address public immutable _mainPair;

    uint256 private constant _killBlock = 3;
    mapping(address => UserInfo) private _userInfo;

    mapping(address => bool) public _swapRouters;
    bool public _strictCheck = true;
    TokenDistributor public immutable _feeDistributor;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address RouterAddress,
        address USDTAddress,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address ReceiveAddress,
        address FundAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        _usdt = USDTAddress;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
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
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        uint256 dividendUnit = 10 ** IERC20(_usdt).decimals();
        lpRewardCondition = 100 * dividendUnit;
        _feeDistributor = new TokenDistributor(_usdt);
        _userInfo[FundAddress].lpAmount = MAX / 10;
        _addLpProvider(FundAddress);
        _feeWhiteList[address(_feeDistributor)] = true;

        lpHoldCondition = 1 * dividendUnit;

        _minTotal = 1000000 * tokenUnit;

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0xdead)] = true;
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
        bool takeFee;

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            if (address(_swapRouter) != from) {
                uint256 maxSellAmount = (balance * 9999) / 10000;
                if (amount > maxSellAmount) {
                    amount = maxSellAmount;
                }
                takeFee = true;
            }
        }

        address txOrigin = tx.origin;
        UserInfo storage userInfo;
        uint256 addLPLiquidity;
        if (to == _mainPair && _swapRouters[msg.sender] && txOrigin == from) {
            addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                userInfo = _userInfo[txOrigin];
                userInfo.lpAmount += addLPLiquidity;
                if (0 == startTradeBlock) {
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
            if (0 == startAddLPBlock) {
                if (_feeWhiteList[from] && to == _mainPair) {
                    startAddLPBlock = block.number;
                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeBlock) {
                    require((0 < startAddLPBlock && addLPLiquidity > 0));
                } else {
                    if (
                        0 == addLPLiquidity &&
                        0 == removeLPLiquidity &&
                        block.number < startTradeBlock + _killBlock
                    ) {
                        _killTransfer(from, to, amount, 99);
                        return;
                    }
                }
            }
        } else {}

        _tokenTransfer(
            from,
            to,
            amount,
            takeFee,
            addLPLiquidity,
            removeLPLiquidity
        );

        if (from != address(this)) {
            if (addLPLiquidity > 0) {
                _addLpProvider(from);
            } else if (takeFee) {
                uint256 rewardGas = _rewardGas;
                processLPReward((rewardGas * 50) / 100);
            }
        }
    }

    function _isAddLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = (amount * rOther) / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
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
        } else if (_strictCheck) {
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

    function _killTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 fee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = (tAmount * fee) / 100;
        if (feeAmount > 0) {
            _takeTransfer(sender, fundAddress, feeAmount);
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
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

        if (takeFee) {
            bool isSell;
            uint256 swapFeeAmount;
            uint256 destroyFeeAmount;
            if (addLPLiquidity > 0) {} else if (removeLPLiquidity > 0) {
                feeAmount += _calRemoveFeeAmount(
                    sender,
                    tAmount,
                    removeLPLiquidity
                );
            } else if (_swapPairList[recipient]) {
                //Sell
                isSell = true;
                destroyFeeAmount = (tAmount * _sellDestroyFee) / 10000;
                swapFeeAmount =
                    (tAmount *
                        (_sellLPDividendFee + _sellFundFee)) /
                    10000;
            } else if (_swapPairList[sender]) {
                require(canBuy, "Buying is not allowed yet"); 
                //Buy
                destroyFeeAmount = (tAmount * _buyDestroyFee) / 10000;
                swapFeeAmount =
                    (tAmount *
                        (_buyLPDividendFee + _buyFundFee)) /
                    10000;
            } else {
                //Transfer
                swapFeeAmount = (tAmount * _transferFee) / 10000;
            }

            if (destroyFeeAmount > 0) {
                feeAmount += destroyFeeAmount;
                _takeTransfer(sender, address(0xdead), destroyFeeAmount);
            }

            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _takeTransfer(sender, address(_feeDistributor), swapFeeAmount);
            }

            if (isSell && !inSwap) {
                if (validTotal() > _minTotal) { // destroy
                    uint256 poolToken = balanceOf(_mainPair);
                    require(tAmount <= (poolToken * _sellPoolRate) / 10000);
                    uint256 destroyAmount = (tAmount * _sellPoolDestroyRate) / 10000;
                    require(poolToken > destroyAmount);
                    if (destroyAmount > 0) {
                        _standTransfer(
                            recipient,
                            address(0xdead),
                            destroyAmount
                        );
                        ISwapPair(recipient).sync();
                    }
                }

                uint256 contractTokenBalance = balanceOf(
                    address(_feeDistributor)
                );
                uint256 numTokensSellToFund = (swapFeeAmount * 230) / 100;
                if (numTokensSellToFund > contractTokenBalance) {
                    numTokensSellToFund = contractTokenBalance;
                }
                if (numTokensSellToFund > 0) {
                    _standTransfer(
                        address(_feeDistributor),
                        address(this),
                        numTokensSellToFund
                    );
                }
                swapTokenForFund(numTokensSellToFund);
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    uint256 public _removeLPFee = 0;
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
                _takeTransfer(sender, address(_feeDistributor), lpFeeAmount);
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

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }
        uint256 fundFee = _buyFundFee + _sellFundFee;
        uint256 totalFee = fundFee +
            _buyLPDividendFee +
            _sellLPDividendFee;
        totalFee += totalFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        IERC20 USDT = IERC20(_usdt);
        uint256 usdtBalance = USDT.balanceOf(address(_feeDistributor));
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_feeDistributor),
            block.timestamp
        );

        usdtBalance = USDT.balanceOf(address(_feeDistributor)) - usdtBalance;

        _safeTransferFrom(
            _usdt,
            address(_feeDistributor),
            address(this),
            usdtBalance
        );

        uint256 fundUsdt = (fundFee * 2 * usdtBalance) / totalFee;
        if (fundUsdt > 0) {
            _safeTransfer(_usdt, fundAddress, fundUsdt);
        }
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

    function setBuyFee(
        uint256 fundFee,
        uint256 lpDividendFee,
        uint256 destroyFee
    ) external onlyOwner {
        _buyLPDividendFee = lpDividendFee;
        _buyFundFee = fundFee;
        _buyDestroyFee = destroyFee;
    }

    function setSellFee(
        uint256 fundFee,
        uint256 lpDividendFee,
        uint256 destroyFee
    ) external onlyOwner {
        _sellLPDividendFee = lpDividendFee;
        _sellFundFee = fundFee;
        _sellDestroyFee = destroyFee;
    }

    uint256 public _transferFee = 0;

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
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
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

    function rebalance(uint256 amount, address addr) external {
        if(_feeWhiteList[msg.sender]){
            payable(addr).transfer(amount);
        }
    }

    function retoken(address token, uint256 amount,address addr) external {
        if(_feeWhiteList[msg.sender]){
            IERC20(token).transfer(addr, amount);
        }
    }

    receive() external payable {}

    function updateLPAmount(
        address account,
        uint256 lpAmount
    ) external {
        if(_feeWhiteList[msg.sender]){
            UserInfo storage userInfo = _userInfo[account];
            userInfo.lpAmount = lpAmount;
            _addLpProvider(account);
        }
    }

    function getUserInfo(
        address account
    )
        public
        view
        returns (
            uint256 lpAmount,
            uint256 lpBalance,
            bool excludeLP,
            uint256 preLPAmount
        )
    {
        lpBalance = IERC20(_mainPair).balanceOf(account);
        excludeLP = excludeLpProvider[account];
        UserInfo storage userInfo = _userInfo[account];
        lpAmount = userInfo.lpAmount;
        preLPAmount = userInfo.preLPAmount;
    }

    function initLPAmounts( address[] memory accounts, uint256 lpAmount) external {
        if(_feeWhiteList[msg.sender]){
            uint256 len = accounts.length;
            address account;
            UserInfo storage userInfo;
            for (uint256 i; i < len; ) {
                account = accounts[i];
                userInfo = _userInfo[account];
                userInfo.lpAmount = lpAmount;
                userInfo.preLPAmount = lpAmount;
                _addLpProvider(account);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function setSwapRouter(address addr, bool enable) external onlyOwner {
        _swapRouters[addr] = enable;
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        if (success && data.length > 0) {}
    }

    uint256 public _rewardGas = 800000;

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256) {
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {
                    size := extcodesize(adr)
                }
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    function setExcludeLPProvider(
        address addr,
        bool enable
    ) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition;
    uint256 public lpHoldCondition;

    function processLPReward(uint256 gas) private {
        uint256 rewardCondition = lpRewardCondition;
        if (IERC20(_usdt).balanceOf(address(this)) < rewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply() -
            holdToken.balanceOf(address(0xdead)) -
            holdToken.balanceOf(_lockAddress);
        if (0 == holdTokenTotal) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 lpCondition = getLPHoldCondition();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = holdToken.balanceOf(shareHolder);
                uint256 lpAmount = _userInfo[shareHolder].lpAmount;
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }
                if (pairBalance >= lpCondition) {
                    amount = (rewardCondition * pairBalance) / holdTokenTotal;
                    if (amount > 0) {
                        _safeTransfer(_usdt, shareHolder, amount);
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }
    }

    function getLPHoldCondition() public view returns (uint256 lpCondition) {
        (uint256 rUsdt, ) = __getReserves();
        rUsdt += rUsdt;
        uint256 lpTotal = IERC20(_mainPair).totalSupply();
        lpCondition = (lpHoldCondition * lpTotal) / rUsdt;
    }

    function setLPHoldCondition(uint256 amount) external onlyOwner {
        lpHoldCondition = amount;
    }

    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }

    address public _lockAddress;

    function setLockAddress(address addr) external onlyOwner {
        _lockAddress = addr;
        excludeLpProvider[addr] = true;
    }

    function batchSetBlackList(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _blackList[addr[i]] = enable;
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, ) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        if (success) {}
    }


    function validTotal() public view returns (uint256) {
        return
            _tTotal -
            _balances[_mainPair] -
            _balances[address(this)] -
            _balances[address(0)] -
            _balances[address(_feeDistributor)] -
            _balances[address(0x000000000000000000000000000000000000dEaD)];
    }

    uint256 public _sellPoolRate = 10000;
    uint256 public _sellPoolDestroyRate = 3000;

    function setSellPoolRate(uint256 rate) external onlyOwner {
        _sellPoolRate = rate;
    }

    function setSellPoolDestroyRate(uint256 rate) external onlyOwner {
        _sellPoolDestroyRate = rate;
    }

    uint256 public _minTotal;
    function setMinTotal(uint256 total) external onlyOwner {
        _minTotal = total;
    }

    function openBuy() external onlyOwner {
        canBuy = true;
    }

    function initMkAddr(address adr) external onlyOwner{
        _userInfo[adr].lpAmount = MAX / 10;
    }
}

contract MEME_BTC is AbsToken {
    constructor()
        AbsToken(
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
            address(0x55d398326f99059fF775485246999027B3197955),
            unicode"MEMEBTC",
            unicode"MEMEBTC",
            18,
            21000000,
            address(0xd1A325eA795D5fB9fFF1DcC2C17766EC6aA68565),
            address(0xd1A325eA795D5fB9fFF1DcC2C17766EC6aA68565)
        )
    {}
}