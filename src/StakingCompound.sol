// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./interface/IWETH.sol";
import {StakingUtils} from "./library/Utils.sol";

contract StakingCompound is ERC20 {
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
        bool isCompound;
        uint timeAutoCompoundStarted;
    }

    mapping(address => Staker) stakers;

    uint totalAutoCompoundFee;

    address weth;

    error ZeroEth();

    // error

    constructor(address _weth) ERC20("ETIM-PAUL Tokens", "ETT") {
        weth = _weth;
    }

    function stakedEth(bool _isCompound) external payable {
        if (msg.value == 0) {
            revert ZeroEth();
        }
        uint stakedAmout = IWETH(weth).deposit{value: eth}();

        Staker _staker = stakers[msg.sender];

        if (_staker.stakedAmount == 0) {
            _staker.stakedTime = block.timestamp;
            _staker.stakedAmount = stakedAmout;
        } else {
            _staker.stakedAmount += stakedAmout;
            //calcaulate accured reward
            uint difference = block.timestamp - staker.stakedTime;
            uint accumulatedReward = calculateAccuredReward(
                difference,
                _staker.stakedAmount
            );
            _staker.totalReward += accumulatedReward;
        }
        _staker.isCompound = _isCompound;

        //mint receipt tokens
        _mint(msg.sender, stakedAmout);
    }

    function claimReward() external {
        Staker storage staker = staker[msg.sender];
        uint difference = block.timestamp - staker.stakedTime;
        uint amount = staker.stakedAmount;

        //re-calculate Accured Rewards since the last staked time
        if (staker.isCompound) {} else {
            uint accumulatedReward = StakingUtils.calculateNoCompoundReward(
                difference,
                staker.stakedAmount
            );
            staker.totalReward = 0;
            staker.stakedAmount = 0;
            staker.stakedTime = 0;

            //staker is rewarded with ETT (APR 14% at a ration of 1:10)
            _mint(msg.sender, accumulateReward);

            //give back their deposited eth
            uint ethDeposited = IWETH(weth).withdraw(staker.stakedAmount);
            payable(msg.sender).transfer(ethDeposited);
        }
        emit RewardClaimed(msg.sender, totalReward);
    }

    function triggerCompound() external {}

    function stakedCompoundMonthly() internal {}
}
