// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDEXRouter {
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
	function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
	function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
	function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract BuidlFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
	
	IDEXRouter public router;
	IERC20 public USDT;
	IERC20 public BUIDL;
	IERC20 public WETH;
	
	bool public bonusStatus;
	
	address public liquidityWallet;
	
	uint256 private minStaking;
	uint256 private minStakingForLevelROI;
	uint256 private dailyROI;
	uint256 private divider;
	uint256 private maxReturn;
	uint256 private ROITimestamp;
	
    uint256 private totalStaked;
	uint256 private totalWithdrawn;
	uint256 private activeUsers;
	
	uint256[4] public levelWiseROI;
	
	uint256[10] public rankWiseReward;
	uint256[10] public rankWiseMatching;
	
    struct User {
		uint256 amount;
		uint256 activeStake;
		uint256 ROIStake;
		uint256 withdraw;
		uint256 pending;
		uint256 directTeam;
		uint256 stakeByDirect;
		uint256 totalTeam;
		uint256 stakeByTeam;
		uint256 rankBonus;
		uint256 levelIncome;
		string referralCode;
		string sponsorCode;
		Stake[] stakes;
		Withdraw[] withdraws;
		address[] myTeam;
    }
	
	struct Stake {
		uint256 amount;
		uint256 ROI;
		uint256 withdraw;
		uint256 stakeTime;
		uint256 lastClaimedTime;
    }
	
	struct Withdraw {
		uint256 amount;
		uint256 fromLevelROI;
		uint256 withdrawTime;
		uint256 withdrawType;
    }
	
	struct LevelInfo {
		uint256 buidler;
		uint256 staked;
		uint256 stakeCount;
		uint256 stakers;
    }
	
    mapping(address => User) public users;
	mapping(string => address) public referralAddress;
	mapping(address => mapping(uint256 => LevelInfo)) public levelInfo;
	
    event Staked(address indexed user, uint256 amount, uint256 time);
	event RewardClaimed(address indexed user, uint256 amount, uint256 time);
	event ClearStuckBalance(address indexed receiver);
	event LiquidityWalletChanged(address wallet);
	event DailyROIUpdated(uint256 ROI);
	event EmergencyWithdrawal(address owner, uint256 balance);
	event BonusStatusUpdated(bool status);
	
    constructor(address _owner) {
		require(address(_owner) != address(0), "Zero address");
		
		router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		
	    USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
		BUIDL = IERC20(0x4A67A307E6c6F35117ecfDD4A2767095EB4c2B4E);
		WETH = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
		
		liquidityWallet = address(0x81e6717D1173bd252A994a5e98D2a6a065Aeff30);
		
		maxReturn = 3;
		dailyROI = 60;
		divider = 10000;
		ROITimestamp = 86400;
		
		bonusStatus = true;
		
		minStaking = 10 * 10**18;
		minStakingForLevelROI = 100 * 10**18;
		
		levelWiseROI = [2500, 3000, 4000, 5000];
		
		rankWiseReward = [50 * 10**18, 100 * 10**18, 250 * 10**18, 500 * 10**18, 1000 * 10**18, 2500 * 10**18, 5000 * 10**18, 10000 * 10**18, 25000 * 10**18, 50000 * 10**18];
		rankWiseMatching = [1000 * 10**18, 2000 * 10**18, 5000 * 10**18, 10000 * 10**18, 20000 * 10**18, 50000 * 10**18, 100000 * 10**18, 200000 * 10**18, 500000 * 10**18, 1000000 * 10**18];
		_transferOwnership(address(_owner));
	}
	
	receive() external payable {}
	
    function stakeUSDT(uint256 amount, string memory sponsorCode, string memory referralCode) external nonReentrant{
		require(bytes(sponsorCode).length > 0, "Sponsor code is not correct");
		require(bytes(referralCode).length > 0, "Referral code is not correct");
		require(amount % minStaking == 0 && amount >= minStaking, "Stake amount must be in multiples of the minimum stake amount");
		require(msg.sender.code.length == 0, "Only EOA address is allowed");
		require(referralAddress[sponsorCode] != address(msg.sender), "Sponsor and staker can't be same");
		require(referralAddress[referralCode] == address(msg.sender) || referralAddress[referralCode] == address(0) , "Referral code already used by another user");
		if(totalStaked > 0)
		{
			require(referralAddress[sponsorCode] != address(0), "You cannot join without a sponsor");
		}
		
		require(USDT.balanceOf(address(msg.sender)) >= amount, "USDT is not available to stake");
	    require(USDT.allowance(address(msg.sender), address(this)) >= amount, "Make sure to add enough USDT allowance");
		
		USDT.safeTransferFrom(msg.sender, address(this), amount);
		
		stake(msg.sender, amount, sponsorCode, referralCode);
		
		swapAndLiquifyUSDT(amount);
        emit Staked(msg.sender, amount, block.timestamp);
    }
	
	function stakeBUIDL(uint256 amount, string memory sponsorCode, string memory referralCode) external nonReentrant {
		require(bytes(sponsorCode).length > 0, "Sponsor code is not correct");
		require(bytes(referralCode).length > 0, "Referral code is not correct");
		require(amount % minStaking == 0 && amount >= minStaking, "Stake amount must be in multiples of the minimum stake amount");
		require(msg.sender.code.length == 0, "Only EOA address is allowed");
		require(referralAddress[sponsorCode] != address(msg.sender), "Sponsor and staker can't be same");
		require(referralAddress[referralCode] == address(msg.sender) || referralAddress[referralCode] == address(0) , "Referral code already used by another user");
		if(totalStaked > 0)
		{
			require(referralAddress[sponsorCode] != address(0), "You cannot join without a sponsor");
		}
		
		uint256 required = getQuotesBUIDL(amount);
		
		require(BUIDL.balanceOf(address(msg.sender)) >= required, "BUIDL is not available to stake");
	    require(BUIDL.allowance(address(msg.sender), address(this)) >= required, "Make sure to add enough BUIDL allowance");
		
		BUIDL.safeTransferFrom(msg.sender, address(this), required);
		
		stake(msg.sender, amount, sponsorCode, referralCode);
		
		swapAndLiquifyBUIDL(required);
        emit Staked(msg.sender, amount, block.timestamp);
    }
	
	function stakeBNB(uint256 amount, string memory sponsorCode, string memory referralCode) external payable nonReentrant {
		require(bytes(sponsorCode).length > 0, "Sponsor code is not correct");
		require(bytes(referralCode).length > 0, "Referral code is not correct");
		require(amount % minStaking == 0 && amount >= minStaking, "Stake amount must be in multiples of the minimum stake amount");
		require(msg.sender.code.length == 0, "Only EOA address is allowed");
		require(referralAddress[sponsorCode] != address(msg.sender), "Sponsor and staker can't be same");
		require(referralAddress[referralCode] == address(msg.sender) || referralAddress[referralCode] == address(0) , "Referral code already used by another user");
		if(totalStaked > 0)
		{
			require(referralAddress[sponsorCode] != address(0), "You cannot join without a sponsor");
		}
		
		uint256 required = getQuotesBNB(amount);
	    require(msg.value >= required, "BNB is not available to stake");
		
		stake(msg.sender, amount, sponsorCode, referralCode);
		
		swapAndLiquifyBNB(required);
        emit Staked(msg.sender, amount, block.timestamp);
    }
	
	function stake(address buidler, uint256 amount, string memory sponsorCode, string memory referralCode) internal {
		User storage user = users[buidler];
		
		if(bytes(user.referralCode).length == 0)
		{
			referralAddress[referralCode] = msg.sender;
			user.referralCode = referralCode;
	    }
		
		if(bytes(user.sponsorCode).length == 0 && referralAddress[sponsorCode] != address(0))
		{
		    if(keccak256(bytes(users[referralAddress[sponsorCode]].sponsorCode)) != keccak256(bytes(user.referralCode)))
			{
				user.sponsorCode = sponsorCode;
			}
		}
		
		user.stakes.push(Stake(
			amount,
            dailyROI,   			
			0, 
			block.timestamp,
			block.timestamp
		));

		bool newBuidler;
		
		if(user.amount == 0)
		{
			address sponsor = referralAddress[user.sponsorCode];
			users[sponsor].myTeam.push(msg.sender);
		}
		if((user.amount * maxReturn) == user.withdraw) 
		{
			activeUsers++;
			newBuidler = true;
		}
		
		bool isUnique;
		if(amount >= minStakingForLevelROI)
		{
			user.ROIStake++;
			if(user.ROIStake == 1)
			{
				isUnique = true;
			}
		}
		
		user.amount += amount;
		user.activeStake += amount;
		totalStaked += amount;
		addMatchingAmount(buidler, amount, newBuidler, isUnique);
	}
	
	function pendingToWithdraw(address buidler) public view returns (uint256, uint256) {
        User storage user = users[buidler];
		
        uint256 amount = 0;
        uint256 dividend = 0;
		uint256 pending = user.pending;
		
        for (uint256 i = 0; i < user.stakes.length; i++) {
		
			uint256 ROI = user.stakes[i].ROI;
			uint256 investment = user.stakes[i].amount;
			uint256 withdraw = user.stakes[i].withdraw;
			uint256 lastClaimedTime = user.stakes[i].lastClaimedTime;
			uint256 currentClaimedTime = block.timestamp;
			
			if(withdraw < (investment * maxReturn)) 
			{
				dividend = ((((investment * ROI) / divider) * (currentClaimedTime - lastClaimedTime)) / ROITimestamp);
				
				if((withdraw + dividend + pending) > (investment * maxReturn)) 
				{
					uint256 limitRemaining = (investment * maxReturn) - (withdraw);
					uint256 pendingRemaining = pending > limitRemaining ? limitRemaining : pending;
					
					dividend = limitRemaining;
					pending -= pendingRemaining;
				}
				else
				{
					dividend += pending;
					pending = 0;
				}
				amount += dividend;
			}
        }
		return (amount, user.pending);
    }
	
	function withdrawReward() external nonReentrant {
        User storage user = users[msg.sender];
		
		uint256 amount = 0;
        uint256 dividend = 0;
		uint256 removeFromMatching = 0;
		uint256 ROIlimitComplete = 0;
		uint256 pending = user.pending;
		
        for (uint256 i = 0; i < user.stakes.length; i++) 
		{
			uint256 ROI = user.stakes[i].ROI;
			uint256 investment = user.stakes[i].amount;
			uint256 withdraw = user.stakes[i].withdraw;
			uint256 lastClaimedTime = user.stakes[i].lastClaimedTime;
			uint256 currentClaimedTime = block.timestamp;
			
			if(withdraw < (investment * maxReturn)) {
			
				dividend = ((((investment * ROI) / divider) * (currentClaimedTime - lastClaimedTime)) / ROITimestamp);
				
				if((withdraw + dividend + pending) > (investment * maxReturn)) 
				{
					uint256 limitRemaining = (investment * maxReturn) - (withdraw);
					uint256 pendingRemaining = pending > limitRemaining ? limitRemaining : pending;
					
					dividend = limitRemaining;
					pending -= pendingRemaining;
					removeFromMatching += investment;
					
					if(investment >= minStakingForLevelROI)
					{
						ROIlimitComplete++;
						user.ROIStake--;
					}
				} 
				else 
				{
					dividend += pending;
					pending = 0;
				}
				user.stakes[i].withdraw += dividend;
				user.stakes[i].lastClaimedTime = block.timestamp;
				amount += dividend;
			}
        }
		require(amount > 0, "User has no dividend");
		
		user.withdraws.push(Withdraw(
			amount, 
			user.pending,
			block.timestamp,
			0
		));
		
		uint256 toLevelROI = amount - user.pending;
		
		user.activeStake -= removeFromMatching;
		user.withdraw += amount;
		user.pending = 0;
		
		totalWithdrawn += amount;
		
		bool limitComplete;
		if(user.withdraw == (user.amount * maxReturn))
		{
			activeUsers--;
			limitComplete = true;
		}
		
		if(removeFromMatching > 0)
		{
			removeMatchingAmount(msg.sender, removeFromMatching, limitComplete, ROIlimitComplete);
		}
		distributionLevelROI(msg.sender, toLevelROI);
		
		uint256 tokens = getQuotesBUIDL(amount);
		
		require(BUIDL.balanceOf(address(this)) >= tokens, "BUIDL is not available to withdraw");
        BUIDL.safeTransfer(msg.sender, tokens);
        emit RewardClaimed(msg.sender, amount, block.timestamp);
    }
	
	function withdrawBonus(address topSponsor) external nonReentrant {
		User storage user = users[msg.sender];
		
		require(bonusStatus, "Bonus withdraw is not active");
		require(user.activeStake > 0, "No active stake found");
		require(keccak256(bytes(user.referralCode)) == keccak256(bytes(users[topSponsor].sponsorCode)), "TopSponsor is not correct");
		
		uint256 powerLeg = users[topSponsor].stakeByTeam + users[topSponsor].activeStake;
		uint256 otherLeg = users[msg.sender].stakeByTeam - powerLeg;
		
		uint256 payableAmount = 0;
		
		for (uint256 i = 0; i < rankWiseMatching.length; i++)
		{
            if (powerLeg >= rankWiseMatching[i] && otherLeg >= rankWiseMatching[i])
			{
				payableAmount += rankWiseReward[i];
            }
        }
		
		payableAmount -= user.rankBonus;
		user.rankBonus += payableAmount;
		
		totalWithdrawn += payableAmount;
		
		user.withdraws.push(Withdraw(
			payableAmount, 
			0,
			block.timestamp,
			1
		));
		
		uint256 tokens = getQuotesBUIDL(payableAmount);
		
		require(BUIDL.balanceOf(address(this)) >= tokens, "BUIDL is not available to withdraw");
        BUIDL.safeTransfer(msg.sender, tokens);
		emit RewardClaimed(msg.sender, payableAmount, block.timestamp);
	}
	
	function distributionLevelROI(address buidler, uint256 amount) internal {
	    address sponsor = referralAddress[users[buidler].sponsorCode];
		
		uint256 missedCommission = (amount * 14500) / (divider);
		for(uint256 i=0; i < levelWiseROI.length; i++)	
		{
			if(sponsor != address(0)) 
			{
			    uint256 eligibleLevel = checkEligibleROILevel(sponsor);
				if(eligibleLevel >= (i + 1))
				{
					uint256 dividend = (amount * levelWiseROI[i]) / (divider);
					uint256 pending = (users[sponsor].amount * maxReturn) - (users[sponsor].withdraw + users[sponsor].pending);
					
				    if(dividend > pending)
				    {
						missedCommission -= pending;
						users[sponsor].pending += pending;
						users[sponsor].levelIncome += pending;
				    }
				    else
				    {
						missedCommission -= dividend;
						users[sponsor].pending += dividend;
						users[sponsor].levelIncome += dividend;
				    }
				}
			} 
			else  
			{
				break;
			}
			sponsor = referralAddress[users[sponsor].sponsorCode];
		}
		
		if(missedCommission > 0)
		{
			uint256 tokens = getQuotesBUIDL(missedCommission);
			require(BUIDL.balanceOf(address(this)) >= tokens, "BUIDL is not available to withdraw");
			BUIDL.safeTransfer(owner(), tokens);
		}
	}
	
	function addMatchingAmount(address buidler, uint256 amount, bool newBuidler, bool unique) internal {
	    address sponsor = referralAddress[users[buidler].sponsorCode];
		
		for(uint256 i=0; i < 256; i++) {
			if(sponsor != address(0)) 
			{
			    if(levelWiseROI.length > i)
				{
					levelInfo[sponsor][i].staked += amount;
					if(amount >= minStakingForLevelROI)
					{
						levelInfo[sponsor][i].stakeCount++;
						if(unique)
						{
							levelInfo[sponsor][i].stakers++;
						}
					}
					if(newBuidler)
					{
						levelInfo[sponsor][i].buidler++;
					}
				}
			    if(i == 0)
				{
					users[sponsor].stakeByDirect += amount;
					if(newBuidler)
					{
						users[sponsor].directTeam++;
					}
				}
				users[sponsor].stakeByTeam += amount;
				if(newBuidler)
				{
					users[sponsor].totalTeam++;
				}
			} 
			else  
			{
				break;
			}
			sponsor = referralAddress[users[sponsor].sponsorCode];
		}
	}
	
	function removeMatchingAmount(address buidler, uint256 amount, bool limitComplete, uint256 ROIlimitComplete) internal {
	    address sponsor = referralAddress[users[buidler].sponsorCode];
		
		for(uint256 i=0; i < 256; i++)  {
			if(sponsor != address(0)) 
			{
				if(levelWiseROI.length > i)
				{
					levelInfo[sponsor][i].staked -= amount;
					levelInfo[sponsor][i].stakeCount -= ROIlimitComplete;
					if(limitComplete)
					{
						levelInfo[sponsor][i].buidler--;
					}
					if(ROIlimitComplete > 0 && users[buidler].ROIStake == 0)
					{
						levelInfo[sponsor][i].stakers--;
					}
				}
				if(i == 0)
				{
					users[sponsor].stakeByDirect -= amount;
					if(limitComplete)
					{
						users[sponsor].directTeam--;
					}
				}
				users[sponsor].stakeByTeam -= amount;
				if(limitComplete)
				{
					users[sponsor].totalTeam--;
				}
			} 
			else  
			{
				break;
			}
			sponsor = referralAddress[users[sponsor].sponsorCode];
		}
	}
	
	function checkEligibleROILevel(address buidler) internal view returns (uint256) {
		uint256 ROIStaking = levelInfo[buidler][0].stakers;
		
		if(ROIStaking >= 10) 
		{
			return 4;
		} 
		else if(ROIStaking >= 5) 
		{
			return 3;
		} 
		else if(ROIStaking >= 2) 
		{
			return 2;
		} 
		else if(ROIStaking >= 1) 
		{
			return 1;
		} 
		else 
		{
			return 0;
		}
	}
	
	function swapAndLiquifyUSDT(uint256 amount) private {
	    uint256 oldBalance = address(this).balance;
		swapUSDTForBNB(amount);
		uint256 newBalance = address(this).balance - oldBalance;
		
		uint256 half = newBalance / 2;
		uint256 otherHalf = newBalance - half;
		
		uint256 oldBUIDLBalance = BUIDL.balanceOf(address(this));
		swapBNBForBUIDL(half);
		uint256 newBUIDLBalance = BUIDL.balanceOf(address(this)) - oldBUIDLBalance;
		
		addLiquidity(newBUIDLBalance, otherHalf);
    }
	
	function swapAndLiquifyBUIDL(uint256 amount) private {
	    uint256 half = amount / 2;
		uint256 otherHalf = amount - half;
		
	    uint256 oldBalance = address(this).balance;
		swapBUIDLForBNB(half);
		uint256 newBalance = address(this).balance - oldBalance;
		
		addLiquidity(otherHalf, newBalance);
    }
	
	function swapAndLiquifyBNB(uint256 amount) private {
	    uint256 half = amount / 2;
		uint256 otherHalf = amount - half;
		
		uint256 oldBalance = BUIDL.balanceOf(address(this));
		swapBNBForBUIDL(half);
		uint256 newBalance = BUIDL.balanceOf(address(this)) - oldBalance;
		
		addLiquidity(newBalance, otherHalf);
    }
	
	function swapUSDTForBNB(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(WETH);
		
		USDT.approve(address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function swapBUIDLForBNB(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(BUIDL);
        path[1] = address(WETH);
		
		BUIDL.approve(address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function swapBNBForBUIDL(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(BUIDL);
		
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function addLiquidity(uint256 token, uint256 BNB) private {
		BUIDL.approve(address(router), token);
		
        router.addLiquidityETH{value: BNB}(
            address(BUIDL),
            token,
            0,
            0,
            address(liquidityWallet),
            block.timestamp
        );
    }
	
	function getQuotesBUIDL(uint256 amountIn) public view returns (uint256) {
		address[] memory path = new address[](3);
		path[0] = address(USDT);
		path[1] = address(WETH);
		path[2] = address(BUIDL);
		
		uint256[] memory required = router.getAmountsOut(amountIn, path);
		return required[2];
    }
	
	function getQuotesBNB(uint256 amountIn) public view returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(USDT);
		path[1] = address(WETH);
		
		uint256[] memory required = router.getAmountsOut(amountIn, path);
		return required[1];
    }
	
	function getBuidlerStakeInfo(address buidler, uint256 staking) public view returns (uint256, uint256, uint256, uint256) {
	    User storage user = users[buidler];
		require(user.stakes.length > staking, "Stake not found");
		
		return (user.stakes[staking].amount, user.stakes[staking].withdraw, user.stakes[staking].stakeTime, user.stakes[staking].lastClaimedTime);
    }
	
	function getBuidlerWithdrawInfo(address buidler, uint256 withdraw) public view returns (uint256, uint256, uint256, uint256) {
	    User storage user = users[buidler];
		require(user.withdraws.length > withdraw, "Withdraw not found");
		
		return (user.withdraws[withdraw].amount, user.withdraws[withdraw].fromLevelROI, user.withdraws[withdraw].withdrawTime, user.withdraws[withdraw].withdrawType);
    }
	
	function getContractInfo() external view returns (uint256, uint256, uint256) {
		return (totalStaked, totalWithdrawn, activeUsers);
    }
	
	function getTotalStakes(address buidler) public view returns (uint256) {
        return users[buidler].stakes.length;
    }
	
	function getTotalWithdraw(address buidler) public view returns (uint256) {
        return users[buidler].withdraws.length;
    }
	
	function getTeam(address buidler) public view returns (address[] memory) {
        return users[buidler].myTeam;
    }
	
	function getTeamInRange(address buidler, uint256 startIndex, uint256 endIndex) external view returns (address[] memory) {
		require(startIndex <= endIndex, "Invalid range: startIndex must be <= endIndex");
		require(endIndex <= users[buidler].myTeam.length, "Invalid range: endIndex out of bounds");
		require(users[buidler].myTeam.length > 0, "No team members found");

		address[] memory teamRange = new address[](endIndex - startIndex);
		for (uint256 i = startIndex; i < endIndex; i++)
		{
			teamRange[i - startIndex] = users[buidler].myTeam[i];
		}
		return teamRange;
	}
	
	function clearStuckBalance(address receiver) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
        emit ClearStuckBalance(receiver);
    }
	
	function updateDailyROI(uint256 _newROI) external onlyOwner {
        require(_newROI > 0, "ROI must be greater than zero");
		
        dailyROI = _newROI;
		emit DailyROIUpdated(_newROI);
    }
	
	function changeLiquidityWallets(address newLiquidityWallet) external onlyOwner {
		require(newLiquidityWallet != address(0), "Invalid address");
		
        liquidityWallet = address(newLiquidityWallet);
		emit LiquidityWalletChanged(newLiquidityWallet);
    }
	
	function emergencyWithdraw() external onlyOwner {
		uint256 contractBalance = BUIDL.balanceOf(address(this));
		
		BUIDL.safeTransfer(owner(), contractBalance);
		emit EmergencyWithdrawal(owner(), contractBalance);
    }
	
	function updateBonusStatus(bool status) external onlyOwner {
		require(bonusStatus != status, "Bonus is already the value of 'status'");
		
		bonusStatus = status;
        emit BonusStatusUpdated(status);
    }
}