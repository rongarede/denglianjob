// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./KKToken.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IStaking {
    function stake() payable external;
    function unstake(uint256 amount) external;
    function claim() external;
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
}

contract StakingPool is IStaking {
    KKToken public kkToken;
    uint256 public constant REWARD_PER_BLOCK = 10 * 1e18; // 10 KK tokens per block
    uint256 public lastRewardBlock;

    mapping(address => StakeInfo) private stakes;
    uint256 public totalStaked;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
    }


    constructor(KKToken _kkToken) {
        kkToken = _kkToken;
        lastRewardBlock = block.number;
    }

    function updatePool() internal {
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - lastRewardBlock;
        uint256 kkReward = blocks * REWARD_PER_BLOCK;
        kkToken.mint(address(this), kkReward);
        lastRewardBlock = block.number;
    }

    function _updateReward(address account) internal {
        require(account != address(0), "Invalid account");
        StakeInfo memory info = stakes[account];
        // 更新该用户待领取奖励
        info.rewardDebt += (info.amount * (block.number - lastRewardBlock) * REWARD_PER_BLOCK) / totalStaked;
        // 更新该用户的累积奖励
        stakes[account] = info;
    }

    function stake() payable external override {
        updatePool();

        StakeInfo storage stakeInfo = stakes[msg.sender];
        if (stakeInfo.amount > 0) {
            _updateReward(msg.sender);
        }

        stakes[msg.sender].amount += msg.value;
        totalStaked += msg.value;
    }

    function unstake(uint256 amount) external override {
        require(amount > 0, "Cannot unstake zero amount");

        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount >= amount, "Insufficient staked amount");

        updatePool();
        _updateReward(msg.sender);

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        payable(msg.sender).transfer(amount);
    }

    function claim() external override {
        updatePool();

        StakeInfo storage stakeInfo = stakes[msg.sender];
        _updateReward(msg.sender);
        uint256 reward = stakes[msg.sender].rewardDebt;

        stakeInfo.rewardDebt = 0;

        if (reward > 0) {
            kkToken.transfer(msg.sender, reward);
        }

    }

    function balanceOf(address account) external view override returns (uint256) {
        return stakes[account].amount;
    }

    function getStake(address user) external  returns (uint256 amount, uint256 rewards) {
        _updateReward(msg.sender);
        return (stakes[user].amount, stakes[user].rewardDebt);
    }


    function earned(address account) external view override returns (uint256) {
        StakeInfo storage stakeInfo = stakes[account];
        uint256 pending = (stakeInfo.amount * (block.number - lastRewardBlock) * REWARD_PER_BLOCK) / totalStaked;
        return stakeInfo.rewardDebt + pending;
    }
}
