// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MockERC20 is ERC20, Ownable2Step {
    constructor() ERC20("MockERC20", "MERC20") {
        _mint(msg.sender, 10_000_000 ether);
    }
}
