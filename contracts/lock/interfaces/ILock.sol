// SPDX-License-Identifier: AGPL-3.0-only
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
