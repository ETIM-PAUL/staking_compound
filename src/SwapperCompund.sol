// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SwapperCompound {
    event ETHStaked(address staker, uint amount, bool isCompund);
    event RewardsClaimed(address staker, uint amount);
    event CompoundActionTriggered(address trigger, uint amount);

    struct LiquidityPool {
        uint totalAmount;
        uint totalDepositors;
    }

    struct Staker {
        uint stakedAmount;
        uint stakedTime;
        uint totalReward;
    }
}
