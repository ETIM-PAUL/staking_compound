// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

abstract contract Helpers is Test {
    // uint256 user
    function createAddress(
        string memory name
    ) public returns (address caller, uint256 privateKey) {
        privateKey = uint256(keccak256(abi.encodePacked(name)));
        caller = vm.addr(privateKey);
        vm.label(caller, name);
    }

    function swapCaller(address _caller) public {
        vm.startPrank(_caller);
        vm.deal(_caller, 3 ether);
        vm.label(_caller, "CALLER");
    }
}
