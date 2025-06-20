/*
Issued by: Hol Safe Community.
Deflationary token with constant liquidity and decentralized distribution of collaborative economy.
More information: holdsafecrypto.com
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.25;

import {IERC20, ERC20} from "./ERC20.sol";
import {ERC20Burnable} from "./ERC20Burnable.sol";
import {Ownable, Ownable2Step} from "./Ownable2Step.sol";
import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Hold_Safe is ERC20, ERC20Burnable, Ownable2Step, Initializable {
     
    uint16[3] public autoBurnFees;

    uint16 public swapThresholdRatio;
    
    uint256 private _liquidityPending;

    uint16[3] public liquidityFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;
 
    error CannotDepositNativeCoins(address account);

    error InvalidSwapThresholdRatio(uint16 swapThresholdRatio);

    error CannotExceedMaxTotalFee(uint16 buyFee, uint16 sellFee, uint16 transferFee);

    error InvalidAMM(address AMM);
 
    event AutoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event AutoBurned(uint256 amount);

    event SwapThresholdUpdated(uint16 swapThresholdRatio);

    event LiquidityFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event LiquidityAdded(uint amountToken, uint amountCoin, uint liquidity);
    event ForceLiquidityAdded(uint256 leftoverTokens, uint256 unaddedTokens);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);
 
    constructor()
        ERC20(unicode"Hold Safe", unicode"HS")
        Ownable(msg.sender)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0x6A952C2C0EfCe93089734a660856d5c81EcB1c2b;
        
        autoBurnFeesSetup(50, 50, 0);

        updateSwapThreshold(50);

        liquidityFeesSetup(300, 300, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x6A952C2C0EfCe93089734a660856d5c81EcB1c2b);
    }
    
    /*
        This token is not upgradeable. Function afterConstructor finishes post-deployment setup.
    */
    function afterConstructor(address _router) initializer external {
        _updateRouterV2(_router);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
    
    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - autoBurnFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - autoBurnFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - autoBurnFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        autoBurnFees = [_buyFee, _sellFee, _transferFee];

        emit AutoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function updateSwapThreshold(uint16 _swapThresholdRatio) public onlyOwner {
        if (_swapThresholdRatio == 0 || _swapThresholdRatio > 500) revert InvalidSwapThresholdRatio(_swapThresholdRatio);

        swapThresholdRatio = _swapThresholdRatio;
        
        emit SwapThresholdUpdated(_swapThresholdRatio);
    }

    function getSwapThresholdAmount() public view returns (uint256) {
        return balanceOf(pairV2) * swapThresholdRatio / 10000;
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _liquidityPending;
    }

    // Prevent unintended coin transfers
    receive() external payable {
        if (msg.sender != address(routerV2)) revert CannotDepositNativeCoins(msg.sender);
    }

    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();

        _approve(address(this), address(routerV2), tokenAmount);

        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns (uint256 leftover) {
        // Sub-optimal method for supplying liquidity
        uint256 halfAmount = tokenAmount / 2;
        uint256 otherHalf = tokenAmount - halfAmount;

        _swapTokensForCoin(halfAmount);

        uint256 coinBalance = address(this).balance;

        if (coinBalance > 0) {
            (uint amountToken, uint amountCoin, uint liquidity) = _addLiquidity(otherHalf, coinBalance);

            emit LiquidityAdded(amountToken, amountCoin, liquidity);

            return otherHalf - amountToken;
        } else {
            return otherHalf;
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 coinAmount) private returns (uint, uint, uint) {
        _approve(address(this), address(routerV2), tokenAmount);

        return routerV2.addLiquidityETH{value: coinAmount}(address(this), tokenAmount, 0, 0, address(0xdead), block.timestamp);
    }

    function addLiquidityFromLeftoverTokens() external {
        uint256 leftoverTokens = balanceOf(address(this)) - getAllPending();

        uint256 unaddedTokens = _swapAndLiquify(leftoverTokens);

        emit ForceLiquidityAdded(leftoverTokens, unaddedTokens);
    }

    function liquidityFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - liquidityFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - liquidityFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - liquidityFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        liquidityFees = [_buyFee, _sellFee, _transferFee];

        emit LiquidityFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _setAMM(router, true);
        _setAMM(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMM(address AMM, bool isAMM) external onlyOwner {
        if (AMM == pairV2 || AMM == address(routerV2)) revert InvalidAMM(AMM);

        _setAMM(AMM, isAMM);
    }

    function _setAMM(address AMM, bool isAMM) private {
        AMMs[AMM] = isAMM;

        if (isAMM) { 
        }

        emit AMMUpdated(AMM, isAMM);
    }


    function _update(address from, address to, uint256 amount)
        internal
        override
    {
        _beforeTokenUpdate(from, to, amount);
        
        if (from != address(0) && to != address(0)) {
            if (!_swapping && amount > 0 && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
                uint256 fees = 0;
                uint8 txType = 3;
                
                if (AMMs[from] && !AMMs[to]) {
                    if (totalFees[0] > 0) txType = 0;
                }
                else if (AMMs[to] && !AMMs[from]) {
                    if (totalFees[1] > 0) txType = 1;
                }
                else if (!AMMs[from] && !AMMs[to]) {
                    if (totalFees[2] > 0) txType = 2;
                }
                
                if (txType < 3) {
                    
                    uint256 autoBurnPortion = 0;

                    fees = amount * totalFees[txType] / 10000;
                    amount -= fees;
                    
                    if (autoBurnFees[txType] > 0) {
                        autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                        super._update(from, address(0), autoBurnPortion);
                        emit AutoBurned(autoBurnPortion);
                    }

                    _liquidityPending += fees * liquidityFees[txType] / totalFees[txType];

                    fees = fees - autoBurnPortion;
                }

                if (fees > 0) {
                    super._update(from, address(this), fees);
                }
            }
            
            bool canSwap = getAllPending() >= getSwapThresholdAmount() && balanceOf(pairV2) > 0;
            
            if (!_swapping && from != pairV2 && from != address(routerV2) && canSwap) {
                _swapping = true;
                
                if (_liquidityPending > 0) {
                    _swapAndLiquify(_liquidityPending);
                    _liquidityPending = 0;
                }

                _swapping = false;
            }

        }

        super._update(from, to, amount);
        
        _afterTokenUpdate(from, to, amount);
        
    }

    function _beforeTokenUpdate(address from, address to, uint256 amount)
        internal
        view
    {
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}