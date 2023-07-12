// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SignatureChecker} from "../utils/SignatureChecker.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Presale, Vesting, IPool} from "../interfaces/IPool.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {CurrencyLibrary} from "../libraries/CurrencyLibrary.sol";

contract PoolManager is SignatureChecker, ReentrancyGuard {
    using CurrencyLibrary for address;

    address private _poolAddress;
    uint256 private _totalCreated;
    mapping(uint256 => address) private _presales;
    mapping(address => address) private _usersPresales;
    event PresaleCreated(
        address presaleAddress,
        address currency,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );

    constructor(
        address _signer,
        address poolAddress
    ) SignatureChecker(_signer) {
        _poolAddress = poolAddress;
    }

    /**
     * @notice Creates a new presale contract with the given presale details.
     * @param newPresale The presale details to be set for the new presale contract.
     * @param vesting The vesting details to be set for the new presale contract.
     * @param signature The signature for the presale details, used for signature verification.
     * @return The address of the newly created presale contract.
     */
    function createPresale(
        Presale memory newPresale,
        Vesting memory vesting,
        bytes memory signature
    ) external nonReentrant returns (address) {
        require(newPresale.startTime >= block.timestamp);
        require(recover(newPresale, signature), "Incorrect signature");
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, newPresale.currency)
        );
        address presaleAddress = Clones.cloneDeterministic(_poolAddress, salt);
        _presales[_totalCreated] = presaleAddress;
        IPool presaleContract = IPool(presaleAddress);
        bool success = presaleContract.initialize(msg.sender);
        require(success, "Error");
        _totalCreated++;
        uint256 totalAmount = presaleContract.setPresale(newPresale);
        require(totalAmount > 0, "Amount must be greater than 0");
        if (newPresale.isVesting) {
            presaleContract.setVesting(vesting);
        }
        newPresale.currency.safeTransferFrom(
            msg.sender,
            presaleAddress,
            totalAmount
        );
        emit PresaleCreated(
            presaleAddress,
            newPresale.currency,
            totalAmount,
            newPresale.startTime,
            newPresale.endTime
        );
        return presaleAddress;
    }

    /**
     * @notice Withdraws all the remaining ETH balance from the contract to the owner's address.
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "");
        CurrencyLibrary.safeTransferETH(owner(), balance);
    }

    /**
     * @notice Returns the address of the presale contract at the specified index in the `_presales` array.
     * @param index The index of the presale contract.
     * @return poolAddress The address of the presale contract.
     */
    function presales(
        uint256 index
    ) external view onlyOwner returns (address poolAddress) {
        poolAddress = _presales[index];
    }

    /**
     * @notice Returns an array of all presale contract addresses created by the owner.
     * @return poolAddress An array of presale contract addresses.
     */
    function getAllPresales()
        external
        view
        onlyOwner
        returns (address[] memory poolAddress)
    {
        for (uint256 i = 0; i < _totalCreated; ) {
            poolAddress[i] = (_presales[i]);
            unchecked {
                i++;
            }
        }
        return poolAddress;
    }

    /**
     * @notice Returns the presale and vesting data of a specific presale contract.
     * @param poolAddress The address of the presale contract.
     * @return presaleDatas The presale data of the specified presale contract.
     * @return vestingDatas The vesting data of the specified presale contract.
     */
    function getPresalesData(
        IPool poolAddress
    )
        external
        view
        onlyOwner
        returns (Presale memory presaleDatas, Vesting memory vestingDatas)
    {
        return poolAddress.getPoolData();
    }

    /**
     * @notice Returns the predicted address of a presale pool based on the pool owner and currency.
     * @param poolOwner The address of the presale pool owner.
     * @param currency The address of the presale currency.
     * @return poolAddress The predicted address of the presale pool.
     */
    function getPoolAddress(
        address poolOwner,
        address currency
    ) external view returns (address poolAddress) {
        bytes32 salt = keccak256(abi.encodePacked(poolOwner, currency));
        poolAddress = Clones.predictDeterministicAddress(_poolAddress, salt);
    }
}
