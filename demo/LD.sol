// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IUniswapPair {
    function sync() external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

contract TokenDistributor {
    mapping(address => bool) private _feeWhiteList;
    constructor () {
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
    }

    function claimToken(address token, address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(to, amount);
        }
    }

    function claimBalance(address to, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _safeTransferETH(to, amount);
        }
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        if (success) {}
    }

    receive() external payable {}
}

contract LDToken is IERC20,IERC20Errors,Ownable {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _decimals = 18;
    string private _name;
    string private _symbol;

    address public immutable usdt = 0x55d398326f99059fF775485246999027B3197955;
    
    uint256 constant ONE_DAY = 28800;
    
    TokenDistributor public immutable _distributor;
    TokenDistributor public immutable _floorPriceDistributor;
    TokenDistributor public immutable _dividendDistributor;
    TokenDistributor public immutable _feeDistributor;
    IUniswapV2Router public immutable _uniswapV2Router;

    address public _uniswapPair;
    address[] public floorPriceBL;
    mapping (address => User) public users;
    address[] public dividendUsers;
    address[] public dividendIndirectUsers;
    address fund;
    address fund1;
    address ufund;
    address bots;
    mapping (address => bool) public WL;
    mapping (address => bool) public BL;
    
    uint256 public dividendIndex;
    uint256 public dividendIndirectIndex;
    uint256 public dividendRewards;
    uint256 public dividendIndirectRewards;
    uint256 public dividendPTotal;
    uint256 public dividendIPTotal;

    //fee
    uint256 public buyTotal;
    uint256 public feeTotal;
    uint256 public ufeeTotal;
    uint256 public fundTotal;
    uint256 public profitTotal;
    uint256 buyFee = 200; //div 10000
    uint256 sellFee = 200; 
    uint256 sellUFee = 100; 
    uint256 profitFee = 1000;
    uint256 DDPR = 10000e18; //dividend direct performance requirements
    uint256 DIPR = 50000e18; //dividend indirect performance requirements
    uint256 DBR = 1000e18; //dividend burn requirements
    uint256 public toggleAmount = 1e18;

    //mining
    address public pool = address(0);
    uint256 initialNum = 30000e18;
    uint256 public poolNum = 30000e18;
    uint256 private constant ACC_REWARD_PRECISION = 1e12;
    uint256 public accRewardPerShare;
    uint256 public lastRewardBlock;
    uint256 public miningStartBlock;
    uint256 public burnTotal;
    uint256 public initialPrice = 1e17; //初始价格 0.1
    uint256 public updateHighPrice = 1e17;
    uint256 public minimumPool = 1000e18;
    uint256 public burnReduceBlock;
    
    bool public startTrade = false;
    bool public startMining = false;

    bool private inSwap;
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event ReduceLog(uint256,uint256,uint256);
    event DeflationLog(uint256,uint256,uint256);
    event DividendData(uint256,uint256,uint256,uint256,uint256,uint256,uint256);

    struct User {
        address upline;
        address[] downlines;
        uint256 performance;
        uint256 indirectPerformance;
        uint256 received;
        uint256 indirectReceived;
        uint256 earned;
        uint256 burnTotal;
        uint256 miningTotal;
        uint256 burnUvalue;
        int256 rewardDebt;
        uint256 lastBlock;
    }

    constructor(address recipient, address _fund, address _fund1, address _ufund, address _bot) Ownable(_msgSender()) {
        require(usdt < address(this), "min");
        _name = "LD Token";
        _symbol = "LD";
        _uniswapV2Router = IUniswapV2Router(
            0x10ED43C718714eb63d5aA57B78B54704E256024E //pancake
        );

        _uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            usdt
        );
        _addFPBL(address(0xdead));
        _addFPBL(address(0));
        _addFPBL(address(_uniswapPair));
        _addFPBL(address(this));

        _approve(address(this), address(_uniswapV2Router), ~uint256(0));
        WL[_msgSender()] = true;
        WL[recipient] = true;
        // _approve(address(_floorPriceDistributor), address(this), ~uint256(0));
        fund = _fund;
        fund1 = _fund1;
        ufund = _ufund;
        bots = _bot;

        _distributor = new TokenDistributor();
        _floorPriceDistributor = new TokenDistributor();
        _dividendDistributor = new TokenDistributor();
        _feeDistributor = new TokenDistributor();

        _totalSupply = 21_000_000 * 10 ** _decimals;
        _balances[recipient] =  20_900_000 * 10 ** _decimals;
        _balances[pool] =  100_000 * 10 ** _decimals;
        
        emit Transfer(address(0), recipient,  _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account] + earned(account);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        return true;
    }
    
    function _basicTransfer(address from,address to, uint256 value) internal {
        uint256 fromBalance = _balances[from];
        if (fromBalance < value) {
            revert ERC20InsufficientBalance(from, fromBalance, value);
        }
        unchecked {
            _balances[from] = fromBalance - value;
        }

        unchecked {
            _balances[to] += value;
        }
        
        // emit Transfer(from, to, value);
        if (from != address(0)) {
            emit Transfer(from, to, value);
        }
    }
    
    function _approve(address owner, address spender, uint256 value) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function getUser(address _user) public view returns(User memory) {
        return users[_user];
    }

    function _update(address from,address to,uint256 value) internal  {
        require(!BL[from] && !BL[to],"BL");
        if (from == address(0)) {
            _update(from, to, value);
            return;
        }
        
        if (!isContract(from)) {
            getReward(from);
        }
        
        if (!isContract(from) && to == address(_floorPriceDistributor)) {
            uint256 _uAmount = value * getFloorPrice() / 1e18;
            _basicTransfer(from, address(0xdead), value);
            _floorPriceDistributor.claimToken(usdt, from, _uAmount);
            return;
        }

        if (!isContract(from) && !isContract(to) && to != address(0) && to != address(0xdead) && value == 1e18) {
            if (!inArray(to, users[from].downlines) && !inArray(from, users[to].downlines)) {
                if (users[to].upline == address(0)) {
                    users[from].downlines.push(to);
                }
            }

            if (inArray(from, users[to].downlines) && users[from].upline == address(0)) {
                users[from].upline = to;
            }
            _basicTransfer(from, to, value);
            return;
        }
        
        if(to == address(this) && !isContract(from)) {
            takeDead(from, value);
            _basicTransfer(from, to, value);
            return;
        }

        if (from == address(this) || to == address(this) || WL[to] || WL[from]) {
            _basicTransfer(from, to, value);
            return;
        }

        if (_uniswapPair == from || _uniswapPair == to) {
            require(startTrade, "not open");
            if (_uniswapPair == from) {
                if (_isRemoveLiquidity()) {
                    _basicTransfer(from, to, value);
                    return;
                }
                uint256 fee = value * buyFee / 10000;
                value -= fee;
                _basicTransfer(from, address(_feeDistributor), fee);
                feeTotal += fee;
                buyTotal += value * 15 / 100;
                updateConstAmount(to, value);
            }
            
            if (_uniswapPair == to) {
                if (_isAddLiquidity(value)) {
                    _basicTransfer(from, to, value);
                    return;
                }
                uint256 fee = value * sellFee / 10000;
                uint256 ufee = value * sellUFee / 10000;
                uint256 _feeTotal = fee + ufee;
                value -= fee;
                value -= ufee;
                _basicTransfer(from, address(_feeDistributor), _feeTotal);
                feeTotal += fee;
                ufeeTotal += ufee;
                
                uint256 profitAmount = getProfitAmount(from, value);
                if (profitAmount > 0) {
                    if (profitFee > 0) {
                        uint256 pFee = profitAmount * profitFee / 10000;
                        value -=  pFee;
                        _basicTransfer(from, address(this), pFee);
                        profitTotal += pFee;
                    }
                }

                _basicTransfer(_uniswapPair, address(0xdead), value * 5 / 100);
                _basicTransfer(_uniswapPair, fund, value * 2 / 100);
                _basicTransfer(_uniswapPair, fund1, value * 1 / 100);
                IUniswapPair(_uniswapPair).sync();
            }

            if (_uniswapPair != from) {
                swapFeeToUSDT(); 
            }
        }

        _basicTransfer(from, to, value);
    }

    function dividendPayout() public {
        if(bots == _msgSender()) {
            address[] memory _dividendUsers = dividendUsers;
            address[] memory _dividendIndirectUsers = dividendIndirectUsers;
            uint256 _total = dividendPTotal;
            if (_total == 0) {
                for(uint256 i; i < _dividendUsers.length; i++) {
                    if (users[_dividendUsers[i]].performance > users[_dividendUsers[i]].received) {
                        _total += users[_dividendUsers[i]].performance;
                    }
                }
                if (_total > 0) {
                    dividendPTotal = _total;
                }
            }

            uint256 _dividendIndex = dividendIndex;
            uint256 _rewards;
            uint256 _uBalance = IERC20(usdt).balanceOf(address(_dividendDistributor));
            if (_dividendIndex == 0) {
                _rewards = _uBalance * 15 / 100;
                dividendRewards = _rewards;
            } else {
                _rewards = dividendRewards;
            }
            uint256 _reward;

            if (_total > 0 && _rewards > 0) {
                uint256 iterations;
                while(_dividendUsers.length >= iterations && iterations < 100) {
                    // _dividendIndex = dividendIndex;
                    if (_dividendIndex >= _dividendUsers.length) {
                        dividendIndex = _dividendIndex;
                        break;
                    }
                    _reward = _rewards * users[_dividendUsers[_dividendIndex]].performance / _total;

                    if (users[_dividendUsers[_dividendIndex]].performance < users[_dividendUsers[_dividendIndex]].received + _reward ) {
                        _reward = users[_dividendUsers[_dividendIndex]].performance - users[_dividendUsers[_dividendIndex]].received;
                    }
                    if (_reward > 0) {
                        users[_dividendUsers[_dividendIndex]].received += _reward;
                        _dividendDistributor.claimToken(usdt, _dividendUsers[_dividendIndex], _reward);
                    }
                    
                    _dividendIndex++;
                    iterations++;
                    if (iterations == 100) {
                        dividendIndex = _dividendIndex;
                    }
                }
            }

            uint256 _indirectDividendIndex = dividendIndirectIndex;
            uint256 _indirectRewards;

            uint256 _indirectTotal = dividendIPTotal;
            if (_indirectTotal == 0) {
                for(uint256 ii; ii < _dividendIndirectUsers.length; ii++) {
                    if (getOutAmount(users[_dividendIndirectUsers[ii]].indirectPerformance) > users[_dividendIndirectUsers[ii]].indirectReceived) {
                        _indirectTotal += users[_dividendIndirectUsers[ii]].indirectPerformance;
                    }
                }
                if (_indirectTotal > 0) {
                    dividendIPTotal = _indirectTotal;
                }
            }

            if (_indirectDividendIndex == 0) {
                _indirectRewards = _uBalance * 5 / 100;
                dividendIndirectRewards = _indirectRewards;
            } else {
                _indirectRewards = dividendIndirectRewards;
            }
            
            if (_indirectTotal > 0 && _indirectRewards > 0) {
                uint256 iterations;
                while(_dividendIndirectUsers.length >= iterations && iterations < 100) {
                    if (_indirectDividendIndex >= _dividendIndirectUsers.length) {
                        dividendIndirectIndex = _indirectDividendIndex;
                        break;
                    }
                    _reward = _indirectRewards * users[_dividendIndirectUsers[_indirectDividendIndex]].indirectPerformance / _indirectTotal;

                    if (getOutAmount(users[_dividendIndirectUsers[_indirectDividendIndex]].indirectPerformance) < users[_dividendIndirectUsers[_indirectDividendIndex]].indirectReceived + _reward ) {
                        _reward = getOutAmount(users[_dividendIndirectUsers[_indirectDividendIndex]].indirectPerformance) - users[_dividendIndirectUsers[_indirectDividendIndex]].indirectReceived;
                    }
                    if (_reward > 0) {
                        users[_dividendIndirectUsers[_indirectDividendIndex]].indirectReceived += _reward;
                        _dividendDistributor.claimToken(usdt, _dividendIndirectUsers[_indirectDividendIndex], _reward);
                    }
                    
                    _indirectDividendIndex++;
                    iterations++;
                    if (iterations == 100) {
                        dividendIndirectIndex = _indirectDividendIndex;
                    }
                }
            }
            emit DividendData(_dividendIndex, _dividendUsers.length, _indirectDividendIndex, _dividendIndirectUsers.length,0,0,0);
            
            if (_dividendIndex >= _dividendUsers.length && _indirectDividendIndex >= _dividendIndirectUsers.length) {
                dividendIndex = 0;
                dividendIndirectIndex = 0;
                dividendPTotal = 0;
                dividendIPTotal = 0;
            }

        } else {
            return;
        }
    }
    
    function deflation() public {
        if(bots == _msgSender() && startMining) {
            _updateReward();
            uint256 _old = burnTotal;
            burnTotal = burnTotal * 99 / 100;
            burnReduceBlock = block.number;
            _basicTransfer(address(this), address(0x0), _old - burnTotal);
            emit DeflationLog(block.timestamp,_old,burnTotal);
        }
    }
    
    function reduceMining() public {
        require(poolNum > minimumPool, "MIN POOL");
        uint256 _price = getSellUsdtAmount(1e10) * 1e8;
        require(_price > updateHighPrice, "NOT NEW PRICE");

        uint256 _diffPrice =  _price - updateHighPrice;
        uint256 _diffMul = _diffPrice / initialPrice;
        if (_diffPrice > 0 && _diffMul > 0) {
            _updateReward();
            updateHighPrice += _diffMul * initialPrice;
            uint256 _poolNum = getReducedAmount(updateHighPrice);
            if (_poolNum > minimumPool) {
                poolNum = _poolNum;
            } else {
                poolNum = minimumPool;
            }
            emit ReduceLog(_price,_diffPrice,poolNum);
        }
    }

    function getReducedAmount(uint256 _hp) public view returns (uint256) {
        uint256 _diffMul = (_hp - initialPrice) / initialPrice;
        if (_diffMul == 0) {
            return 0;
        }
        uint256 per;
        for (uint256 i = 0; i < _diffMul; i++) {
            if (i < 28) {
                per += 250;
            } else if (i >= 28 && i < 39) {
                per += 100;
            } else if (i >= 39 && i < 49 ) {
                per += 50;
            } else if (i >= 49 && i < 59 ) {
                per += 25;
            } else if (i >= 59 && i < 69 ) {
                per += 15;
            } else {
                per += 10;
            }
        }
        uint256 _reduced = initialNum * per / 10000;
        return initialNum > _reduced ? initialNum - _reduced : initialNum ;
    }

    function _getUserAmount(address _user) internal view returns (uint256) {
        User memory _userInfo = users[_user];
        if (burnReduceBlock == 0) {
            return _userInfo.miningTotal;
        }
        
        uint256 _timePast = _userInfo.lastBlock <= burnReduceBlock ? ceilDiv(burnReduceBlock - _userInfo.lastBlock, ONE_DAY) : 0;
        uint256 _amount = _userInfo.miningTotal;
        if (_timePast == 0 || _amount == 0) {
            return (_amount);
        }

        for (uint256 i = 1; i <= _timePast; i++) {
            _amount -= _amount * 1 / 100;
        }
        return _amount;
    }
    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function rewardPerBlock() public view returns(uint256) {
        return uint256(uint256(poolNum) / 28800);
    }
    
    function addFPBL(address _user) public onlyOwner {
        _addFPBL(_user);
    }

    function setTrade() public onlyOwner {
        if (!startTrade) {
            startTrade = true;
        }
    }

    function setMining() public onlyOwner {
        if (!startMining) {
            startMining = true;
            lastRewardBlock = block.number;
            miningStartBlock = block.number;
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _addFPBL(address _user) internal {
        if (!inArray(_user, floorPriceBL)) {
            floorPriceBL.push(_user);
        }
    }

    function _removeFPBL(address _user) internal {
        address[] memory _floorPriceBL = floorPriceBL;
        for (uint256 i; i < _floorPriceBL.length; i ++) {
            if (_floorPriceBL[i] == _user) {
                floorPriceBL[i] = _floorPriceBL[_floorPriceBL.length - 1];
                floorPriceBL.pop();
                break;
            }
        }
        return;
    }

    function inArray(address addr,address[] memory arr) internal pure returns (bool) {
        for (uint256 i; i < arr.length; i++) {
            if (arr[i] == addr) {
                return true;
            }
        }
        return false;
    }

    mapping(address => uint256) internal userCostAmount;
    function updateConstAmount(address account, uint256 amount) internal {
        uint256 currentAmount = getSellUsdtAmount(amount);
        userCostAmount[account] = userCostAmount[account] + currentAmount;
    }
    
    function getSellUsdtAmount(uint256 amount) public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        uint256[] memory amounts = _uniswapV2Router.getAmountsOut(amount, path);
        return amounts[1];
    }

    function getdividendUsersLength() public view returns (uint256) {
        return dividendUsers.length;
    }

    function getdividendIndirectUsersLength() public view returns (uint256) {
        return dividendIndirectUsers.length;
    }
    
    // usdt -> token
    function getBuyTokenAmount(uint256 amount) public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(this);
        uint256[] memory amounts = _uniswapV2Router.getAmountsOut(amount, path);
        return amounts[1];
    }
    
    function getProfitAmount(address account, uint256 amount) internal returns (uint256){
        uint256 constAmount = userCostAmount[account];
        uint256 currentAmount = getSellUsdtAmount(amount);
        if (constAmount > currentAmount) {
            userCostAmount[account] = userCostAmount[account] - currentAmount;
            return 0;
        } else if (constAmount > 0 && currentAmount > constAmount) {
            uint256 profitAmount = getBuyTokenAmount(currentAmount - constAmount);
            userCostAmount[account] = 0;
            return profitAmount;
        } else {
            userCostAmount[account] = 0;
            return amount;
        }
    }

    function getFloorPrice() public view returns(uint256 price) {
        address[] memory _fpbl = floorPriceBL;
        uint256 _fpblTotal;
        for(uint256 i; i < _fpbl.length; i++) {
            _fpblTotal += _balances[_fpbl[i]];
        }
        if (totalSupply() - _fpblTotal == 0) {
            price = 0;
        } else {
            price = IERC20(usdt).balanceOf(address(_floorPriceDistributor)) * 1e18 / (totalSupply() - _fpblTotal);
        }
    }

    function swapFeeToUSDT() public lockTheSwap {
        uint256 _fee = feeTotal;
        uint256 _ufee = ufeeTotal;
        uint256 _buy = buyTotal;
        uint256 _profit = profitTotal;
        uint256 _feeTotal = _fee + _ufee;
        uint256 _total = _feeTotal + _buy + _profit;
        
        if (_total < toggleAmount) { 
            return ;
        }
        if (_buy > toggleAmount)  {
            _basicTransfer(_uniswapPair, address(this), _buy);
            IUniswapPair(_uniswapPair).sync();
        }
        if (_feeTotal > 0)  {
            _basicTransfer(address(_feeDistributor), address(this), _feeTotal);
        }
        
        feeTotal = 0;
        buyTotal = 0;
        profitTotal = 0;
        ufeeTotal = 0;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        
        uint256 _bal = IERC20(usdt).balanceOf(address(_distributor));
        // swap token to usdt
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _total,
            0,
            path,
            address(_distributor),
            block.timestamp
        );
        uint256 _afterBal = IERC20(usdt).balanceOf(address(_distributor));
        uint256 _swapTotal = _afterBal - _bal;

        uint256 _swapBuy = _swapTotal * _buy * 2 / 3 / _total;
        if (_swapBuy > 0) {
            _distributor.claimToken(usdt, address(_floorPriceDistributor), _swapBuy);
        }

        uint256 _swapUFee = _swapTotal * _ufee / _total;
        if (_swapUFee > 0) {
            _distributor.claimToken(usdt, address(ufund), _swapUFee);
        }

        uint256 _dividendTotal = _swapTotal - _swapUFee - _swapBuy;
        if (_dividendTotal > 0) {
            _distributor.claimToken(usdt, address(_dividendDistributor), _dividendTotal);
        }
    }

    function getOutAmount(uint256 amount) internal pure returns (uint256) {
        return amount / 2;
    }
    
    //get mining 
    function getReward(address account) internal {
        _updateReward();
        uint256 _reward = earned(account);
        if (_reward == 0 || _balances[pool] < _reward) {
            return;
        }
        User storage _user = users[account];

        int256 _accumulatedRewards = int256((_getUserAmount(account) * accRewardPerShare) / ACC_REWARD_PRECISION);
        _user.rewardDebt = _accumulatedRewards;

        if (_reward > 0) {
            _user.earned += _reward;
            _basicTransfer(pool, account, _reward);
        }
    }
    
    function earned(address account) public view returns (uint256) {
        User memory _user = users[account];
        if (lastRewardBlock == 0 || !startMining || burnTotal == 0 ) {
            return 0;
        }

        uint256 _accRewardPerShare = accRewardPerShare;
        
        if (block.number > lastRewardBlock && burnTotal != 0) {
            uint256 _timePast = block.number - lastRewardBlock;
            uint256 _rewards = _timePast * rewardPerBlock();
            _accRewardPerShare = _accRewardPerShare + ((_rewards * ACC_REWARD_PRECISION) / burnTotal);
        }

        return uint256(_getUserAmount(account) * _accRewardPerShare / ACC_REWARD_PRECISION) - uint256(_user.rewardDebt);
    }

    function takeDead(address _user, uint256 value) internal {
        _updateReward();
        User storage user = users[_user];
        uint256 uValue = value * getSellUsdtAmount(1e10) / 1e10;
        address _upline = user.upline;
        User storage uplineUser = users[_upline];
        
        user.miningTotal = _getUserAmount(_user) + value;
        user.burnTotal += value;
        user.burnUvalue += uValue;
        user.rewardDebt = user.rewardDebt + int256(value * accRewardPerShare) / int256(ACC_REWARD_PRECISION);
        burnTotal += value;
        user.lastBlock = block.number;
        
        if (_upline != address(0)) {
            // direct
            uplineUser.performance += uValue;
            if (uplineUser.burnUvalue >= DBR && uplineUser.performance >= DDPR) {
                if (!inArray(_upline, dividendUsers)) {
                    dividendUsers.push(_upline);
                }
            }
            // indirect
            if (uplineUser.upline != address(0)) {
                User storage indirectUser = users[uplineUser.upline];
                indirectUser.indirectPerformance += uValue;
                
                if (indirectUser.burnUvalue >= DBR && indirectUser.indirectPerformance >= DIPR) {
                    if (!inArray(uplineUser.upline, dividendIndirectUsers)) {
                        dividendIndirectUsers.push(uplineUser.upline);
                    }
                }
            }
        }

        if (user.burnUvalue >= DBR && user.performance >= DDPR) {
            if (!inArray(_user, dividendUsers)) {
                dividendUsers.push(_user);
            }
        }

        if (user.burnUvalue >= DBR && user.indirectPerformance >= DIPR) {
            if (!inArray(_user, dividendUsers)) {
                dividendIndirectUsers.push(_user);
            }
        }
    }
    
    function _updateReward() internal{
        if (!startMining) {
            return;
        }
        if (block.number > lastRewardBlock) {
            if (burnTotal > 0) {
                uint256 _timePast = block.number - lastRewardBlock;
                uint256 _rewards = _timePast * rewardPerBlock();
                accRewardPerShare = accRewardPerShare + (_rewards * ACC_REWARD_PRECISION) / burnTotal;
            }
            lastRewardBlock = block.number;
        }
    }

    function setBL(address[] calldata accounts, bool b) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            BL[accounts[i]] = b;
            if (b) {
                _addFPBL(accounts[i]);
            } else {
                _removeFPBL(accounts[i]);
            }
        }
    }

    function setWL(address[] calldata accounts, bool b) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            WL[accounts[i]] = b;
        }
    }

    function setFee(uint256 _bFee, uint256 _sFee, uint256 _sUFee) public onlyOwner {
        buyFee = _bFee;
        sellFee = _sFee;
        sellUFee = _sUFee;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool){
        (uint256 r0,uint256 r1,) = IUniswapPair(_uniswapPair).getReserves();
        uint256 rOther;
        uint256 rThis;
        uint256 amountOther;
        if (usdt < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
        
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        uint256 bal = IERC20(usdt).balanceOf(_uniswapPair);
        return bal >= rOther + amountOther;
    }

    function _isRemoveLiquidity() internal view returns (bool){
        (uint256 r0,uint256 r1,) = IUniswapPair(_uniswapPair).getReserves();
        uint256 r;
        if (usdt < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(usdt).balanceOf(_uniswapPair);
        return bal <= r;
    }
    
    function claimToken(address token, address to, uint256 amount) public onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function claimBalance(address to, uint256 amount) public onlyOwner {
        _safeTransferETH(to, amount);
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        if (success) {}
    }

    receive() external payable {}
}