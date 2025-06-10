/**
 *Submitted for verification at BscScan.com on 2025-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

interface ISwapPair {
    function totalSupply() external view returns (uint256);
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

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function feeTo() external view returns (address);
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract Mint is Ownable{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    ISwapRouter private _ROUTER;

    address _USDT = 0x55d398326f99059fF775485246999027B3197955;
    address _token;
    address _lp;

    uint private _addPoolMin = 55e18;
    uint private _minHoldTime = 30 days;
    uint private _staticInterval = 1 days;

    mapping(address => bool) public lpAddHistoryFlag;
    mapping(address => bool) public lpRemoveHistoryFlag;

    EnumerableSet.AddressSet mintUsers; //lp持有用户
    mapping(address => uint256) public userLpValues;

    mapping(address => uint256) public userLpAmounts;

    mapping(address => uint256) public mintStartTimes; 
    mapping(address => uint256) public userDynamicIncomes;


    mapping(address => address) public userRefers;
    mapping(address => EnumerableSet.AddressSet) private lowerValidUsers; 

    struct lowerValidUserInfo {
        address rUser;
        uint256 rAmount;
    }

    mapping(address => uint256) public userLastTimes;

    mapping(address => uint) public userInviteTotal;
    mapping(address => bool) private _isContractDealer; 

    receive() external payable {}

    constructor(){
        _ROUTER = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }    

    function setAddr(address token, address lp) external onlyOwner{
        _token = token;
        _lp = lp;
        _isContractDealer[_token] = true;
    }    

    function setContractDealerFlag(address addr,bool flag) public onlyOwner{
        _isContractDealer[addr] = flag;
    }

    function getContractDealerFlag(address addr) public view returns(bool flag){
        flag = _isContractDealer[addr];
    }

    modifier onlyContractDealer() {
        require(_isContractDealer[_msgSender()] == true, "Ownable: _contract_dealer is not the owner");
        _;
    }

    function setAddPoolMin(uint256 min) external onlyOwner{
        _addPoolMin = min;
    }

    function setMinHoldTime(uint256 hold) external onlyOwner{
        _minHoldTime = hold;
    }

    function setStaticInterval(uint256 interval) external onlyOwner{
        _staticInterval = interval;
    }

    function getMintUsers() public view returns (address[] memory) {
        return mintUsers.values();
    }

    function getMintUser(uint256 i) public view returns (address) {
        return mintUsers.at(i);
    }

    function getLowerValidUsers(address account) public view returns (lowerValidUserInfo[] memory) {
        if(lowerValidUsers[account].length() == 0) return new lowerValidUserInfo[](0);
        uint256 _len = lowerValidUsers[account].length();
        lowerValidUserInfo[] memory _userInfos = new lowerValidUserInfo[](uint256(_len));
        for(uint i = 0; i < _len; i++) {
            _userInfos[i].rUser =  lowerValidUsers[account].at(i);
            _userInfos[i].rAmount = userLpValues[_userInfos[i].rUser];
        }

        return _userInfos;
    }

    uint256 public removeLpDeviationRate = 95;
    function setRemoveLpDeviationRate(uint256 rate) external onlyOwner{
        removeLpDeviationRate = rate;
    }

    function checkRemoveLP(address account, uint amount) public view returns (bool){
        if(lpRemoveHistoryFlag[account]) return false;

        if(!lpAddHistoryFlag[account]) return false;

        uint256 removeLPLiquidity = _isRemoveLiquidity(amount);

        if(removeLPLiquidity <= userLpAmounts[account] * removeLpDeviationRate / 100){
            return false;
        }
        return true;
    }

    function checkAddLP(address account, uint amount) public view returns (bool){
        
        if(lpAddHistoryFlag[account]) return false;

        if (getSwapValueUSDT(amount) < _addPoolMin) return false;

        return true;
    }
    
    function register(address account, address refer) external onlyContractDealer{
        
        userRefers[account] = refer;

    }

    function getBalance(address account) public view returns (uint){

        if(mintStartTimes[account] == 0) return 0;

        (uint256 staticIncome, ) = getStaticIncome(account);

        uint256 dynamicIncome = userDynamicIncomes[account];

        return staticIncome + dynamicIncome;

    }

    function isDynamicList(address account) public view returns (bool){
        if(mintStartTimes[account] == 0) return false;
        if(userInviteTotal[account] == 0) return false;
        return true;
    }

    //获取静态收益
    function getStaticIncome(address account) internal view returns(uint256 balance, uint256 cycle){
        if(mintStartTimes[account] > 0) {
            uint256 day = (block.timestamp - userLastTimes[account]) / _staticInterval;
            if(day > 0){
                cycle = day / 7;
                if(cycle > 0){ // 加池子U价值 / 代币价格 * 1e18 * 周期 * 7 / 100
                    balance = userLpValues[account] * 1e18 * cycle * 7 / 100 / getSwapValueUSDT(1e18);            
                }
            }
        }
    }

    event DynamicIncomes(address account, address refer, uint256 depth, uint256 amount);
    event DynamicIncomesNo(address account, address refer, uint256 depth, uint256 inviteCount,uint256 t);

    //给上级释放动态挖矿奖励
    function sumDynamicIncomes(address account, uint256 amount, uint256 depth) internal{
        address refer = userRefers[account];
        if(refer == address(0)) return;
        if(depth > 5) return;

        uint256 inviteCount = userInviteTotal[refer];
        if(depth == 1){
            if(inviteCount >= 1 && mintStartTimes[account] != 0){
                userDynamicIncomes[refer] = userDynamicIncomes[refer] + amount;
                emit DynamicIncomes(account, refer, depth, amount);
            }else{
                emit DynamicIncomesNo(account, refer, depth, inviteCount, mintStartTimes[account]);
            }
        }else if(depth == 2){
            if(inviteCount >= 5 && mintStartTimes[account] != 0){
                userDynamicIncomes[refer] = userDynamicIncomes[refer] + amount; 
                emit DynamicIncomes(account, refer, depth, amount);           
            }else{
                emit DynamicIncomesNo(account, refer, depth, inviteCount, mintStartTimes[account]);
            }
        }else if(depth >= 3){
            if(inviteCount >= 8 && mintStartTimes[account] != 0){
                userDynamicIncomes[refer] = userDynamicIncomes[refer] + amount;
                emit DynamicIncomes(account, refer, depth, amount);   
            }else{
                emit DynamicIncomesNo(account, refer, depth, inviteCount, mintStartTimes[account]);
            }      
        }
        depth++;
        sumDynamicIncomes(refer, amount, depth);
    }

    event ClaimRewardLog(address account, uint256 staticIncome, uint256 dynamicCome,uint256 balance,uint256 cycle);
    //提取奖励
    function claimReward(address account) external onlyContractDealer returns(uint) {
        
        if(mintStartTimes[account] == 0) return 0;

        //获取静态收益
        (uint256 staticIncome, uint256 cycle)  = getStaticIncome(account);

        //获取动态收益
        uint256 dynamicIncome = userDynamicIncomes[account];

        uint256 balance = staticIncome + dynamicIncome;

        userDynamicIncomes[account] = 0;
        if(staticIncome > 0){
            //给上级释放动态挖矿奖励  静态奖励的10%
            sumDynamicIncomes(account, staticIncome.div(10), 1);        

            userLastTimes[account] = userLastTimes[account] + cycle * 7 * _staticInterval;
        }

        emit ClaimRewardLog(account, staticIncome, dynamicIncome, balance, cycle);
        return balance;
    }

    bool public bCompensateFlag = true;
    function setCompensateFlag(bool flag) external onlyOwner{
        bCompensateFlag = flag;
    }

    event AcutalLog(address account,uint amount,uint amountU,uint lpValue, uint price, bool isCapital,uint burnAmount, uint giftAmount);
    //LP保价
    function computeAcutal(address account, uint amount) external onlyContractDealer returns (bool isCapital, uint burnAmount, uint giftAmount){
        if(!bCompensateFlag) return (false,0,0);

        uint256 value = getSwapValueUSDT(amount) * 2;
        if(value > userLpValues[account]){//盈利
            isCapital = true;
            burnAmount = (value - userLpValues[account]) * 1e18 / getSwapValueUSDT(1e18);
        }else if(value < userLpValues[account]){//亏损
            //没有超过最低持有时间，亏损不补偿
            if(mintStartTimes[account] != 0 && (block.timestamp - mintStartTimes[account] >= _minHoldTime)){
                isCapital = true;
                giftAmount = (userLpValues[account] - value) * 1e18 / getSwapValueUSDT(1e18);
            }
        }
        emit AcutalLog(account, amount, value, userLpValues[account], getSwapValueUSDT(1e18), isCapital, burnAmount, giftAmount);
        userLpValues[account] = 0;
    }

    event AddUserLog(address account,uint256 amount, uint256 lp);
    //添加原始lp用户 
    function addWhiteUser(address account) external onlyContractDealer{
        lpAddHistoryFlag[account] = true;

        mintUsers.add(account);

        userLpValues[account] = 100e18 * 2;

        emit AddUserLog(account, 0, userLpValues[account]);

    }

    //添加持有lp用户 并记录lp价值
    function addUser(address account, uint256 amount) external onlyContractDealer{
        lpAddHistoryFlag[account] = true;//加池子标记

        mintUsers.add(account);

        userLpValues[account] = getSwapValueUSDT(amount) * 2;

        userLpAmounts[account] = _isAddLiquidity(amount);

        emit AddUserLog(account, 0, userLpValues[account]);
    }

    event ActivateUserLog(address account, uint256 t);
    //激活动态挖坑用户
    function activateUser(address account) external onlyContractDealer{
        if(mintUsers.contains(account)){
            if(mintStartTimes[account] == 0){
                mintStartTimes[account] = block.timestamp;
                userLastTimes[account] = block.timestamp;

                if(userRefers[account] != address(0)){
                    address refer = userRefers[account];
                    lowerValidUsers[refer].add(account);
                    userInviteTotal[refer]++;
                }
                emit ActivateUserLog(account, block.timestamp);
            }                        
        }
    }

    event LogOutUserLog(address account,uint256 t);
    //注销用户
    function logOutUser(address account) external onlyContractDealer{
        lpRemoveHistoryFlag[account] = true;
        mintUsers.remove(account);
        mintStartTimes[account] = 0;

        //查找是否有推荐人
        if(userRefers[account] != address(0)){
            address refer = userRefers[account];
            //从推荐人有效用户列表移除当前用户
            if(lowerValidUsers[refer].contains(account)){
                lowerValidUsers[refer].remove(account);
                //有效用户数量减1
                userInviteTotal[refer]--; 
            }           
        }
        emit LogOutUserLog(account, block.timestamp);
    }

    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        ISwapPair mainPair = ISwapPair(_lp);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _USDT;
        if (tokenOther < _token) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(_lp);
    }

    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        //isAddLP
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(_lp).totalSupply();
        address feeTo = ISwapFactory(_ROUTER.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(_lp).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                    uint256 denominator = rootK * 17 + rootKLast*8;
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            if (amount0 > 0) {
                liquidity = Math.sqrt(amount0 * amount) - 1000;
            }
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        if (balanceOther < rOther) {
            liquidity = (amount * ISwapPair(_lp).totalSupply()) /
            (IERC20(_token).balanceOf(_lp) - amount);
        } else {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = amount * rOther / (rThis - amount);
                require(balanceOther >= amountOther + rOther);
            }
        }
    } 

    function getSwapValueUSDT(uint amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _USDT;
        if (_lp == address(0)) return 0;
        (uint256 reserve1, uint256 reserve2, ) = ISwapPair(_lp).getReserves();
        if (reserve1 == 0 || reserve2 == 0) {
            return 0;
        } else {
            return _ROUTER.getAmountsOut(amount, path)[1];
        }
    }

    function withDrawalToken(address token, address _address, uint amount) external onlyOwner returns(bool){

        IERC20(token).transfer(_address, amount);

        return true;
    }

    function withDrawal(address _address, uint amount) external onlyOwner returns(bool){
        require(address(this).balance >= amount, "ETH: Insufficient balance !");
        payable(_address).transfer(amount);
        return true;
    }
}