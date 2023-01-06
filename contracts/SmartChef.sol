// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "./ISmartChef.sol";

contract SmartChef is ISmartChef, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public _delegator;
    bool public hasUserLimit;
    bool public isInitialized;
    uint256 public accTokenPerShare;
    uint256 public endBlock;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public poolLimitPerUser;
    uint256 public rewardPerBlock;
    uint256 public totalDeposit;

    IERC20 public rewardToken;
    IERC20 public stakedToken;

    mapping(address => UserInfo) public userInfo;
    mapping(address => DepositHistory[]) userDepositHistory;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    event TokenRecovery(address token, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event UpdateStartEndBlock(uint256 startBlock, uint256 endBlock);
    event UpdateRewardPerBlock(uint256 rewardPerBlock);
    event UpdatePoolLimit(uint256 poolLimitPerUser);
    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        _delegator = msg.sender;
    }

    function initialize(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _poolLimitPerUser,
        address _admin
    ) external {
        require(!isInitialized, "INITIALIZED");
        require(msg.sender == _delegator, "UNAUTHORIZED");

        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        lastRewardBlock = startBlock;
        transferOwnership(_admin);
    }

    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "USER_LIMIT");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            totalDeposit = totalDeposit.add(_amount);
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            userDepositHistory[msg.sender].push(DepositHistory(user.amount, block.timestamp));
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "INSUFFICIENT_BALANCE");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalDeposit = totalDeposit.sub(_amount);
            stakedToken.safeTransfer(address(msg.sender), _amount);
            traceBackDepositHistory(user);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    function getDepositHistory(address account) external view returns (DepositHistory[] memory){
        return userDepositHistory[account];
    }

    function traceBackDepositHistory(UserInfo memory user) internal {
        if (user.amount == 0){
            delete userDepositHistory[msg.sender];
        }else {
            DepositHistory[] storage depositHistories = userDepositHistory[msg.sender];
            uint lastedTimestamp = block.timestamp;
            while(depositHistories.length > 0){
                if (depositHistories[depositHistories.length - 1].amount > user.amount){
                    lastedTimestamp = depositHistories[depositHistories.length - 1].timestamp;
                    depositHistories.pop();
                }else{
                    break;
                }
            }
            depositHistories.push(DepositHistory(user.amount, lastedTimestamp));
        }
    }

    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken) && _tokenAddress != address(rewardToken), "TOKEN_LOCKED");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit TokenRecovery(_tokenAddress, _tokenAmount);
    }

    function stopReward() external onlyOwner {
        endBlock = block.number;
    }

    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "ALREADY_UNLIMITED");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "NEW_LIMIT_LOWER");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit UpdatePoolLimit(poolLimitPerUser);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "POOL_STARTED");
        rewardPerBlock = _rewardPerBlock;
        emit UpdateRewardPerBlock(_rewardPerBlock);
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner {
        require(block.number < startBlock, "POOL_STARTED");
        require(_startBlock < _endBlock, "INVALID_START_END_BLOCK");
        require(block.number < _startBlock, "BLOCK_PASSED");

        startBlock = _startBlock;
        endBlock = _endBlock;

        lastRewardBlock = startBlock;

        emit UpdateStartEndBlock(_startBlock, _endBlock);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
                accTokenPerShare.add(tokenReward.mul(1e12).div(stakedTokenSupply));
            return user.amount.mul(adjustedTokenPerShare).div(1e12).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
        }
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }
}