// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {StakingCompound} from "../src/StakingCompound.sol";

contract CounterTest is Test {
    StakingCompound public stake;

    function setUp() public {
        stake = new SwapperCompound();
    }
}
