// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./interface/IWETH.sol";
import {StakingUtils} from "./library/Utils.sol";

contract StakingCompound is ERC20 {
    event ETHStaked(address staker, uint amount, bool isCompound);
    event RewardClaimed(address staker, uint amount);
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
    address admin;

    error ZeroEth();
    error AdminCantStake();

    // error

    constructor(address _weth) ERC20("ETIM-PAUL Tokens", "ETT") {
        weth = address(_weth);
        admin = msg.sender;
    }

    function stakedEth(
        bool _isCompound
    ) external payable returns (bool success) {
        if (msg.value == 0) {
            revert ZeroEth();
        }
        if (msg.sender == admin) {
            revert AdminCantStake();
        }
        IWETH(weth).deposit{value: msg.value}();

        Staker storage _staker = stakers[msg.sender];

        if (_staker.stakedAmount == 0) {
            _staker.stakedTime = block.timestamp;
            _staker.stakedAmount = msg.value;
        } else {
            _staker.stakedAmount += msg.value;
            //calcaulate accured reward
            uint difference = block.timestamp - _staker.stakedTime;
            uint accumulatedReward = StakingUtils.calculateNoCompoundReward(
                difference,
                _staker.stakedAmount
            );
            _staker.totalReward += accumulatedReward;
        }
        _staker.isCompound = _isCompound;

        //mint receipt tokens
        _mint(msg.sender, msg.value);

        success = true;

        emit ETHStaked(msg.sender, msg.value, _isCompound);
    }

    function claimReward() external {
        Staker storage staker = stakers[msg.sender];
        uint difference = block.timestamp - staker.stakedTime;
        uint ethDeposited = staker.stakedAmount;

        uint accumulatedReward;

        //re-calculate Accured Rewards since the last staked time
        if (staker.isCompound) {} else {
            accumulatedReward = StakingUtils.calculateNoCompoundReward(
                difference,
                staker.stakedAmount
            );
            staker.totalReward = 0;
            staker.stakedAmount = 0;
            staker.stakedTime = 0;

            //staker is rewarded with ETT (APR 14% at a ration of 1:10)
            _mint(msg.sender, accumulatedReward);

            //give back their deposited eth
            IWETH(weth).withdraw(ethDeposited);
            payable(msg.sender).transfer(ethDeposited);
        }
        emit RewardClaimed(msg.sender, accumulatedReward);
    }

    function triggerCompound() external {}

    function stakedCompoundMonthly() internal {}

    receive() external payable {}
}
