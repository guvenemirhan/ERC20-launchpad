// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ILock {
    function lockTokens(
        address _currency,
        address _owner,
        uint256 amount,
        uint256 endTime,
        bool isLPToken
    ) external returns (bool);
}
