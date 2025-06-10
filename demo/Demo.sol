/**
 *Submitted for verification at BscScan.com on 2025-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library DateTime {
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;
    function isLeapYear(uint256 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }
    function leapYearsBefore(uint256 year) internal pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
    function getDaysInMonth(uint256 month, uint256 year) internal pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }
    function parseTimestamp(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 weekday, uint256 hour, uint256 minute, uint256 second) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
        for (i = 1; i <= getDaysInMonth(month, year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        hour = getHour(timestamp);
        minute = getMinute(timestamp);
        second = getSecond(timestamp);
        weekday = getWeekday(timestamp);
    }
    function getYear(uint256 timestamp) internal pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }
    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, , , , , ) = parseTimestamp(timestamp);
    }
    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day, , , , ) = parseTimestamp(timestamp);
    }
    function getHour(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp / 60 / 60) % 24);
    }
    function getMinute(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp / 60) % 60);
    }
    function getSecond(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp % 60);
    }
    function getWeekday(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
    function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint256 timestamp) {
        uint16 i;
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;
        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }
        timestamp += DAY_IN_SECONDS * (day - 1);
        timestamp += HOUR_IN_SECONDS * (hour);
        timestamp += MINUTE_IN_SECONDS * (minute);
        timestamp += second;
        return timestamp;
    }
    function getDayNum(uint256 timestamp) internal pure returns (uint256) {
        (uint256 year, uint256 month, uint256 day, , , , ) = parseTimestamp(timestamp);
        return year * 10000 + month * 100 + day;
    }
    function getTodayNum(uint256 timestamp) internal view returns (uint256) {
        (uint256 year, uint256 month, uint256 day, , , , ) = parseTimestamp(block.timestamp + timestamp);
        return year * 10000 + month * 100 + day;
    }
    function getDayHour(uint256 timestamp) internal pure returns (uint256) {
        (uint256 year, uint256 month, uint256 day, , uint256 hour, , ) = parseTimestamp(timestamp);
        return year * 1000000 + month * 10000 + day * 100 + hour;
    }
    function getDayMinute(uint256 timestamp) internal pure returns (uint256) {
        (uint256 year, uint256 month, uint256 day, , uint256 hour, uint256 minute, ) = parseTimestamp(timestamp);
        return (year * 1000000) + (month * 10000) + (day * 100) + ((hour % 10) * 10 + minute / 10);
    }
}

interface ISwapPair {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface ISwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        if (from != address(this)) emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _balances[address(0)] += amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Distributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

interface IMint {
    function isDynamicList(address _addr) external view returns (bool);
    function checkRemoveLP(address account, uint amount) external view returns (bool);
    function checkAddLP(address account, uint amount) external view returns (bool);
    function getBalance(address account) external view returns (uint);
    function computeAcutal(address account, uint amount) external returns (bool isCapital, uint burnAmount, uint giftAmount);
    function register(address account, address refer) external;
    function claimReward(address account) external returns (uint);
    function addUser(address account,uint256 value) external;
    function addWhiteUser(address account) external;

    function activateUser(address account) external;
    function logOutUser(address account) external;
}

contract FDC is ERC20, Ownable {
    using Address for address;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isWhiteList;
    mapping(address => bool) public isBlackList;
    mapping(address => uint) public userLasts;
    mapping(address => address) public userRefers;
    mapping(address => uint) public userInviteTotal;
    mapping(address => mapping(uint => address)) public userInvites;
    uint private _startBlock;
    uint private _openTime;
    uint private _burnTime;
    uint private _burnMin;
    uint private _activeAmount = 1e15;
    uint private _beforeOpenTime = 15 * 60;
    uint private _beforeOpenAmount = 50e18;
    uint private _addPoolRate = 5;    
    uint private _buyRateRate = 5;
    uint private _swapEveryMax = 30000e18;
    uint private _swapEveryTime = 10;
    uint private _swapDynamicMin = 30e18;
    uint256 _swapAndLiquifyAmount = 1e18;
    uint256 _burnInterval = 1 hours;
    uint public lpReward;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    address private _usdt = 0x55d398326f99059fF775485246999027B3197955;
    address private _uniswapRouterV2Address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private _feeAddress = 0x8c39635aCEa4e5a52480EFCEA8Fa81Ea7aAbb29A;
    address private _swapPair;
    IERC20 private _USDT;
    Distributor private _DISTRIBUTOR;
    IMint private _MINT;
    ISwapRouter private _ROUTER;
    bool _inSwapAndLiquify;
    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    event Mining(bool isMining, address account, uint amount);

    constructor() ERC20("Flying Dragon Coin", "FDC") {
        require(_usdt < address(this),"Token small");

        address recieve = msg.sender;
        _USDT = IERC20(_usdt);
        _ROUTER = ISwapRouter(_uniswapRouterV2Address);
        _MINT = IMint(0x50E27D405419de984d9EEe80068844A4ddA88D61);

        _swapPair = pairFor(_ROUTER.factory(), address(this), address(_USDT));
        _DISTRIBUTOR = new Distributor(address(_USDT));
        isFeeExempt[address(this)] = true;
        isFeeExempt[recieve] = true;
        isFeeExempt[_dead] = true;
        isFeeExempt[msg.sender] = true;
        _mint(recieve, 25_000_000 * 10 ** decimals());
        _mint(address(this), 185_000_000 * 10 ** decimals());
    }

    function withdrawToken(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }

    function setTokenAdd(uint256 category, address data) public onlyOwner {
        if (category == 1) _swapPair = data;
        if (category == 10) {
            _USDT = IERC20(data);
            _DISTRIBUTOR = new Distributor(address(_USDT));
        }
        if (category == 12) _MINT = IMint(data);
        if (category == 13) _ROUTER = ISwapRouter(data);
        if (category == 14) _feeAddress = data;
    }

    function setConfig(uint256 category, uint256 data) public onlyOwner {
        if (category == 2) _openTime = data;
        if (category == 3) _burnTime = data;
        if (category == 4) _burnMin = data;
        if (category == 5) _activeAmount = data;
        if (category == 7) _beforeOpenTime = data;
        if (category == 8) _beforeOpenAmount = data;
        if (category == 9) _addPoolRate = data;
        if (category == 10) _buyRateRate = data;
        if (category == 11) _swapEveryMax = data;
        if (category == 12) _swapEveryTime = data;
        if (category == 13) _swapDynamicMin = data;
        if (category == 14) lpReward = data;
        if (category == 15) _swapAndLiquifyAmount = data;
        if (category == 16) _burnInterval = data;        
    }

    function setIsFeeExempt(address account, bool newValue) public onlyOwner {
        isFeeExempt[account] = newValue;
    }

    function setIsFeeExemptBatch(address[] memory accounts, bool data) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isFeeExempt[accounts[i]] = data;
        }
    }

    function setIsWhiteList(address account, bool newValue) public onlyOwner {
        isWhiteList[account] = newValue;
        if(newValue){
            _MINT.addWhiteUser(account);
        }
    }

    function setIsWhiteListBatch(address[] memory accounts, bool data) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhiteList[accounts[i]] = data;
            if(data){
                _MINT.addWhiteUser(accounts[i]);
            }            
        }
    }

    function setIsBlackList(address account, bool enable) public onlyOwner {
        isBlackList[account] = enable;
    }

    function setIsBlackListBatch(address[] memory accounts, bool data) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBlackList[accounts[i]] = data;
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + _MINT.getBalance(account);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (!isFeeExempt[tx.origin] && !_inSwapAndLiquify) {
            uint reward = _MINT.claimReward(tx.origin);
            if (reward > balanceOf(address(this))) {
                reward = balanceOf(address(this));
            }
            if (reward > 0) {
                super._transfer(address(this), tx.origin, reward);
                emit Mining(true, tx.origin, reward);
            }
        }

        bool isAdd;
        bool isRemove;

        if (isBlackList[from] || isBlackList[to]) {
            revert("Blacklist prohibits transfer");
        }
        else if (_inSwapAndLiquify || isFeeExempt[from] || isFeeExempt[to]) {
            super._transfer(from, to, amount);
            if (to == _swapPair && _startBlock == 0) {
                _startBlock = block.number;
            }
        }
        else if (from == _swapPair) {
            if (_startBlock == 0 || _openTime == 0 || _openTime > block.timestamp) revert("Trading not open");
            (, uint rOther, uint balanceOther) = _getReserves();
            
            if (balanceOther >= rOther + (getSwapValueUSDT(amount) * (100 - _buyRateRate)) / 100 && balanceOther <= rOther + (getSwapValueUSDT(amount) * (100 + _buyRateRate)) / 100) {
                if (getSwapValueUSDT(amount) > _swapEveryMax) revert("Exceeding the maximum limit");
                if (userLasts[to] + _swapEveryTime > block.timestamp) revert("Trading too frequently");
                userLasts[to] = block.timestamp;
                uint256 every = amount / 100;
                super._transfer(from, address(this), every);
                lpReward += every;
                super._transfer(from, _dead, every);
                super._transfer(from, to, amount - every * 2);
            }
            else {
                isRemove = true;
                if (userLasts[to] + _swapEveryTime > block.timestamp) revert("Trading too frequently");
                userLasts[to] = block.timestamp;

                if (isWhiteList[to]) {
                    super._transfer(from, _dead, amount);
                }
                else {
                    if (!_MINT.checkRemoveLP(to, amount) || to != tx.origin) revert("No pool withdrawal allowed");

                    uint reward = _MINT.claimReward(to);
                    if (reward > balanceOf(address(this))) {
                        reward = balanceOf(address(this));
                    }
                    if (reward > 0) {
                        super._transfer(address(this), to, reward);
                        emit Mining(true, to, reward);
                    }

                    (bool isCapital, uint burnAmount, uint giftAmount) = _MINT.computeAcutal(to, amount);
                    if (isCapital) {//触发保价机制
                        uint256 every = amount / 100;
                        if (burnAmount > 0 && burnAmount + every * 2 < amount) {
                            super._transfer(from, _dead, every * 2 + burnAmount);
                            super._transfer(from, to, amount - every * 2 - burnAmount);
                        }
                        else if (burnAmount > 0 && burnAmount + every * 2 >= amount) {
                            super._transfer(from, _dead, amount);
                        }
                        else if (giftAmount > 0) {
                            if (giftAmount > balanceOf(address(this))) {
                                giftAmount = balanceOf(address(this));
                            }
                            if (giftAmount > 0) {
                                super._transfer(address(this), tx.origin, giftAmount);
                                emit Mining(false, tx.origin, giftAmount);
                            }
                            super._transfer(from, _dead, every * 2);
                            super._transfer(from, to, amount - every * 2);
                        }
                    } else {
                        uint256 every = amount / 100;
                        super._transfer(from, _dead, every * 2);
                        super._transfer(from, to, amount - every * 2);
                    }
                }
            }
        }
        else if (to == _swapPair) {
            if (_startBlock == 0 || _openTime == 0 || _openTime > block.timestamp) revert("Trading not open");
            (uint rThis, uint rOther, uint balanceOther) = _getReserves();
            
            if (balanceOther >= rOther + (amount * rOther * (100 - _addPoolRate)) / (rThis * 100) && balanceOther <= rOther + (amount * rOther * (100 + _addPoolRate)) / (rThis * 100)) {                
                isAdd = true;
                if (getSwapValueUSDT(amount) > _swapEveryMax) revert("Exceeding the maximum limit");                

                if (userLasts[from] + _swapEveryTime > block.timestamp) revert("Trading too frequently");
                userLasts[from] = block.timestamp;
                if (!_MINT.checkAddLP(from, amount) || from != tx.origin) revert("Re-issuance to add liquidity is not allowed");
                super._transfer(from, to, amount);
            }
            else {
                burnPool();
                swapAndLiquify();
                if (getSwapValueUSDT(amount) > _swapEveryMax) revert("Exceeding the maximum limit");
                if (userLasts[from] + _swapEveryTime > block.timestamp) revert("Trading too frequently");
                userLasts[from] = block.timestamp;
                if (_MINT.isDynamicList(from) && getSwapValueUSDT(amount) < _swapDynamicMin) revert("Below minimum value");
                uint256 every = amount / 100;
                super._transfer(from, address(this), every);
                lpReward += every;
                super._transfer(from, _dead, every);
                super._transfer(from, to, amount - every * 2);
            }
        }
        else {
            if (from != _swapPair && from != address(this) && from != address(1)) {
                if (userLasts[from] + _swapEveryTime > block.timestamp) revert("Trading too frequently");
                userLasts[from] = block.timestamp;
            }
            if (amount == 1e14 && !to.isContract() && !from.isContract()) {
                //不能重复绑定 不能先激活再绑定关系
                if(userRefers[from] == address(0) && !_MINT.isDynamicList(from)){
                    address refer = to;
                    bool isExist = false;
                    
                    for (uint256 i = 0; i < 10; i++) {
                        if (refer == address(0)) break;
                        if (refer == from) {
                            isExist = true;
                            break;
                        }
                        refer = userRefers[refer];
                    }
                    
                    if (!isExist) {
                        userInviteTotal[to]++;
                        userInvites[to][userInviteTotal[to]] = from;
                        userRefers[from] = to;
                        _MINT.register(from, to);
                    }
                }
            }
            super._transfer(from, to, amount);
        }

        if (balanceOf(from) == 0 && balanceOf(address(this))  > 0) {
            super._transfer(address(this), from, 1);
        }

        if (_startBlock > 0 && from == _swapPair && !_inSwapAndLiquify) {
            //激活有效挖坑用户
            if (!isRemove && amount >= 1) {
                    try _MINT.activateUser(to) {} catch {}
            }

            //注销挖矿用户
            if(isRemove){
                try _MINT.logOutUser(to) {} catch {}                  
            }

        } else if (_startBlock > 0 && to == _swapPair && !_inSwapAndLiquify) {
            if (isAdd) {//添加lp持有用户和挖矿用户
                try _MINT.addUser(from, amount) {} catch {}
            }

        }
    }

    function getTokenAdd() public view returns (address swapPair, address usdt, address distributor, 
        address burnDividend, address feeAddress){
        swapPair = _swapPair;
        usdt = address(_USDT);
        distributor = address(_DISTRIBUTOR);
        burnDividend = address(_MINT);
        feeAddress = _feeAddress;
    }

    function getConfig() public view returns (uint startBlock, uint openTime, uint burnTime, 
        uint burnMin, uint activeAmount, uint beforeOpenTime, uint beforeOpenAmount, uint addPoolRate, 
        uint buyRateRate, uint swapEveryMax, uint swapEveryTime, uint swapDynamicMin, uint swapAndLiquifyAmount,
        uint burnInterval){
        startBlock = _startBlock;
        openTime = _openTime;
        burnTime = _burnTime;
        burnMin = _burnMin;
        activeAmount = _activeAmount;
        beforeOpenTime = _beforeOpenTime;
        beforeOpenAmount = _beforeOpenAmount;
        addPoolRate = _addPoolRate;
        buyRateRate = _buyRateRate;
        swapEveryMax = _swapEveryMax;
        swapEveryTime = _swapEveryTime;
        swapDynamicMin = _swapDynamicMin;
        swapAndLiquifyAmount = _swapAndLiquifyAmount;
        burnInterval = _burnInterval;
    }

    function getPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_USDT);
        if (_swapPair == address(0)) return 0;
        if (balanceOf(_swapPair) == 0 || _USDT.balanceOf(_swapPair) == 0) return 0;
        (uint256 reserve1, uint256 reserve2, ) = ISwapPair(_swapPair).getReserves();
        if (reserve1 == 0 || reserve2 == 0) {
            return 0;
        } else {
            return _ROUTER.getAmountsOut(1 * 10 ** decimals(), path)[1];
        }
    }

    function getSwapValueUSDT(uint amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_USDT);
        if (_swapPair == address(0)) return 0;
        (uint256 reserve1, uint256 reserve2, ) = ISwapPair(_swapPair).getReserves();
        if (reserve1 == 0 || reserve2 == 0) {
            return 0;
        } else {
            return _ROUTER.getAmountsOut(amount, path)[1];
        }
    }    

    function burnPool() public lockTheSwap {
        if (balanceOf(_swapPair) <= _burnMin) {
            _burnTime == 0;
            return;
        }
        if (_startBlock == 0 || _openTime == 0 || block.timestamp < _openTime) return;
        if (_burnTime == 0) {
            _burnTime = block.timestamp + _burnInterval;
            return;
        }
        if (_burnTime > block.timestamp) return;
        _burnTime += _burnInterval;
        super._transfer(_swapPair, _dead, (balanceOf(_swapPair) * 1) / 1000);
        ISwapPair(_swapPair).sync();
    }    

    function swapAndLiquify() public lockTheSwap {
        uint amount = lpReward;
        if (amount >= _swapAndLiquifyAmount && amount <= balanceOf(address(this))) {
            address token0 = ISwapPair(_swapPair).token0();
            (uint256 reserve0, uint256 reserve1, ) = ISwapPair(_swapPair).getReserves();
            uint256 tokenPool = reserve0;
            if (token0 != address(this)) tokenPool = reserve1;
            if (amount > tokenPool / 100) {
                amount = tokenPool / 100;
            }
            lpReward -= amount;
            _swapTokensForUSDT(amount);
            uint256 amountU = _USDT.balanceOf(address(_DISTRIBUTOR));
            _USDT.transferFrom(address(_DISTRIBUTOR), address(_feeAddress), amountU);
        }
    }

    function _getReserves() private view returns (uint rThis, uint rOther, uint balanceOther) {
        (uint r0, uint r1, ) = ISwapPair(_swapPair).getReserves();
        if (address(_USDT) < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
        balanceOther = _USDT.balanceOf(_swapPair);
    }

    function _swapTokensForUSDT(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_USDT);
        _approve(address(this), address(_ROUTER), tokenAmount);
        _ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(_DISTRIBUTOR), block.timestamp);
        emit SwapTokensForTokens(tokenAmount, path);
    }
    event SwapTokensForTokens(uint256 amountIn, address[] path);
    event AddLiquidity(uint256 tokenAmount, uint256 ethAmount);
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), hex"00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5")))));
    }
}