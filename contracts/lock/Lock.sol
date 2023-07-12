// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {CurrencyLibrary} from "../libraries/CurrencyLibrary.sol";
import {LPLib} from "../libraries/LPLib.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Lock is Ownable2Step {
    using CurrencyLibrary for address;
    using LPLib for address;

    struct LockInfo {
        address currency;
        address owner;
        address factory;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    uint256 private _totalLocked;

    mapping(uint256 => LockInfo) public locks;

    event LockAdded(
        address currency,
        address owner,
        address factory,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 lockId
    );

    event LockUpdated(
        address currency,
        address owner,
        address factory,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 lockId
    );

    event Unlocked(
        address currency,
        address owner,
        address factory,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 lockId
    );

    /**
     * @notice This function locks a specified amount of tokens until a given end time.
     * @param _currency The address of the token contract to lock tokens from.
     * @param _owner The address of the user locking the tokens.
     * @param amount The amount of tokens to be locked.
     * @param endTime The unix timestamp after which the tokens can be unlocked.
     * @param isLPToken A boolean value indicating whether the locked token is a LP (Liquidity Pool) token.
     * @return A boolean value indicating whether the tokens were locked successfully.
     *
     * Requirements:
     * - `amount` must be less than or equal to the balance of the `msg.sender`.
     * - `endTime` must be greater than the current block timestamp.
     *
     * Emits an {LockAdded} event with relevant data.
     */
    function lockTokens(
        address _currency,
        address _owner,
        uint256 amount,
        uint256 endTime,
        bool isLPToken
    ) external returns (bool) {
        uint256 ownerBalance = _currency.balanceOf(msg.sender);
        require(
            amount <= ownerBalance,
            "Amount must be greater than owner balance."
        );
        require(
            endTime > block.timestamp,
            "End time must be greater than block timestamp."
        );
        LockInfo storage _temp = locks[_totalLocked];
        if (isLPToken) {
            address factory = _currency.isLPToken();
            _temp.factory = factory;
        } else {
            _temp.factory = address(0);
        }
        _temp.startTime = block.timestamp;
        _temp.endTime = endTime;
        _temp.amount = amount;
        _temp.currency = _currency;
        _temp.owner = msg.sender;
        _currency.safeTransferFrom(msg.sender, address(this), amount);
        emit LockAdded(
            _currency,
            _owner,
            _temp.factory,
            amount,
            block.timestamp,
            endTime,
            _totalLocked
        );
        _totalLocked++;
        return true;
    }

    /**
     * @notice This function modifies the lock conditions of a specific lock.
     * @param lockId The ID of the lock to be modified.
     * @param newAmount The new amount of tokens to be locked.
     * @param newEndTime The new unix timestamp after which the tokens can be unlocked.
     * @return A boolean value indicating whether the lock conditions were successfully modified.
     *
     * Requirements:
     * - `lockId` must be less than or equal to the total number of locks.
     * - The caller must be the owner of the lock.
     * - `newAmount` must be greater than or equal to the current locked amount and greater than 0.
     * - `newEndTime` must be greater than the current end time and the current block timestamp.
     *
     * Emits a {LockUpdated} event with relevant data.
     */
    function editTokensLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newEndTime
    ) external returns (bool) {
        require(lockId <= _totalLocked);
        LockInfo storage _temp = locks[lockId];
        require(_temp.owner == msg.sender, "You are not owner of pool");
        require(newAmount >= _temp.amount && newAmount > 0, "");
        require(
            newEndTime >= _temp.endTime && newEndTime > block.timestamp,
            "New lock expiry time must be gt current lock expiry time"
        );
        uint256 diff;
        unchecked {
            diff = newAmount - _temp.amount;
        }
        require(diff > 0);
        _temp.currency.safeTransferFrom(msg.sender, address(this), diff);
        emit LockUpdated(
            _temp.currency,
            _temp.owner,
            _temp.factory,
            newAmount,
            _temp.startTime,
            newEndTime,
            lockId
        );
        return true;
    }

    /**
     * @notice This function unlocks tokens that were previously locked.
     * @param lockId The ID of the lock to be unlocked.
     * @return A boolean value indicating whether the tokens were successfully unlocked.
     *
     * Requirements:
     * - `lockId` must be less than or equal to the total number of locks.
     * - The caller must be the owner of the lock.
     * - The locked amount must be greater than 0.
     * - The end time of the lock must be less than or equal to the current block timestamp.
     *
     * Emits a {LockUpdated} event with relevant data, and deletes the lock from the `locks` mapping.
     */
    function unlockTokens(uint256 lockId) external returns (bool) {
        require(lockId <= _totalLocked);
        LockInfo memory _temp = locks[lockId];
        require(_temp.owner == msg.sender, "You are not owner of pool");
        require(_temp.amount > 0, "You have no locked tokens");
        require(
            _temp.endTime <= block.timestamp,
            "Lock time has not expired yet"
        );
        _temp.currency.safeTransfer(msg.sender, _temp.amount);
        emit LockUpdated(
            _temp.currency,
            _temp.owner,
            _temp.factory,
            _temp.amount,
            _temp.startTime,
            _temp.endTime,
            lockId
        );
        delete locks[lockId];
        return true;
    }
}
