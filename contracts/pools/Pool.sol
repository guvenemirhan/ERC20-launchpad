// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;
import {CurrencyLibrary} from "../libraries/CurrencyLibrary.sol";
import {Presale, Vesting, Contributor} from "../interfaces/IPresale.sol";
import {IRouterV2} from "../interfaces/IRouterV2.sol";
import {ILock} from "../lock/interfaces/ILock.sol";
import {VestingLib} from "../libraries/VestingLib.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Pool is ReentrancyGuard {
    using CurrencyLibrary for address;

    struct Stats {
        uint256 totalContributed;
        uint256 totalTokenAmount;
        uint256 totalClaimed;
        bool isFinalized;
        bool isCancelled;
    }

    bool private _isInit;
    bool private _isWhitelist;

    address private _owner;
    address private _factory;
    address private _token;

    ILock private immutable _lock;
    Presale private _presale;
    Stats private _presaleStats;
    Vesting private _vesting;

    mapping(address => Contributor) private _contributors;
    mapping(address => bool) private _whitelist;

    event Contribute(address contributor, uint256 amount, uint256 timestamp);
    event Claimed(address contributor, uint256 amount, uint256 timestamp);
    event EmergencyWithdrawal(
        address contributor,
        uint256 amount,
        uint256 timestamp
    );
    event Finalized(uint256 timestamp);
    event Cancelled(uint256 timestam);
    event AddedWhitelist(uint256 addresses, uint256 timestamp);
    event Withdrawn(address user, uint256 amount, uint256 timestamp);

    error ClaimError(address user);

    modifier isInitialized() {
        require(!_isInit, "Already initialized");
        _;
        _isInit = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not owner");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == _factory, "You are not factory");
        _;
    }

    constructor(address lock) {
        _lock = ILock(lock);
    }

    receive() external payable {
        contribute();
    }

    fallback() external payable {
        contribute();
    }

    /**
     * @notice This function initializes the contract.
     * @param owner The address of the owner of the contract.
     * @return A boolean value indicating whether the initialization was successful.
     *
     * Sets the contract `_factory` to the caller of the function and the contract `_owner` to the provided owner address.
     */
    function initialize(address owner) external isInitialized returns (bool) {
        _factory = msg.sender;
        _owner = owner;
        return true;
    }

    /**
     * @notice This function sets the vesting schedule for the proxy contract.
     * @param vesting A `Vesting` struct containing the vesting schedule details.
     * @dev The function can only be called by the factory.
     */
    function setVesting(Vesting memory vesting) external onlyFactory {
        require(vesting.tge > 0 && vesting.tge < 100, "");
        require(vesting.tge + vesting.release <= 100, "");
        require(vesting.release > 0 && vesting.cliff > 0, "");
        vesting.startTime = 0;
        _vesting = vesting;
    }

    /**
     * @notice This function sets the presale details for the proxy contract.
     * @param saleInfo A `Presale` struct containing the presale details.
     * @dev The function can only be called by the factory.
     */
    function setPresale(
        Presale memory saleInfo
    ) external onlyFactory returns (uint256) {
        _token = saleInfo.currency;
        _presale = saleInfo;
        uint256 totalTokenAmount = saleInfo.hardcap * saleInfo.presaleRate;
        if (saleInfo.autoListing) {
            totalTokenAmount += saleInfo.hardcap * saleInfo.listingRate;
        }
        _presaleStats.totalTokenAmount = totalTokenAmount;
        return totalTokenAmount;
    }

    /**
     * @notice Allows for withdrawal of contributed funds if the presale is cancelled.
     * @dev This function can only be executed if the presale has been cancelled. The function is protected against reentrancy attacks.
     */
    function withdraw() external nonReentrant {
        require(_presaleStats.isCancelled, "Presale continues");
        uint256 amount = _contributors[msg.sender].totalContributed;
        delete _contributors[msg.sender];
        CurrencyLibrary.safeTransferETH(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Cancels the presale and transfers the total token amount back to the owner.
     * @dev This function can only be executed by the owner.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function cancel() external onlyOwner returns (bool) {
        Stats storage presaleStats = _presaleStats;
        require(
            !presaleStats.isFinalized && !presaleStats.isCancelled,
            "Presale is finalized"
        );
        presaleStats.isCancelled = true;
        address currency = _token;
        currency.safeTransfer(_owner, presaleStats.totalTokenAmount);
        emit Cancelled(block.timestamp);
        return true;
    }

    /**
     * @notice Finalizes the presale based on the defined conditions and distributes the funds accordingly.
     * @dev This function can only be executed by the owner.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function finalize() external onlyOwner returns (bool) {
        Stats storage presaleStats = _presaleStats;
        require(!presaleStats.isCancelled, "Presale is cancelled.");
        Presale memory presale = _presale;
        uint256 totalContributed = _presaleStats.totalContributed;
        require(
            (presale.softcap < totalContributed &&
                block.timestamp > presale.endTime) ||
                presale.hardcap == totalContributed,
            "Presale is not over yet"
        );
        presaleStats.isFinalized = true;
        if (presale.isVesting) {
            _vesting.startTime = block.timestamp + _vesting.cliff;
        }
        uint256 liquidityAmount = totalContributed * presale.listingRate;
        if (presale.autoListing) {
            if (presale.isLock) {
                _addLiquidityETH(
                    presale.currency,
                    address(this),
                    liquidityAmount,
                    totalContributed
                );
                _lockLPTokens(presale.currency, presale.lockEndTime);
            } else {
                _addLiquidityETH(
                    presale.currency,
                    msg.sender,
                    liquidityAmount,
                    totalContributed
                );
            }
        } else {
            CurrencyLibrary.safeTransferETH(msg.sender, totalContributed);
        }
        uint256 refundAmount = presale.hardcap *
            presale.listingRate -
            liquidityAmount;
        _refund(refundAmount, presale.currency, presale.refund);
        emit Finalized(block.timestamp);
        return true;
    }

    /**
     * @notice Sets the whitelist of addresses allowed to participate in the presale.
     * @dev This function can only be executed by the owner.
     * @param whitelistAddresses An array of addresses to be added to the whitelist.
     */
    function setWhitelist(
        address[] calldata whitelistAddresses
    ) external onlyOwner {
        require(
            whitelistAddresses.length <= 200,
            "Maximum 200 addresses can be added"
        );
        if (!_isWhitelist) {
            _isWhitelist = true;
        }
        for (uint256 i = 0; i < whitelistAddresses.length; ) {
            require(
                whitelistAddresses[i] != address(0),
                "Address must not be equal to zero address"
            );
            _whitelist[whitelistAddresses[i]] = true;
            unchecked {
                i++;
            }
        }
        emit AddedWhitelist(whitelistAddresses.length, block.timestamp);
    }

    /**
     * @notice Changes the factory address used for the presale.
     * @dev This function can only be executed by the current factory address.
     * @param factory The new factory address to be set.
     */
    function changeFactoryAddress(address factory) external onlyFactory {
        require(
            factory != address(0),
            "Factory address does not equal zero address"
        );
        _factory = factory;
    }

    /**
     * @notice Claims the vested tokens or available tokens for the caller.
     * @dev If the presale has vesting enabled, it calls the `_vestingClaim` function to claim the vested tokens.
     *      Otherwise, it calls the `_claim` function to claim the available tokens.
     *      If the claim is unsuccessful, it reverts with a `ClaimError` indicating the caller's address.
     */
    function claim() external {
        bool isClaimed = _presale.isVesting ? _vestingClaim() : _claim();
        if (!isClaimed) {
            revert ClaimError(msg.sender);
        }
    }

    /**
     * @notice Performs an emergency withdrawal for the caller.
     * @dev Allows a contributor to perform an emergency withdrawal of their contributed funds.
     *      It can only be called before the presale is finalized.
     *      The contributor's total contribution is deducted from the presale's total contributed amount.
     *      20% of the total contribution is transferred to the caller as the withdrawal amount.
     *      The remaining 80% is transferred to the caller as a fee.
     *      The contributor's total contribution and claimable amount are set to 0.
     */
    function emergencyWithdrawal() external {
        Stats storage presaleStats = _presaleStats;
        require(!presaleStats.isFinalized, "Presale is finalized");
        Contributor memory contributor = _contributors[msg.sender];
        require(contributor.totalContributed > 0, "You are not contributor");
        presaleStats.totalContributed -= contributor.totalContributed;
        uint256 amount = (contributor.totalContributed * 20) / 100;
        uint256 fee;
        unchecked {
            fee = contributor.totalContributed - amount;
        }
        contributor.totalContributed = 0;
        contributor.claimable = 0;
        CurrencyLibrary.safeTransferETH(msg.sender, amount);
        CurrencyLibrary.safeTransferETH(msg.sender, fee);
        emit EmergencyWithdrawal(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice Contributes funds to the presale.
     * @dev Allows a user to contribute funds to the presale by sending Ether to the contract.
     *      The function performs various checks before accepting the contribution:
     *        - If the presale has a whitelist, the caller must be whitelisted.
     *        - The presale must not be cancelled or finalized.
     *        - The current block timestamp must be within the presale's start and end time.
     *        - The total contributed amount plus the sent value must not exceed the presale's hardcap.
     *        - The caller's total contribution plus the sent value must not exceed the presale's max buy limit.
     *        - The sent value must be greater than or equal to the presale's min buy limit.
     *      If all checks pass, the contribution is recorded:
     *        - The sent value is added to the presale's total contributed amount.
     *        - The sent value is added to the caller's total contribution amount.
     *        - The caller's claimable amount is increased based on the presale rate.
     * @return A boolean value indicating the success of the contribution.
     */
    function contribute() public payable returns (bool) {
        if (_isWhitelist) {
            require(_whitelist[msg.sender], "You are not whitelisted.");
        }
        Presale memory presale = _presale;
        Stats storage presaleStats = _presaleStats;
        require(
            !presaleStats.isCancelled &&
                !presaleStats.isFinalized &&
                block.timestamp >= presale.startTime &&
                block.timestamp <= presale.endTime,
            "The presale is not active at this time."
        );
        require(presaleStats.totalContributed + msg.value <= presale.hardcap);
        Contributor storage contributor = _contributors[msg.sender];
        require(
            contributor.totalContributed + msg.value <= presale.maxBuy &&
                msg.value >= presale.minBuy
        );
        presaleStats.totalContributed += msg.value;
        _contributors[msg.sender].totalContributed += msg.value;
        _contributors[msg.sender].claimable += msg.value * presale.presaleRate;
        emit Contribute(msg.sender, msg.value, block.timestamp);
        return true;
    }

    /**
     * @notice Retrieves the pool data including the presale and vesting information.
     * @dev Only the factory address can call this function.
     * @return A tuple containing the presale and vesting information.
     */
    function getPoolData()
        public
        view
        returns (Presale memory, Vesting memory)
    {
        require(msg.sender == _factory);
        return (_presale, _vesting);
    }

    /**
     * @notice Refunds the specified amount of tokens to the designated address.
     * @param amount The amount of tokens to be refunded.
     * @param currency The address of the token contract.
     * @param isRefund Whether the tokens should be refunded to the caller or burned.
     */
    function _refund(uint256 amount, address currency, bool isRefund) private {
        address to = isRefund ? msg.sender : address(0xdEaD);
        currency.safeTransfer(to, amount);
    }

    /**
     * @notice Locks the LP tokens in the contract by transferring them to a lock contract.
     * @param token The address of the LP token contract.
     * @param lockTime The duration for which the tokens will be locked.
     */
    function _lockLPTokens(address token, uint256 lockTime) private {
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address lpToken = _pairFor(token, weth);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ILock lockAddress = _lock;
        lpToken.safeApprove(address(lockAddress), lpTokenBalance);
        _lock.lockTokens(lpToken, msg.sender, lpTokenBalance, lockTime, true);
    }

    /**
     * @notice Adds liquidity to an ETH-based trading pair.
     * @param token The address of the token to be added as liquidity.
     * @param to The address to receive the liquidity tokens.
     * @param amountTokenDesired The desired amount of the token to add as liquidity.
     * @param amountETH The amount of ETH to be added as liquidity.
     */
    function _addLiquidityETH(
        address token,
        address to,
        uint amountTokenDesired,
        uint amountETH
    ) private {
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        token.safeApprove(router, amountTokenDesired);
        IRouterV2(router).addLiquidityETH{value: amountETH}(
            token,
            amountTokenDesired,
            0,
            0,
            to,
            block.timestamp
        );
    }

    /**
     * @notice Claims vested tokens for the caller.
     * @return True if the claim is successful, otherwise reverts.
     */
    function _vestingClaim() private returns (bool) {
        Stats memory presaleStats = _presaleStats;
        require(presaleStats.isFinalized, "Presale not finalized yet");
        Contributor storage contributor = _contributors[msg.sender];
        require(
            contributor.claimable > 0 &&
                contributor.claimable > contributor.claimed,
            "Amount must be greater than 0"
        );
        Vesting memory vesting = _vesting;
        uint256 claimable = VestingLib.calculateClaimableAmount(
            vesting,
            contributor
        );
        require(claimable > 0, "No claimable amount available");
        _token.safeTransfer(msg.sender, claimable);
        emit Claimed(msg.sender, claimable, block.timestamp);
        return true;
    }

    /**
     * @notice Claims available tokens for the caller.
     * @return True if the claim is successful, otherwise reverts.
     */
    function _claim() private returns (bool) {
        Stats memory presaleStats = _presaleStats;
        require(presaleStats.isFinalized, "Presale not finalized yet");
        Contributor storage contributor = _contributors[msg.sender];
        require(contributor.claimable > 0, "Amount must be greater than 0");
        uint256 claimable = contributor.claimable;
        contributor.claimable = 0;
        _token.safeTransfer(msg.sender, claimable);
        emit Claimed(msg.sender, claimable, block.timestamp);
        return true;
    }

    /**
     * @notice Returns the Uniswap V2 pair address for the given tokens.
     * @param tokenA Address of token A.
     * @param tokenB Address of token B.
     * @return pair The pair address.
     */
    function _pairFor(
        address tokenA,
        address tokenB
    ) private pure returns (address pair) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }
}
