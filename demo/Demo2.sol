// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapRouter {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IToken {
    function getInviter(address user) external view returns (address);
    function MAX_BUY_AMOUNT() external view returns (uint256);
    function QUEUE_DAY() external view returns (uint256);
    function getBuyFee() external view returns (uint256, uint256);
    function buyUsdtAmountByUser(address account) external view returns (uint256);
    function isActiveByUser(address account) external view returns (bool);
    function _lpDistributor() external view returns (address);
    function _inviterDistributor() external view returns (address);
    function distributeInviterReward(address user, uint256 totalAmount) external returns (bool);
    function setUserBuyUsdtAmount(address account, uint256 buyUsdtAmount) external returns (bool);
    function setUserLastUpdatedTime(address account, uint256 lastUpdatedTime) external returns (bool);
    function setUserActive(address account, bool isActive) external returns (bool);
}

contract Miner is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct OrderInfo {
        address account; // 用户地址
        uint256 receiveBnbAmount; // 支付BNB数量
        uint256 swapUsdtAmount; // 兑换USDT数量
        uint256 receiveTimestamp; // 支付时间
        uint256 swapTimestamp; // 兑换时间
    }

    uint256 public MAX_SLIPPAGE = 50; // 0.5%
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant GAS_FEE = 0.0024 ether;

    uint256 public totalOrderCount; // 当前订单数量
    uint256 public finishOrderCount; // 已完成订单数量
    bool public autoBuy;

    mapping(uint256 => OrderInfo) public orderInfo;

    address public immutable _token;
    address public immutable _wbnb;
    address public immutable _usdt;
    ISwapRouter public immutable _swapRouter;

    event CreateOrder(
        address indexed user,
        uint256 indexed orderId,
        uint256 receiveBnbAmount,
        uint256 swapUsdtAmount,
        uint256 receiveTimestamp
    );
    event BuyOrder(uint256 indexed orderId);
    event GasFeeUpdated(uint256 newGasFee);
    event QueueDurationUpdated(uint256 newDuration);
    event SlippageUpdated(uint256 newSlippage);
    event MaxBuyAmountUpdated(uint256 newAmount);

    constructor(
        address token,
        address wbnb,
        address usdt,
        address swapRouter
    ) Ownable(msg.sender) {
        _token = token;
        _wbnb = wbnb;
        _usdt = usdt;
        _swapRouter = ISwapRouter(swapRouter);

        autoBuy = true;

        // Approve unlimited USDT to swap router
        IERC20(usdt).forceApprove(address(swapRouter), type(uint256).max);
    }

    receive() external payable nonReentrant {
        require(msg.value > GAS_FEE, "Miner: Insufficient gas fee");

        uint256 unitPrice = _getAmountsOut();
        require(unitPrice > 0, "Miner: Invalid price");

        uint256 ethAmount = msg.value - GAS_FEE;
        uint256 tokenValue = (ethAmount * unitPrice) / 1 ether;

        IToken token = IToken(_token);

        require(token.getInviter(msg.sender) != address(0), "no bind");

        uint256 maxBuyAmount = token.MAX_BUY_AMOUNT();
        uint256 buyUsdtAmount = token.buyUsdtAmountByUser(msg.sender);
        bool active = token.isActiveByUser(msg.sender);

        require(
            buyUsdtAmount + tokenValue <= maxBuyAmount,
            "Miner: Exceed max limit"
        );

        token.setUserBuyUsdtAmount(msg.sender, tokenValue);
        if (!active) token.setUserActive(msg.sender, true);

        (bool success, ) = owner().call{value: GAS_FEE}("");
        require(success, "Miner: Gas transfer failed");

        address[] memory path = _getPath();
        uint256 minAmountOut = (tokenValue * (BASIS_POINTS - MAX_SLIPPAGE)) / BASIS_POINTS;
        
        uint256 balanceBefore = IERC20(_usdt).balanceOf(address(this));
        _swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minAmountOut,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedUsdt = IERC20(_usdt).balanceOf(address(this)) - balanceBefore;
        require(receivedUsdt >= minAmountOut, "Miner: High slippage");

        uint256 currentOrderId = ++totalOrderCount;
        orderInfo[currentOrderId] = OrderInfo({
            account: msg.sender,
            receiveBnbAmount: msg.value,
            swapUsdtAmount: receivedUsdt,
            receiveTimestamp: block.timestamp,
            swapTimestamp: 0
        });

        if (autoBuy) {
            _buyOrder();
        }
       

        emit CreateOrder(msg.sender, currentOrderId, msg.value, receivedUsdt, block.timestamp);
    }

    function buyOrder() external nonReentrant returns (bool) {
        _buyOrder();
        return true;
    }

    function _buyOrder() private {
        if (totalOrderCount == 0) return;
        uint256 currentOrderId = finishOrderCount + 1;

        OrderInfo storage info = orderInfo[currentOrderId];
        if (info.swapTimestamp > 0) return;

        IToken token = IToken(_token);
        uint256 queueDay = token.QUEUE_DAY();
        (uint256 lpFee, uint256 inviterFee) = token.getBuyFee();
        address lpDistributor = token._lpDistributor();
        address inviteDistributor = token._inviterDistributor();

        if (block.timestamp < info.receiveTimestamp + queueDay) return;

        info.swapTimestamp = block.timestamp;

        // Process LP fee
        uint256 lpAmount = (info.swapUsdtAmount * lpFee) / BASIS_POINTS;
        IERC20(_usdt).safeTransfer(lpDistributor, lpAmount);

        // Process inviter rewards
        uint256 inviterAmount = (info.swapUsdtAmount * inviterFee) / BASIS_POINTS;
        IERC20(_usdt).safeTransfer(inviteDistributor, inviterAmount);
        token.distributeInviterReward(info.account, inviterAmount);

        // Swap remaining USDT to tokens
        uint256 swapAmount = info.swapUsdtAmount - lpAmount - inviterAmount;
        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = _token;

        // uint256 minTokenAmount = _calculateMinTokenAmount(swapAmount);
        
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 receivedToken = IERC20(_token).balanceOf(address(this)) - balanceBefore;
        IERC20(_token).safeTransfer(info.account, receivedToken);

        token.setUserLastUpdatedTime(info.account, block.timestamp);

        finishOrderCount = currentOrderId;

        emit BuyOrder(currentOrderId);
    }

    function setAutoBuy(bool b) external onlyOwner {
        autoBuy = b;
    }

    function setMaxSlippage(uint256 newSlippage) external onlyOwner {
        MAX_SLIPPAGE = newSlippage;
        emit SlippageUpdated(newSlippage);
    }

    function _getAmountsOut() internal view returns (uint256) {
        address[] memory path = _getPath();
        try _swapRouter.getAmountsOut(1 ether, path) returns (
            uint[] memory prices
        ) {
            return prices[1];
        } catch {
            revert("Miner: Price query failed");
        }
    }

    function _calculateMinTokenAmount(uint256 usdtAmount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = _token;
        
        try _swapRouter.getAmountsOut(usdtAmount, path) returns (
            uint[] memory amounts
        ) {
            return (amounts[1] * (BASIS_POINTS - MAX_SLIPPAGE)) / BASIS_POINTS;
        } catch {
            revert("Miner: Token price query failed");
        }
    }


    function _getPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _wbnb;
        path[1] = _usdt;
        return path;
    }

    function rescueTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    function rescueETH(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }
}