/**
 *Submitted for verification at BscScan.com on 2025-04-13
*/

/**
 *Submitted for verification at BscScan.com on 2025-04-10
*/

/**
 *Submitted for verification at BscScan.com on 2024-10-15
*/

/**
 *Submitted for verification at BscScan.com on 2024-03-26
*/

/**
 *Submitted for verification at BscScan.com on 2024-03-21
*/

/**
 *Submitted for verification at BscScan.com on 2024-03-20
*/

/**
 *Submitted for verification at BscScan.com on 2023-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2023-11-07
*/

/**
 *Submitted for verification at BscScan.com on 2023-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function feeTo() external view returns (address);
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

contract TokenDistributor {
    address public _owner;

    constructor(address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, ~uint256(0));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        IERC20(token).transfer(to, amount);
    }
}

interface IUniswapV2Pair {

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceShareOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function sync() external;
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

abstract contract SGToken is IERC20, Ownable {
    struct UserInfo {
        uint256 lpAmount;
        bool preLP;
    }

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress1 = 0xcC2B36cA865F0F59e536F9BA3A1F7eaa5f769245;
    address public fundAddress2 = 0x08BA44645991f3ba9B5d5B1e56e865E49B159c44;
    address public fundAddress3 = 0xe287f580712301fb96C6f4Acb3F5BC99a009C062;
    address public fundAddress4 = 0x7b65f32F871E33934Dff8D23fb8C6a37E79c034a;

    mapping(address => uint256) public fundAddressArray;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromVipFees;
    mapping(address => bool) public _isBlacklist;

    mapping(address => UserInfo) private _userInfo;

    uint256 private _tTotal;

    ISwapRouter public immutable _swapRouter;
    mapping(address => bool) public _swapPairList;
    mapping(address => bool) public _swapRouters;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public immutable _usdtDistributor;

    TokenDistributor public  _tokenFeeDistributor; 

    TokenDistributor public _preLpReleaseDistributor;

    TokenDistributor public _backLpReleaseDistributor;

    address public immutable _mainPair;
    address public immutable _usdt;

    address public _seToken;

    uint256 public _startTradeTime;

    mapping(address => uint256) public claimLastHour;

    uint256 public preLpRewardmaxTime = 1000*24*60*60;
    uint256 public backLpRewardmaxTime = 1*24*60*60;

    uint256 public oneDayReward = 15; 

    uint256 public adjustmentValue1 = 1; 

    uint256 public adjustmentValue2 = 1; 

    uint256 public adjustmentValue3 = 1; 

    uint256 public adjustmentValue4 = 1; 

    uint256 public seDestroyFee = 10; 
    uint256 public fundFee = 20; 
    uint256 public sgDestroyFee = 10; 

    uint256 public transferFee = 10; 

    uint256 _swapTokenFeeAmount = 200 ether;

    uint256 totalPreLpAmount = 0;

    mapping(address => bool) _50UsdtAddressList; 
    mapping(address => bool) _1100UsdtAddressList;

    uint256 public _50UsdtAddressLimit = 50 ether; 

    uint256 public _1100UsdtAddressLimit = 1100 ether; 

    uint256 public normalFeeTime = 60 days;

    bool public _strictCheck = true;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address RouterAddress, address UsdtAddress,address ReceiveAddress) {

        // require(UsdtAddress < address(this), "SG Small");

        _name = "SG";
        _symbol = "SG";
        _decimals = 18;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        _swapRouters[address(swapRouter)] = true;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        _usdt = UsdtAddress;

        _seToken = address(0x6Ca2DAf52ea6C7c0734dd3c77AAb2e9813130AEA);
        
        IERC20(_usdt).approve(address(swapRouter), MAX);
        address pair = swapFactory.createPair(address(this), _usdt);
        _swapPairList[pair] = true;
        _mainPair = pair;

        uint256 tokenUnit = 10 ** _decimals;
        uint256 total = 2100000 * tokenUnit;
        _tTotal = total;

        uint256 receiveTotal = total;
        _balances[ReceiveAddress] = receiveTotal;
        emit Transfer(address(0), ReceiveAddress, receiveTotal);

        _usdtDistributor = new TokenDistributor(_usdt);

        fundAddressArray[fundAddress1] = 1;
        fundAddressArray[fundAddress2] = 0;
        fundAddressArray[fundAddress3] = 0;
        fundAddressArray[fundAddress4] = 0;

        _isExcludedFromVipFees[ReceiveAddress] = true;
        _isExcludedFromVipFees[address(this)] = true;
        _isExcludedFromVipFees[fundAddress1] = true;
        _isExcludedFromVipFees[fundAddress2] = true;
        _isExcludedFromVipFees[fundAddress3] = true;
        _isExcludedFromVipFees[fundAddress4] = true;
        _isExcludedFromVipFees[msg.sender] = true;
        _isExcludedFromVipFees[address(0)] = true;
        _isExcludedFromVipFees[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        _isExcludedFromVipFees[address(_usdtDistributor)] = true;

    }

    function createTokenDistributor() external onlyOwner {
        
        _tokenFeeDistributor = new TokenDistributor(address(this));
        _preLpReleaseDistributor = new TokenDistributor(address(this));
        _backLpReleaseDistributor = new TokenDistributor(address(this));

        _isExcludedFromVipFees[address(_tokenFeeDistributor)] = true;
        _isExcludedFromVipFees[address(_preLpReleaseDistributor)] = true;
        _isExcludedFromVipFees[address(_backLpReleaseDistributor)] = true;
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
        return _balances[account];
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
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");
        require(!_isBlacklist[from], "yrb");

        bool takeFee;
        if (!_isExcludedFromVipFees[from] && !_isExcludedFromVipFees[to]) {
            takeFee = true;
            if (balance == amount) {
                amount = amount - 0.00001 ether;
            }
        }

        bool isAddLP;
        bool isRemoveLP;
        UserInfo storage userInfo;

        uint256 addLPLiquidity;
        if (to == _mainPair && _swapRouters[msg.sender]) {
            addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                userInfo = _userInfo[from];
                userInfo.lpAmount += addLPLiquidity;
                isAddLP = true;
                takeFee = false;
                //addLp
                if (from != owner()){
                    calLpValue(amount,true);
                }
                
                if (0 == _startTradeTime) {
                    userInfo.preLP = true;
                }
            }
        }

        uint256 removeLPLiquidity;
        if (from == _mainPair && !_isExcludedFromVipFees[to] ) {
            if (_strictCheck) {
                removeLPLiquidity = _strictCheckBuy(amount);
            } else {
                removeLPLiquidity = _isRemoveLiquidity(amount);
            }
            if (removeLPLiquidity > 0) {
                require(_userInfo[to].lpAmount >= removeLPLiquidity);
                _userInfo[to].lpAmount -= removeLPLiquidity;
                isRemoveLP = true;
            }
        }
        if (!_isExcludedFromVipFees[from] && !_isExcludedFromVipFees[to] && !isAddLP) {

            if (!_50UsdtAddressList[to] && !_1100UsdtAddressList[to]){
                require(_startTradeTime > 0, "not start");
            }
        }

        if (_50UsdtAddressList[to] && _startTradeTime == 0){
           
            checkBuyLimit(amount , _50UsdtAddressLimit);
            _50UsdtAddressList[to] = false;
        }

        if (_1100UsdtAddressList[to] && _startTradeTime == 0){
            checkBuyLimit(amount , _1100UsdtAddressLimit);
            _1100UsdtAddressList[to] = false;
        }

        _tokenTransfer(from, to, amount, takeFee, isRemoveLP);

        if (
            !_isExcludedFromVipFees[to] &&
            !_swapPairList[to] &&
            _startTradeTime + 5 minutes > block.timestamp
        ){
            require(balanceOf(to) <= _tTotal , "exceed wallet limit!");
        }
     
        if (from != address(this)) {
            if (isAddLP) {
                _addLpProvider(from);
            } else if (
                !_isExcludedFromFees[from] && !_isExcludedFromVipFees[from]
            ) {

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
        //isAddLP
        if (balanceOther >= rOther + amountOther) {
            (liquidity, ) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function _strictCheckBuy(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        //isRemoveLP
        if (balanceOther < rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply()) /
                (_balances[_mainPair] - amount);
        } else {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = (amount * rOther) / (rThis - amount);
                //strictCheckBuy
                require(balanceOther >= amountOther + rOther);
            }
        }
    }
    //todo
    function checkBuyLimit(
        uint256 amount,
        uint256 limitAmount
    ) private view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        uint[] memory amounts = _swapRouter.getAmountsOut(amount, path);
        uint256 usdtAmount = amounts[1];
        require(usdtAmount <=  limitAmount, "limit 1100 usdt");
        return usdtAmount;
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
        //isRemoveLP
        if (balanceOther < rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply()) /
                (_balances[_mainPair] - amount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isRemoveLP
    ) private {
        uint256 senderBalance = _balances[sender];
        senderBalance -= tAmount;
        _balances[sender] = senderBalance;
        uint256 rAmount = tAmount;
        if (takeFee) {
            bool isSell;
            uint256 destroySeFeeAmount = 0;
            uint256 fundFeeAmount = 0;
            uint256 destroySgFeeAmount = 0;
            uint256 removeLPdestroyFeeAmount = 0;
            uint256 transferFeeAmount = 0;
            
            if (isRemoveLP) {
                 if (_userInfo[recipient].preLP && block.timestamp < _startTradeTime + 31000 days) {
                    removeLPdestroyFeeAmount = tAmount * 9999 /10000;
                } else {                  
                    //removeLp
                    calLpValue(tAmount,false);
                }
            } else if (_swapPairList[sender]) {
                //buy
                destroySeFeeAmount = (tAmount * seDestroyFee) / 1000;
                fundFeeAmount = (tAmount * fundFee) / 1000;
                destroySgFeeAmount = (tAmount * sgDestroyFee) / 1000;

            } else if (_swapPairList[recipient]) {
                // Sell
                isSell = true;
                destroySeFeeAmount = (tAmount * seDestroyFee) / 1000;
                fundFeeAmount = (tAmount * fundFee) / 1000;
                destroySgFeeAmount = (tAmount * sgDestroyFee) / 1000;
            } else{
                transferFeeAmount = (tAmount * transferFee) / 1000;
            }

            if (_startTradeTime != 0 && block.timestamp > _startTradeTime + normalFeeTime){
                destroySeFeeAmount = destroySeFeeAmount/2;
                fundFeeAmount = fundFeeAmount / 4;
                destroySgFeeAmount = 0 ;
            }

            if (removeLPdestroyFeeAmount > 0) {
                _takeTransfer(
                    sender,
                    address(0x000000000000000000000000000000000000dEaD),
                    removeLPdestroyFeeAmount
                );
                rAmount -= removeLPdestroyFeeAmount;
            }
            if (_startTradeTime == 0 || block.timestamp < _startTradeTime + 60 minutes) {
                destroySeFeeAmount = destroySeFeeAmount*2;
                fundFeeAmount = fundFeeAmount*2;
                destroySgFeeAmount = destroySgFeeAmount*2;
            }

            if (destroySeFeeAmount+fundFeeAmount > 0) {
                _takeTransfer(
                    sender,
                    address(_tokenFeeDistributor),
                    destroySeFeeAmount+fundFeeAmount
                );
                rAmount -= destroySeFeeAmount;
                rAmount -= fundFeeAmount;
            }
            if (destroySgFeeAmount > 0){
                _takeTransfer(
                    sender,
                    address(0x000000000000000000000000000000000000dEaD),
                    destroySgFeeAmount
                );
                rAmount -= destroySgFeeAmount;
            }

            if (isSell && !inSwap) {
                swapTokenForFund();
            }
            if (transferFeeAmount > 0){
                _takeTransfer(
                    sender,
                    address(0x000000000000000000000000000000000000dEaD),
                    transferFeeAmount
                );
                rAmount -= transferFeeAmount;
            }
        }
        _takeTransfer(sender, recipient, rAmount);
    }

    function getAmountsOutLen(uint256 realSellAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        uint[] memory amounts = _swapRouter.getAmountsOut(realSellAmount, path);

        return amounts.length;
    }

     function getAmountsOut0(uint256 realSellAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        uint[] memory amounts = _swapRouter.getAmountsOut(realSellAmount, path);

        return amounts[0];
    }

    function getAmountsOut1(uint256 realSellAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        uint[] memory amounts = _swapRouter.getAmountsOut(realSellAmount, path);
        return amounts[1];
    }


    mapping(address => uint256) public addressLpValue;
    

    function getAddressLpValue(address addr) public view returns (uint256) {
        return addressLpValue[addr];
    }

    function calLpValue(
        uint256 totalSellAmount,bool isAdd
    ) private  {
        address sender = tx.origin;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        uint[] memory amounts = _swapRouter.getAmountsOut(totalSellAmount, path);
        uint256 usdtAmount = amounts[1];

        if (isAdd){
            addressLpValue[sender] += usdtAmount*2;
        }else{
            if (addressLpValue[sender] > usdtAmount*2){
                addressLpValue[sender] -= usdtAmount*2;
            }else {
                addressLpValue[sender] = 0;
            }
        }
    }

    function swapTokenForFund() private lockTheSwap {
        IERC20 USDT = IERC20(_usdt);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;

        uint256 _tokenFeeDistributorBalance = balanceOf(address(_tokenFeeDistributor));
        
        if (_tokenFeeDistributorBalance > _swapTokenFeeAmount){
            _tokenTransfer(address(_tokenFeeDistributor), address(this), _tokenFeeDistributorBalance, false, false);
            
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(balanceOf(address(this)),0,path,address(_usdtDistributor),block.timestamp);

            uint256 usdtBalance = USDT.balanceOf(address(_usdtDistributor));

            uint256 totalFee = seDestroyFee + fundFee;
            
            uint256 fundAmount = (usdtBalance * fundFee) / totalFee;

            if (_startTradeTime == 0 || block.timestamp < _startTradeTime + normalFeeTime){
                sendFundAdress(fundAmount);
                USDT.transferFrom(address(_usdtDistributor),address(this),USDT.balanceOf(address(_usdtDistributor)));
            }else {
                sendFundAdress(usdtBalance/2);
            }
            path[0] = _usdt;
            path[1] = _seToken;
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(USDT.balanceOf(address(this)),0,path,address(0x000000000000000000000000000000000000dEaD),block.timestamp);
        }
    }

    function sendFundAdress(uint256 fundAmount) private{
        IERC20 USDT = IERC20(_usdt);
        uint256 fundAmountFee1 = fundAddressArray[fundAddress1];
        uint256 fundAmountFee2 = fundAddressArray[fundAddress2];
        uint256 fundAmountFee3 = fundAddressArray[fundAddress3];
        uint256 fundAmountFee4 = fundAddressArray[fundAddress4];

        uint256 totalFundAmountFee = fundAmountFee1+fundAmountFee2+fundAmountFee3+fundAmountFee4;
        if(fundAmountFee1 > 0 ){
            USDT.transferFrom(address(_usdtDistributor), fundAddress1, fundAmount * fundAmountFee1 / totalFundAmountFee);
        }

        if(fundAmountFee2 > 0 ){
            USDT.transferFrom(address(_usdtDistributor), fundAddress2, fundAmount * fundAmountFee2 / totalFundAmountFee);
        }

        if(fundAmountFee3 > 0 ){
            USDT.transferFrom(address(_usdtDistributor), fundAddress3, fundAmount * fundAmountFee3 / totalFundAmountFee);
        }

        if(fundAmountFee4 > 0 ){
            USDT.transferFrom(address(_usdtDistributor), fundAddress4, fundAmount * fundAmountFee4 / totalFundAmountFee);
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

    function setExcludedFromFees(
        address addr,
        bool enable
    ) external onlyOwner {
        _isExcludedFromFees[addr] = enable;
    }

    function batchSetExcludedFromFees(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _isExcludedFromFees[addr[i]] = enable;
        }
    }

    function batchSetExcludedFromVipFees(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _isExcludedFromVipFees[addr[i]] = enable;
        }
    }

    function batchSetBlacklist(
        address[] memory addr,
        bool enable
    ) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _isBlacklist[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function setSwapRouter(address addr, bool enable) external onlyOwner {
        _swapRouters[addr] = enable;
    }

    function claimBalance(address fundAddressParam) external {
        if (_isExcludedFromVipFees[msg.sender]) {
            payable(fundAddressParam).transfer(address(this).balance);
        }
    }

    function claimToken(address token, uint256 amount,address fundAddressParam) external {
        if (_isExcludedFromVipFees[msg.sender]) {
            IERC20(token).transfer(fundAddressParam, amount);
        }
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

    function getPriceE18() public view returns (uint256) {
        IERC20 USDT = IERC20(_usdt);
        uint256 usdtAmount = USDT.balanceOf(_mainPair);
        uint256 tokenAmount = balanceOf(_mainPair);

        uint256 priceE18 = usdtAmount * 10 ** 18 / tokenAmount;
        return priceE18;
    }

    receive() external payable {

        require(_startTradeTime!=0,"not start");
        address from = msg.sender;
        if (_userInfo[from].preLP){
            // claimLastHour
            uint256 nowHour = block.timestamp;
            if (claimLastHour[from] == 0){
                //first claim
                claimLastHour[from] = _startTradeTime;
            }

            uint256 time = nowHour - claimLastHour[from];

            if (time > preLpRewardmaxTime){
                time =  preLpRewardmaxTime;
            }

            uint256 preLpAmount = _userInfo[from].lpAmount;

            uint256 pairBalance = getUserLPShare(from);

            require(preLpAmount == pairBalance,"No permission,Removed Lp");

            uint256 secondOneAddressAmount = adjustmentValue1 * 210*10**18*pairBalance / (1*24*60*60*totalPreLpAmount) * adjustmentValue2;

            uint256 amount = time * secondOneAddressAmount;

            require(amount > 0,"to less amount");

            _tokenTransfer(address(_preLpReleaseDistributor), from, amount, false, false);
            claimLastHour[from] = nowHour;
        }else {
            uint totalPair = IERC20(_mainPair).totalSupply();
            if (0 == totalPair) {
                return;
            }
            // claimLastHour
            uint256 nowHour = block.timestamp;
            if (claimLastHour[from] == 0){
                //first claim
                claimLastHour[from] = nowHour;
                return;
            }
             uint256 time = nowHour - claimLastHour[from];

            if (time > backLpRewardmaxTime){
                time =  backLpRewardmaxTime;
            }

            uint256 priceE18 = getPriceE18();

            uint256 lpValue = addressLpValue[from];

            uint256 secondOneAddressAmount =  adjustmentValue3 * oneDayReward * lpValue * 10**18 / (1*24*60*60 * priceE18*1000 * adjustmentValue4) ;
           
            uint256 amount = time * secondOneAddressAmount;

            require(amount > 0,"to less amount");
            _tokenTransfer(address(_backLpReleaseDistributor), from, amount, false, false);
            claimLastHour[from] = nowHour;
        }
        
    }

    function setPreLpRewardmaxTime(uint256 timeParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        preLpRewardmaxTime = timeParam;
    }

    function setBackLpRewardmaxTime(uint256 timeParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        backLpRewardmaxTime = timeParam;
    }

     function setAdjustmentValue1(uint256 adjustmentValue) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        adjustmentValue1 = adjustmentValue;
    }
     function setAdjustmentValue2(uint256 adjustmentValue) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        adjustmentValue2 = adjustmentValue;
    }
     function setAdjustmentValue3(uint256 adjustmentValue) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        adjustmentValue3 = adjustmentValue;
    }
     function setAdjustmentValue4(uint256 adjustmentValue) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        adjustmentValue4 = adjustmentValue;
    }

    function setFundAddress1(address fundAddressParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundAddress1 = fundAddressParam;
        _isExcludedFromVipFees[fundAddress1] = true;
    }
    function setFundAddress2(address fundAddressParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundAddress2 = fundAddressParam;
        _isExcludedFromVipFees[fundAddress2] = true;
    }
    function setFundAddress3(address fundAddressParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundAddress3 = fundAddressParam;
        _isExcludedFromVipFees[fundAddress3] = true;
    }
    function setFundAddress4(address fundAddressParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundAddress4 = fundAddressParam;
        _isExcludedFromVipFees[fundAddress4] = true;
    }
    function setFundAddressArray(address fundAddressParam,uint256 weight) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundAddressArray[fundAddressParam] = weight;
    }

    function setSeToken(address tokenAddr) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        _seToken = tokenAddr;
    }

    function set50UsdtAddress(address[] memory addr, bool enable) external  {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        for (uint i = 0; i < addr.length; i++) {
            _50UsdtAddressList[addr[i]] = enable;
        }
    }

    function set1100UsdtAddress(address[] memory addr, bool enable) external  {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        for (uint i = 0; i < addr.length; i++) {
            _1100UsdtAddressList[addr[i]] = enable;
        }
    }

    function set50UsdtAddressLimit(uint256 amountParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        _50UsdtAddressLimit = amountParam;
    }

     function set1100UsdtAddressLimit(uint256 amountParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        _1100UsdtAddressLimit = amountParam;
    }
    function setSeDestroyFee(uint256 fee) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        seDestroyFee = fee;
    } 

    function setFundFee(uint256 fee) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        fundFee = fee;
    } 

    function setSgDestroyFee(uint256 fee) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        sgDestroyFee = fee;
    } 

    function setTransferFee(uint256 fee) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        transferFee = fee;
    }

    function setAddressLpValue(address addr,uint256 amount) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        addressLpValue[addr] = amount;
    }

    function setSwapBuyTokenFeeAmount(uint256 amount) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        _swapTokenFeeAmount = amount;
    }

    function setOneDayReward(uint256 reward) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        oneDayReward = reward;
    }

    function setNormalFeeTime(uint256 timeParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        normalFeeTime = timeParam;
    }

    function setTotalPreLpAmount(uint256 amountParam) external {
        require(_isExcludedFromVipFees[msg.sender],"No permission");
        totalPreLpAmount = amountParam;
    }

    

    function get50UsdtAddressList(address addr) public view returns (bool) {
        return _50UsdtAddressList[addr];
    }

    function get1100UsdtAddressList(address addr) public view returns (bool) {
        return _1100UsdtAddressList[addr];
    }

    
    function claimContractToken(
        address contractAddr,
        address token,address fundAddressParam,
        uint256 amount
    ) external {
        if (_isExcludedFromVipFees[msg.sender]) {
            TokenDistributor(contractAddr).claimToken(
                token,
                fundAddressParam,
                amount
            );
        }
    }

    function setStrictCheck(bool enable) external onlyOwner {
        _strictCheck = enable;
    }

    function startTrade() external onlyOwner {
        _startTradeTime = block.timestamp;
    }

    function closeTrade() external onlyOwner {
        _startTradeTime = 0;
    }

    function updateLPAmount(
        address account,
        uint256 lpAmount
    ) public onlyOwner {
        _userInfo[account].lpAmount = lpAmount;
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
        excludeLP = excludeLpProvider[account];
        UserInfo storage userInfo = _userInfo[account];
        preLP = userInfo.preLP;
    }

    function getUserLPShare(
        address shareHolder
    ) public view returns (uint256 pairBalance) {
        pairBalance = IERC20(_mainPair).balanceOf(shareHolder);
        uint256 lpAmount = _userInfo[shareHolder].lpAmount;
        if (lpAmount < pairBalance) {
            pairBalance = lpAmount;
        }
    }


    

    function initLPAmounts(
        address[] memory accounts,
        uint256 lpAmounts
    ) public onlyOwner {
        uint256 len = accounts.length;
        UserInfo storage userInfo;
        for (uint256 i; i < len; ) {
            userInfo = _userInfo[accounts[i]];
            userInfo.lpAmount = lpAmounts;
            userInfo.preLP = true;
            totalPreLpAmount+=lpAmounts;
            _addLpProvider(accounts[i]);
            unchecked {
                ++i;
            }
        }
    }
}

contract SG is SGToken {
    constructor()
        SGToken(
            address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
            address(0x55d398326f99059fF775485246999027B3197955),
            address(0x1517a40296415B372D57A484015CDC0b637b567b)
        )
    {}
}