// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./interface/IWETH.sol";
import {StakingUtils} from "./library/Utils.sol";

contract StakingCompound is ERC20 {
    event ETHStaked(address staker, uint amount);
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
    uint totalStakers;

    address weth;
    address admin;

    error ZeroEth();
    error AdminCantCall();
    error NoCompoundActivated();
    error AlreadyCompound();

    // error

    constructor(address _weth) ERC20("ETIM-PAUL Tokens", "ETT") {
        weth = address(_weth);
        admin = msg.sender;
    }

    function stakedEth() external payable returns (bool success) {
        if (msg.value == 0) {
            revert ZeroEth();
        }
        if (msg.sender == admin) {
            revert AdminCantCall();
        }
        success = staked(msg.value);
    }

    function claimRewardNoCompound() external {
        Staker storage staker = stakers[msg.sender];
        uint difference = block.timestamp - staker.stakedTime;
        uint ethDeposited = staker.stakedAmount;

        //re-calculate Accured Rewards since the last staked time
        uint accumulated_Reward = StakingUtils.calculateNoCompoundReward(
            difference,
            staker.stakedAmount
        );
        staker.totalReward = 0;
        staker.stakedAmount = 0;
        staker.stakedTime = 0;

        //staker is rewarded with ETT (APR 14% at a ration of 1:10)
        _mint(msg.sender, accumulated_Reward);
        transferFrom(msg.sender, address(this), staker.stakedAmount);
        _burn(address(this), staker.stakedAmount);

        emit RewardClaimed(msg.sender, accumulated_Reward);

        //give back their deposited eth
        IWETH(weth).withdraw(ethDeposited);
        payable(msg.sender).transfer(ethDeposited);
    }

    function claimRewardCompound() external {
        Staker storage staker = stakers[msg.sender];

        //check if the caller has compound activated
        if (!staker.isCompound) {
            revert NoCompoundActivated();
        }

        uint difference = block.timestamp - staker.timeAutoCompoundStarted;
        uint ethDeposited = staker.stakedAmount;

        //re-calculate Accured Rewards since the time auto compound was activated time
        uint _accumulatedReward = ((staker.stakedAmount * 14 * difference) /
            100);
        staker.totalReward = 0;
        staker.stakedAmount = 0;
        staker.stakedTime = 0;
        staker.isCompound = false;

        //staker is rewarded with PRT/100 formula
        _mint(msg.sender, _accumulatedReward);
        transferFrom(msg.sender, address(this), staker.stakedAmount);
        _burn(address(this), staker.stakedAmount);

        //give back their deposited eth
        IWETH(weth).withdraw(ethDeposited);
        payable(msg.sender).transfer(ethDeposited);

        emit RewardClaimed(msg.sender, _accumulatedReward);
    }

    function swapToCompound() external returns (bool success) {
        Staker storage staker = stakers[msg.sender];
        if (staker.isCompound) {
            revert AlreadyCompound();
        }
        success = true;
        staker.isCompound = true;
        staker.timeAutoCompoundStarted = block.timestamp;
    }

    function triggerCompound(address[] memory triggeredAddresses) external {
        if (msg.sender == admin) {
            revert AdminCantCall();
        }

        for (uint256 index = 0; index < triggeredAddresses.length; index++) {
            Staker storage staker = stakers[index];
            uint difference = block.timestamp - staker.stakedTime;
            bool isValid = StakingUtils.checkIfUpToOneMonth(difference);
            if (staker.isCompound && isValid) {
                implementAutoCompound(index);
            }
        }
        (bool success, ) = (msg.sender).call{
            value: (totalAutoCompoundFee / 50)
        }("");
        require(success, "Failed to send Ether");
        emit CompoundActionTriggered(msg.sender, totalAutoCompoundFee);
    }

    function implementAutoCompound(address _staker) internal {
        Staker storage staker = stakers[msg.sender];
        uint difference = block.timestamp - staker.stakedTime;
        uint accumulatedReward = StakingUtils.calculateNoCompoundReward(
            difference,
            staker.stakedAmount
        );
        uint amountConvertedToWeth = (accumulatedReward * 10);

        //update Total auto compound fee
        totalAutoCompoundFee += (staker.stakedAmount / 100);

        //subtract one percent from their initial deposited weth
        staker.stakedAmount = staker.stakedAmount - (staker.stakedAmount / 100);

        //restake accumulated reward tokens
        stakedCompound(amountConvertedToWeth, _staker);
    }

    function staked(uint amount) internal returns (bool success) {
        IWETH(weth).deposit{value: amount}();

        Staker storage _staker = stakers[msg.sender];
        _staker.stakedTime = block.timestamp;
        _staker.stakedAmount += amount;

        //mint receipt tokens
        _mint(msg.sender, amount);
        totalStakers++;
        success = true;

        emit ETHStaked(msg.sender, amount);
    }

    function stakedCompound(
        uint amount,
        address staker
    ) internal returns (bool success) {
        IWETH(weth).deposit{value: amount}();

        Staker storage _staker = stakers[staker];
        _staker.stakedTime = block.timestamp;
        _staker.stakedAmount += amount;

        //mint receipt tokens
        _mint(msg.sender, amount);
        totalStakers++;
        success = true;

        emit ETHStaked(msg.sender, amount);
    }

    receive() external payable {}
}
