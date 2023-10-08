// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SwapperCompound} from "../src/SwapperCompund.sol";

contract CounterTest is Test {
    SwapperCompound public swapper;

    function setUp() public {
        swapper = new SwapperCompound();
    }
}
