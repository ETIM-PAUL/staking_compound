// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StakingCompound} from "../src/StakingCompound.sol";
import {WETH} from "../src/WETH.sol";
import "./Helper.sol";

contract CounterTest is Helpers {
    StakingCompound public stake;
    WETH public weth;

    address callerA;
    address callerB;

    uint256 privKeyA;
    uint256 privKeyB;

    address admin;

    StakingCompound.Staker staker;

    function setUp() public {
        weth = new WETH();
        stake = new StakingCompound(address(weth));

        admin = msg.sender;

        (callerA, privKeyA) = createAddress("CALLERA");
        (callerB, privKeyB) = createAddress("CALLERB");

        staker = StakingCompound.Staker({
            stakedAmount: 0,
            stakedTime: 0,
            totalReward: 0,
            isCompound: false,
            timeAutoCompoundStarted: 0
        });
    }

    function testZeroValueInvalid() external payable {
        vm.expectRevert(StakingCompound.ZeroEth.selector);
        stake.stakedEth{value: 1 ether}();
    }

    function testAdminCannotStake() external payable {
        vm.expectRevert(StakingCompound.AdminCantCall.selector);
        stake.stakedEth{value: 1 ether}();
    }

    function testStakedEth() external payable {
        swapCaller(callerA);
        bool success = stake.stakedEth{value: 1 ether}();
        assertEq(stake.balanceOf(msg.sender), 1000000000000000000);
        assertTrue(success);
    }

    function testClaimTokenNoCompound() external {
        swapCaller(callerA);
        bool success = stake.stakedEth{value: 1 ether}();
        vm.warp(31536001);
        stake.approve(address(stake), 1000000000000000000);
        stake.claimRewardNoCompound();
        assertGe(stake.balanceOf(msg.sender), 1140000000000000000);
        assertGt(address.balance, 2);
    }

    function testSwapToCompound() external {
        swapCaller(callerA);
        stake.stakedEth{value: 1 ether}();
        bool success = stake.swapToCompound();
        assertTrue(success);
    }
}
