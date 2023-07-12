// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Presale, Vesting} from "./IPresale.sol";

interface IPool {
    function initialize(address _owner) external returns (bool);

    function setVesting(Vesting memory vesting) external;

    function setPresale(Presale memory saleInfo) external returns (uint256);

    function getPoolData()
        external
        view
        returns (Presale memory, Vesting memory);
}
