// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library StakingUtils {
    function calculateNoCompoundReward(
        uint difference,
        uint stakedAmount
    ) external pure returns (uint accuredReward) {
        uint secondsInYear = 31_536_000;
        uint fourteenPercent = (difference * stakedAmount * 14) /
            (secondsInYear * 100);

        accuredReward = fourteenPercent * 10;
    }

    function checkIfUpToOneMonth(
        uint diffrence
    ) external pure returns (bool isUpto) {
        uint secondsInMonth = 2678400;
        if (diffrence >= secondsInMonth) {
            isUpto = true;
        } else {
            isUpto = false;
        }
    }
}
