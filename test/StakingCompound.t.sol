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
        stake.stakedEth(staker.isCompound);
    }

    function testAdminCannotStake() external payable {
        vm.expectRevert(StakingCompound.AdminCantStake.selector);
        stake.stakedEth{value: 1 ether}(staker.isCompound);
    }

    function testStakedEthNoCompound() external payable {
        swapCaller(callerA);
        bool success = stake.stakedEth{value: 1 ether}(staker.isCompound);
        assertTrue(success);
    }
}
