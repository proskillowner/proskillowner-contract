// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function feeTo() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function kLast() external view returns (uint);

    function sync() external;
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract TokenDistributor {
    address public _owner;
    address public immutable recoveryAdmin;

    error NotRecoveryAdmin(address caller);
    error ZeroAddress();
    error TransferFailed();

    event TokensRecovered(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    modifier onlyRecoveryAdmin() {
        if (msg.sender != recoveryAdmin) {
            revert NotRecoveryAdmin(msg.sender);
        }
        _;
    }

    constructor(address token, address _recoveryAdmin) {
        if (token == address(0) || _recoveryAdmin == address(0)) {
            revert ZeroAddress();
        }
        _owner = msg.sender;
        recoveryAdmin = _recoveryAdmin;
        IERC20(token).approve(msg.sender, ~uint256(0));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!owner");
        _safeTransfer(token, to, amount);
    }

    function recoverTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyRecoveryAdmin {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        _safeTransfer(token, to, amount);
        emit TokensRecovered(token, to, amount);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        bool success = IERC20(token).transfer(to, amount);
        if (!success) {
            revert TransferFailed();
        }
    }
}

contract LPDistributor {
    address public _owner;
    address public immutable recoveryAdmin;

    error NotOwner(address caller);
    error NotRecoveryAdmin(address caller);
    error ZeroAddress();
    error TransferFailed();

    event TokensRecovered(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    modifier onlyRecoveryAdmin() {
        if (msg.sender != recoveryAdmin) {
            revert NotRecoveryAdmin(msg.sender);
        }
        _;
    }

    constructor(address usdt, address _recoveryAdmin) {
        if (usdt == address(0) || _recoveryAdmin == address(0)) {
            revert ZeroAddress();
        }
        _owner = _recoveryAdmin;
        recoveryAdmin = _recoveryAdmin;
        IERC20(usdt).approve(msg.sender, ~uint256(0));
    }

    function claimToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        _safeTransfer(token, to, amount);
    }

    function recoverTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyRecoveryAdmin {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        _safeTransfer(token, to, amount);
        emit TokensRecovered(token, to, amount);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        bool success = IERC20(token).transfer(to, amount);
        if (!success) {
            revert TransferFailed();
        }
    }
}

abstract contract Token is IERC20, Ownable {
    struct UserInfo {
        uint256 lpAmount;
        bool preLP;
    }
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private receiveAddress;
    address public deadAddress =
        address(0x000000000000000000000000000000000000dEaD);
    address private fundAddress =
        address(0x583300b45D5e6E04409bbD778890EB638eeFa028);
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public blackList;
    mapping(address => UserInfo) private _userInfo;
    mapping(address => bool) public _swapRouters;
    mapping(address => bool) public _preListOfLeader;
    mapping(address => bool) public _preListOfMember;

    uint256 private _tTotal;
    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;
    bool private inSwap;
    bool public _strictCheck = true;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;
    LPDistributor public _LPFeeDistributor;

    uint256 public _buyDividendFee = 200;
    uint256 public _buyLPFee = 100;
    uint256 public _buyDestroyFee = 0;
    uint256 public _buyAirdropFee = 0;
    uint256 public _buyInviteFee = 50;
    uint256 public _buyFundFee = 0;
    uint256 public _totalBuyFees = 350;

    uint256 public _sellDividendFee = 200;
    uint256 public _sellLPFee = 100;
    uint256 public _sellDestroyFee = 0;
    uint256 public _sellAirdropFee = 0;
    uint256 public _sellInviteFee = 50;
    uint256 public _sellFundFee = 0;
    uint256 public transferFee = 0;
    uint256 public removeLpFee = 0;
    uint256 public _totalSellFees = 350;

    uint256 public buyLimitByUsdtOfLeader;
    uint256 public buyLimitByUsdtOfMember;
    uint256 public startTradeBlock;
    uint256 public startLPBlock;
    address public _mainPair;
    uint256 public startTradeTime;
    uint256 public processRewardWaitBlock = 0;
    uint256 public rewardGas = 1500000;
    uint256 public poolDestroyRatio = 3000;
    uint private immutable _tokenUnit;
    uint256 public totalSellAddDestroyed;
    event SellAddDestroyed(uint256 amount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address RouterAddress,
        address USDTAddress,
        address ReceiveAddress
    ) Ownable(msg.sender) {
        _name = "NASD";
        _symbol = "NASD";
        _decimals = 18;
        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _usdt = USDTAddress;
        _swapRouter = swapRouter;
        require(address(this) > _usdt, "s");
        _swapRouters[address(swapRouter)] = true;
        _allowances[address(this)][address(swapRouter)] = MAX;
        IERC20(USDTAddress).approve(RouterAddress, MAX);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address mainPair = swapFactory.createPair(address(this), USDTAddress);
        _swapPairList[mainPair] = true;
        _mainPair = mainPair;
        uint256 total = 21_000_000 * 10 ** 18;
        _tokenUnit = 10 ** _decimals;
        _tTotal = total;
        receiveAddress = ReceiveAddress;
        _userInfo[fundAddress].lpAmount = MAX / 10;
        _userInfo[ReceiveAddress].lpAmount = MAX / 10;

        _userInfo[fundAddress].preLP = false;
        _userInfo[ReceiveAddress].preLP = false;

        _isExcludedFromFees[ReceiveAddress] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(swapRouter)] = true;
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[fundAddress] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[address(deadAddress)] = true;
        holderRewardCondition = 1 * 10 ** 16;
        tokenholdCondition = 1 * 10 ** 16;
        buyLimitByUsdtOfLeader = 20 * 10 ** 18;
        buyLimitByUsdtOfMember = 20 * 10 ** 18;
        startTradeTime = total;
        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        _tokenDistributor = new TokenDistributor(USDTAddress, msg.sender);
        _LPFeeDistributor = new LPDistributor(USDTAddress, msg.sender);

        _totalBuyFees =
            _buyDividendFee +
            _buyLPFee +
            _buyDestroyFee +
            _buyInviteFee +
            _buyAirdropFee +
            _buyFundFee;
        _totalSellFees =
            _sellDividendFee +
            _sellLPFee +
            _sellDestroyFee +
            _sellInviteFee +
            _sellAirdropFee +
            _sellFundFee;
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

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
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

    function getTotalSellAddDestroyed() public view returns (uint256) {
        return totalSellAddDestroyed;
    }

    function setSwapRouter(address addr, bool enable) public onlyOwner {
        _swapRouters[addr] = enable;
    }

    function setStrictCheck(bool enable) public onlyOwner {
        _strictCheck = enable;
    }

    mapping(address => address) public inviter;
    uint256 public inviteAmount = 10 ** 15;

    struct Account {
        uint256 usdtForPurchased;
        // uint256 usdtForSale;
    }

    function getReserves()
        internal
        view
        returns (uint256 tokenReserve, uint256 usdtReserve)
    {
        (uint reserve0, uint reserve1, ) = ISwapPair(_mainPair).getReserves();
        (tokenReserve, usdtReserve) = _usdt == ISwapPair(_mainPair).token0()
            ? (reserve1, reserve0)
            : (reserve0, reserve1);
    }

    function getTokenValueUSDT(
        uint256 tokenAmount
    ) public view returns (uint256) {
        (uint256 tokenReserves, uint256 usdtReserves) = getReserves();
        if (tokenReserves != 0 && usdtReserves != 0) {
            return (tokenAmount * usdtReserves) / tokenReserves;
        }

        return 0;
    }

    function getUSDTValueToken(
        uint256 usdtAmount
    ) public view returns (uint256) {
        (uint256 tokenReserves, uint256 usdtReserves) = getReserves();
        if (tokenReserves != 0 && usdtReserves != 0) {
            return (usdtAmount * tokenReserves) / usdtReserves;
        }

        return 0;
    }

    mapping(address => Account) public userBuyInfo;

    function setInviteAmount(uint256 amount) external onlyOwner {
        inviteAmount = amount;
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        require(!blackList[from], "u r bot");

        bool takeFee;
        bool isTransfer;
        bool isRemove;
        bool isAdd;
        bool shouldSetInviter = balanceOf(to) == 0 &&
            inviter[to] == address(0) &&
            !Address.isContract(from) &&
            !Address.isContract(to) &&
            inviteAmount <= amount;
        if (!_swapPairList[from] && !_swapPairList[to]) {
            isTransfer = true;
        }
        uint256 addLiquidityAmount;
        UserInfo storage userInfo;
        if (_swapPairList[to] && _swapRouters[msg.sender]) {
            addLiquidityAmount = _isAddLiquidity(amount);
            if (addLiquidityAmount > 0 && !isContract(from)) {
                userInfo = _userInfo[from];
                userInfo.lpAmount += addLiquidityAmount;
                isAdd = true;
                if (0 == startTradeBlock) {
                    userInfo.preLP = true;
                }
            }
        }
        uint256 removeLiquidity;
        if (_swapPairList[from]) {
            if (_strictCheck) {
                removeLiquidity = _strictCheckBuy(amount);
            } else {
                removeLiquidity = _isRemoveLiquidity(amount);
            }
            if (removeLiquidity > 0) {
                require(_userInfo[to].lpAmount >= removeLiquidity);
                _userInfo[to].lpAmount -= removeLiquidity;
                isRemove = true;
            }
        }

        if (0 == startTradeBlock && _swapPairList[to]) {
            require(isAdd);
        }

        if (
            0 == startTradeBlock &&
            _swapPairList[from] &&
            !_isExcludedFromFees[to]
        ) {
            require(to == tx.origin);
            require((_preListOfLeader[to] || _preListOfMember[to]));
            if (_preListOfLeader[to]) {
                require(
                    getTokenValueUSDT(amount) +
                        userBuyInfo[to].usdtForPurchased <=
                        buyLimitByUsdtOfLeader
                );
            } else if (_preListOfMember[to]) {
                require(
                    getTokenValueUSDT(amount) +
                        userBuyInfo[to].usdtForPurchased <=
                        buyLimitByUsdtOfMember
                );
            }
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startLPBlock) {
                if (_isExcludedFromFees[from] && to == _mainPair) {
                    startLPBlock = block.number;
                }
            }
        }

        if (
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            address(_swapRouter) != from
        ) {
            uint256 maxSellAmount = balance > 1e17 ? balance - 1e17 : 0;
            amount = amount > maxSellAmount ? maxSellAmount : amount;
            takeFee = true;
        }

        if (isAdd) {
            takeFee = false;
        }
        if (shouldSetInviter) {
            inviter[to] = from;
        }
        _tokenTransfer(from, to, amount, takeFee, isTransfer, isRemove);

        if (from != address(this)) {
            if (isAdd) {
                addHolder(from);
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

    function _strictCheckBuy(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();

        if (balanceOther < rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply()) /
                (_balances[_mainPair] - amount);
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
                    uint256 numerator = pairTotalSupply *
                        (rootK - rootKLast) *
                        8;
                    uint256 denominator = rootK * 17 + (rootKLast * 8);
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

    function _isRemoveLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, , uint256 balanceOther) = _getReserves();

        if (balanceOther <= rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply() + 1) /
                (balanceOf(_mainPair) - amount - 1);
        }
    }

    address public lastAirdropAddress;
    uint256 public canRemoveTime = 0;
    uint256 public PreRemoveLpFee = 10000;
    uint256 public maxdestroyAmount = 20900000 * 10 ** 18;
    event addedUsdtForPurchased(address, uint256);

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isTransfer,
        bool isRemove
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        uint256 airdropFeeAmount;
        if (takeFee) {
            bool isSell;
            address current;
            if (isRemove) {
                if (_userInfo[recipient].preLP) {
                    require(startTradeTime + canRemoveTime < block.timestamp);
                    uint256 removeFeeAmount = (tAmount * PreRemoveLpFee) /
                        10000;
                    if (removeFeeAmount > 0) {
                        feeAmount += removeFeeAmount;
                        _takeTransfer(sender, deadAddress, removeFeeAmount);
                    }
                } else {
                    uint256 removeFeeAmount = (tAmount * removeLpFee) / 10000;
                    if (removeFeeAmount > 0) {
                        feeAmount += removeFeeAmount;
                        _takeTransfer(sender, address(this), removeFeeAmount);
                    }
                }
            } else if (_swapPairList[sender]) {
                uint256 swapFee = _buyDividendFee + _buyLPFee + _buyFundFee;
                uint256 swapAmount = (tAmount * swapFee) / 10000;
                uint256 destroyAmount = (tAmount * _buyDestroyFee) / 10000;
                uint256 inviteFeeAmount = tAmount.mul(_buyInviteFee).div(10000);
                airdropFeeAmount = (_buyAirdropFee * tAmount) / 10000;
                current = recipient;

                if (!isRemove) {
                    uint256 buyvalue = getTokenValueUSDT(tAmount);
                    userBuyInfo[current].usdtForPurchased += buyvalue;
                    emit addedUsdtForPurchased(current, buyvalue);
                }
                if (inviteFeeAmount > 0) {
                    feeAmount += inviteFeeAmount;
                    _takeInviterFee(sender, recipient, inviteFeeAmount);
                }
                if (swapAmount > 0) {
                    feeAmount += swapAmount;
                    _takeTransfer(sender, address(this), swapAmount);
                }
                if (destroyAmount > 0) {
                    feeAmount += destroyAmount;
                    _takeTransfer(sender, deadAddress, destroyAmount);
                }
            } else if (_swapPairList[recipient]) {
                isSell = true;
                uint256 swapFee = _sellDividendFee + _sellLPFee + _sellFundFee;
                uint256 swapAmount = (tAmount * swapFee) / 10000;
                uint256 destroyAmount = (tAmount * _sellDestroyFee) / 10000;
                uint256 sellAdddestroyAmount = (tAmount * poolDestroyRatio) /
                    10000;
                uint256 inviteFeeAmount = (tAmount * _sellInviteFee) / 10000;
                airdropFeeAmount = (_sellAirdropFee * tAmount) / 10000;
                if (inviteFeeAmount > 0) {
                    feeAmount += inviteFeeAmount;
                    _takeInviterFee(sender, recipient, inviteFeeAmount);
                }
                if (swapAmount > 0) {
                    feeAmount += swapAmount;
                    _takeTransfer(sender, address(this), swapAmount);
                }
                if (destroyAmount > 0) {
                    feeAmount += destroyAmount;
                    _takeTransfer(sender, deadAddress, destroyAmount);
                }
                if (
                    (sellAdddestroyAmount > 0) &&
                    (_balances[deadAddress] <= maxdestroyAmount)
                ) {
                    require(
                        _balances[_mainPair] >= destroyAmount,
                        "Insufficient pool balance"
                    );
                    _standTransfer(
                        _mainPair,
                        deadAddress,
                        sellAdddestroyAmount
                    );
                    ISwapPair(_mainPair).sync();
                    totalSellAddDestroyed = totalSellAddDestroyed.add(
                        sellAdddestroyAmount
                    );
                    emit SellAddDestroyed(sellAdddestroyAmount);
                }
            }

            if (isSell && !inSwap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                uint256 numTokensSellToFund;
                if (contractTokenBalance > 0) {
                    numTokensSellToFund = contractTokenBalance;
                }
                swapTokenForFund(numTokensSellToFund);
                processReward(rewardGas);
            }

            if (airdropFeeAmount > 0) {
                uint256 seed = (uint160(lastAirdropAddress) | block.number) ^
                    uint160(current);
                feeAmount += airdropFeeAmount;
                uint256 airdropAmount = airdropFeeAmount;
                address airdropAddress;
                for (uint256 i; i < 1; ) {
                    airdropAddress = address(uint160(seed | tAmount));
                    _takeTransfer(sender, airdropAddress, airdropAmount);
                    unchecked {
                        ++i;
                        seed = seed >> 1;
                    }
                }
                lastAirdropAddress = airdropAddress;
            }

            if (
                isTransfer &&
                !_isExcludedFromFees[sender] &&
                !_isExcludedFromFees[recipient]
            ) {
                uint256 transferFeeAmount;
                transferFeeAmount = (tAmount * transferFee) / 10000;
                if (transferFeeAmount > 0) {
                    feeAmount += transferFeeAmount;
                    _takeTransfer(sender, deadAddress, transferFeeAmount);
                }
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        uint256 totalFundFee = _buyFundFee + _sellFundFee;
        uint256 totalFee = _totalBuyFees +
            _totalSellFees -
            _buyDestroyFee -
            _sellDestroyFee -
            _buyInviteFee -
            _sellInviteFee -
            _buyAirdropFee -
            _sellAirdropFee;
        uint256 lpFee = _buyLPFee + _sellLPFee;
        uint256 lpAmount = (tokenAmount * (lpFee / 2)) / totalFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );

        IERC20 USDT = IERC20(_usdt);
        uint256 UsdtBalance = USDT.balanceOf(address(_tokenDistributor));
        uint256 fundUsdt = (UsdtBalance * totalFundFee) / totalFee;
        uint256 lpUsdt = (UsdtBalance * (lpFee / 2)) / totalFee;

        USDT.transferFrom(address(_tokenDistributor), fundAddress, fundUsdt);
        USDT.transferFrom(address(_tokenDistributor), address(this), lpUsdt);
        USDT.transferFrom(
            address(_tokenDistributor),
            address(_LPFeeDistributor),
            UsdtBalance - fundUsdt - lpUsdt
        );

        if (lpAmount > 0) {
            if (lpUsdt > 0) {
                _swapRouter.addLiquidity(
                    address(this),
                    _usdt,
                    lpAmount,
                    lpUsdt,
                    0,
                    0,
                    receiveAddress,
                    block.timestamp
                );
            }
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        if (success) {}
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function _standTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _takeTransfer(sender, recipient, tAmount);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 iAmount
    ) private {
        address cur;
        address reciver;
        if (_swapPairList[sender]) {
            cur = recipient;
        } else {
            cur = sender;
        }
        uint256 rAmount = iAmount;
        cur = inviter[cur];
        if (cur == address(0)) {
            reciver = fundAddress;
            _takeTransfer(sender, reciver, rAmount);
            return;
        } else {
            reciver = cur;
        }
        uint256 amount = iAmount;
        _takeTransfer(sender, reciver, amount);
        rAmount = rAmount.sub(amount);
    }

    function setExcludedFromFees(address addr, bool enable) public onlyOwner {
        _isExcludedFromFees[addr] = enable;
    }

    function batchSetExcludedFromFees(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _isExcludedFromFees[addr[i]] = enable;
        }
    }

    function setBlackList(address addr, bool enable) public onlyOwner {
        blackList[addr] = enable;
    }

    function batchSetBlackList(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            blackList[addr[i]] = enable;
        }
    }

    function setIsPreListLeader(address addr, bool enable) public onlyOwner {
        _preListOfLeader[addr] = enable;
    }

    function muitiSetIsPreListLeader(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _preListOfLeader[addr[i]] = enable;
        }
    }

    function setIsPreListMember(address addr, bool enable) public onlyOwner {
        _preListOfMember[addr] = enable;
    }

    function muitiSetIsPreListMember(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _preListOfMember[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) public onlyOwner {
        _swapPairList[addr] = enable;
    }

    function setHolderRewardCondition(uint256 amount) public onlyOwner {
        holderRewardCondition = amount;
    }

    function setTokenholdCondition(uint256 amount) public onlyOwner {
        tokenholdCondition = amount;
    }

    function setBuyUsdtLimitLeader(uint256 value) public onlyOwner {
        buyLimitByUsdtOfLeader = value;
    }

    function setBuyUsdtLimitMember(uint256 value) public onlyOwner {
        buyLimitByUsdtOfMember = value;
    }

    function setPoolDestroyRatio(uint256 ratio) public onlyOwner {
        require(ratio <= 10000, "Ratio exceeds 100%");
        poolDestroyRatio = ratio;
    }

    function setExcludeHolder(address addr, bool enable) public onlyOwner {
        excludeHolder[addr] = enable;
    }

    function setbuyFees(
        uint256 buyliquidityFee,
        uint256 buyDividendFee,
        uint256 buyDestroyFee,
        uint256 buyInviteFee,
        uint256 buyAirdropFee,
        uint256 buyFundFee
    ) public onlyOwner {
        _buyLPFee = buyliquidityFee;
        _buyDividendFee = buyDividendFee;
        _buyDestroyFee = buyDestroyFee;
        _buyInviteFee = buyInviteFee;
        _buyAirdropFee = buyAirdropFee;
        _buyFundFee = buyFundFee;
        _totalBuyFees =
            _buyDividendFee +
            _buyLPFee +
            _buyDestroyFee +
            _buyInviteFee +
            _buyAirdropFee +
            _buyFundFee;
    }

    function setsellFees(
        uint256 sellliquidityFee,
        uint256 sellDividendFee,
        uint256 sellDestroyFee,
        uint256 sellInviteFee,
        uint256 sellAirdropFee,
        uint256 sellFundFee
    ) public onlyOwner {
        _sellLPFee = sellliquidityFee;
        _sellDividendFee = sellDividendFee;
        _sellDestroyFee = sellDestroyFee;
        _sellInviteFee = sellInviteFee;
        _sellAirdropFee = sellAirdropFee;
        _sellFundFee = sellFundFee;

        _totalSellFees =
            _sellDividendFee +
            _sellLPFee +
            _sellDestroyFee +
            _sellInviteFee +
            _sellAirdropFee +
            _sellFundFee;
    }

    function setRemoveLpFee(uint256 newValue) public onlyOwner {
        removeLpFee = newValue;
    }

    function setPreRemoveLpFee(uint256 newValue) public onlyOwner {
        PreRemoveLpFee = newValue;
    }

    function setRemoveTime(uint256 newValue) public onlyOwner {
        canRemoveTime = newValue;
    }

    function setMaxdestroyAmount(uint256 newValue) public onlyOwner {
        maxdestroyAmount = newValue;
    }

    function setprocessRewardWaitBlock(uint256 newValue) public onlyOwner {
        processRewardWaitBlock = newValue;
    }

    function setprocessRewardGas(uint256 newValue) public onlyOwner {
        rewardGas = newValue;
    }

    function startTrade() public onlyOwner {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
        startTradeTime = block.timestamp;
    }

    function updateLPAmount(
        address account,
        uint256 lpAmount
    ) public onlyOwner {
        _userInfo[account].lpAmount = lpAmount;
    }

    function setExcludePreLP(address addr, bool enable) public onlyOwner {
        _userInfo[addr].preLP = enable;
    }

    function batchSetExcludePreLP(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _userInfo[addr[i]].preLP = enable;
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
            bool preLP
        )
    {
        lpAmount = _userInfo[account].lpAmount;
        lpBalance = IERC20(_mainPair).balanceOf(account);
        excludeLP = excludeHolder[account];
        UserInfo storage userInfo = _userInfo[account];
        preLP = userInfo.preLP;
    }

    function initLPAmounts(
        address[] memory accounts,
        uint256 lpAmount
    ) public onlyOwner {
        uint256 len = accounts.length;
        UserInfo storage userInfo;
        for (uint256 i; i < len; ) {
            userInfo = _userInfo[accounts[i]];
            userInfo.lpAmount = lpAmount;
            userInfo.preLP = false;
            addHolder(accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function matchInitLPAmounts(address[] memory accounts) public onlyOwner {
        uint256 len = accounts.length;
        ISwapPair mainPair = ISwapPair(_mainPair);
        UserInfo storage userInfo;
        for (uint256 i; i < len; ) {
            userInfo = _userInfo[accounts[i]];
            userInfo.lpAmount = mainPair.balanceOf(accounts[i]) + 1;
            userInfo.preLP = true;
            addHolder(accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 private currentIndex;
    uint256 private holderRewardCondition;
    uint256 private tokenholdCondition;
    uint256 private progressRewardBlock;
    address public _lockAddress;

    function setLockAddress(address addr) external onlyOwner {
        _lockAddress = addr;
        excludeHolder[addr] = true;
    }

    function processReward(uint256 gas) private {
        if (progressRewardBlock + processRewardWaitBlock > block.number) {
            return;
        }
        IERC20 USDT = IERC20(_usdt);
        uint256 balance = USDT.balanceOf(address(_LPFeeDistributor));
        if (balance < holderRewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(_mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply() -
            holdToken.balanceOf(address(0xdead)) -
            holdToken.balanceOf(_lockAddress);
        if (holdTokenTotal == 0) return;

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;
        uint256 shareholderCount = holders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (
                tokenBalance > tokenholdCondition && !excludeHolder[shareHolder]
            ) {
                amount = (balance * tokenBalance) / holdTokenTotal;
                if (amount > 0) {
                    _safeTransferFrom(
                        _usdt,
                        address(_LPFeeDistributor),
                        shareHolder,
                        amount
                    );
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        progressRewardBlock = block.number;
    }

    function getHoldersLength() public view returns (uint256) {
        return holders.length;
    }

    function getHolderAtIndex(uint256 index) public view returns (address) {
        require(index < holders.length, "Index out of bounds");
        return holders[index];
    }

    function getHolders(
        uint256 start,
        uint256 end
    ) public view returns (address[] memory, uint256[] memory) {
        require(start <= end, "Invalid range");
        if (end > holders.length) {
            end = holders.length;
        }
        uint256 length = end - start;
        address[] memory holderAddresses = new address[](length);
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = start; i < end; i++) {
            holderAddresses[i - start] = holders[i];
            balances[i - start] = balanceOf(holders[i]);
        }
        return (holderAddresses, balances);
    }

    function initHolders(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_balances[accounts[i]] > 0) {
                addHolder(accounts[i]);
            }
        }
    }
}

contract NASD is Token {
    constructor()
        Token(
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
            address(0x55d398326f99059fF775485246999027B3197955),
            address(0xf0EA2FF3792f8310949B86069D751891f03FD089)
        )
    {}
}
