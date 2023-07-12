# Launchpad Contracts

## IPool

### initialize

```solidity
function initialize(address _owner) external returns (bool)
```

### setVesting

```solidity
function setVesting(struct Vesting vesting) external
```

### setPresale

```solidity
function setPresale(struct Presale saleInfo) external returns (uint256)
```

### getPoolData

```solidity
function getPoolData() external view returns (struct Presale, struct Vesting)
```

## Presale

```solidity
struct Presale {
  address currency;
  uint256 presaleRate;
  uint256 softcap;
  uint256 hardcap;
  uint256 minBuy;
  uint256 maxBuy;
  uint256 liquidityRate;
  uint256 listingRate;
  uint256 startTime;
  uint256 endTime;
  uint256 lockEndTime;
  bool isVesting;
  bool isLock;
  bool refund;
  bool autoListing;
}
```

## Vesting

```solidity
struct Vesting {
  uint256 tge;
  uint256 cliff;
  uint256 release;
  uint256 startTime;
}
```

## Contributor

```solidity
struct Contributor {
  uint256 totalContributed;
  uint256 claimable;
  uint256 claimed;
  uint256 released;
  bool tgeClaimed;
}
```

## IRouterV2

### addLiquidityETH

```solidity
function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
```

### addLiquidity

```solidity
function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

## IUniswapV2Factory

### getPair

```solidity
function getPair(address tokenA, address tokenB) external view returns (address pair)
```

## IUniswapV2Pair

### factory

```solidity
function factory() external view returns (address)
```

### token0

```solidity
function token0() external view returns (address)
```

### token1

```solidity
function token1() external view returns (address)
```

### getReserves

```solidity
function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)
```

### decimals

```solidity
function decimals() external pure returns (uint8)
```

## IERC20Minimal

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

## CurrencyLibrary

### safeTransferETH

```solidity
function safeTransferETH(address to, uint256 amount) internal
```

### safeTransferFrom

```solidity
function safeTransferFrom(address token, address from, address to, uint256 amount) internal
```

### safeTransfer

```solidity
function safeTransfer(address token, address to, uint256 amount) internal
```

### safeApprove

```solidity
function safeApprove(address token, address to, uint256 amount) internal
```

### balanceOf

```solidity
function balanceOf(address token, address owner) internal view returns (uint256)
```

## LPLib

### isLPToken

```solidity
function isLPToken(address currency) internal view returns (address factory)
```

Check if the given token is an LP token.

_This function uses the UniswapV2Pair interface to try and call the 'factory' method on the given token.
If the call is successful, the function further checks if the token is a valid LP token using _isValidLpToken helper function.
If the token is a valid LP token, the address of the factory that created the LP token is returned.
If the call to the 'factory' method fails, it implies that the token is not an LP token and a revert operation is executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| currency | address | The address of the token to be checked. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| factory | address | The address of the UniswapV2 factory that created the token if it's an LP token. Requirements: - The currency must be a valid LP token. |

## VestingLib

### calculateClaimableAmount

```solidity
function calculateClaimableAmount(struct Vesting vesting, struct Contributor contributor) internal returns (uint256 claimable)
```

Calculate the claimable token amount for a contributor considering vesting.

_This function first checks if the TGE (Token Generation Event) amount has been claimed by the contributor.
If not, it is added to the claimable amount and subtracted from the total claimable amount of the contributor.
It then checks if the vesting start time has been reached. If not, the claimable amount (only TGE amount at this point) is returned.
If the vesting start time has been reached, it calculates the current vesting phase based on the time passed since the start time and the duration of a cliff.
It then calculates the token amount per phase and the total claimable amount based on the number of phases that have passed since the last claim.
The total claimable amount is adjusted if it's larger than the remaining claimable amount of the contributor.
Finally, the function updates the total claimed amount of the contributor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| vesting | struct Vesting | The vesting data including start time, cliff duration, and release percentage. |
| contributor | struct Contributor | The contributor data including the total claimable amount, the amount already claimed, and the last claimed vesting phase. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| claimable | uint256 | The amount of tokens that can be claimed by the contributor at this point. Requirements: - The current phase must be greater than or equal to the last released phase. - The number of past phases must be greater than 0. |

## Lock

### LockInfo

```solidity
struct LockInfo {
  address currency;
  address owner;
  address factory;
  uint256 amount;
  uint256 startTime;
  uint256 endTime;
}
```

### locks

```solidity
mapping(uint256 => struct Lock.LockInfo) locks
```

### LockAdded

```solidity
event LockAdded(address currency, address owner, address factory, uint256 amount, uint256 startTime, uint256 endTime, uint256 lockId)
```

### LockUpdated

```solidity
event LockUpdated(address currency, address owner, address factory, uint256 amount, uint256 startTime, uint256 endTime, uint256 lockId)
```

### Unlocked

```solidity
event Unlocked(address currency, address owner, address factory, uint256 amount, uint256 startTime, uint256 endTime, uint256 lockId)
```

### lockTokens

```solidity
function lockTokens(address _currency, address _owner, uint256 amount, uint256 endTime, bool isLPToken) external returns (bool)
```

This function locks a specified amount of tokens until a given end time.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _currency | address | The address of the token contract to lock tokens from. |
| _owner | address | The address of the user locking the tokens. |
| amount | uint256 | The amount of tokens to be locked. |
| endTime | uint256 | The unix timestamp after which the tokens can be unlocked. |
| isLPToken | bool | A boolean value indicating whether the locked token is a LP (Liquidity Pool) token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the tokens were locked successfully. Requirements: - `amount` must be less than or equal to the balance of the `msg.sender`. - `endTime` must be greater than the current block timestamp. Emits an {LockAdded} event with relevant data. |

### editTokensLock

```solidity
function editTokensLock(uint256 lockId, uint256 newAmount, uint256 newEndTime) external returns (bool)
```

This function modifies the lock conditions of a specific lock.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lockId | uint256 | The ID of the lock to be modified. |
| newAmount | uint256 | The new amount of tokens to be locked. |
| newEndTime | uint256 | The new unix timestamp after which the tokens can be unlocked. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the lock conditions were successfully modified. Requirements: - `lockId` must be less than or equal to the total number of locks. - The caller must be the owner of the lock. - `newAmount` must be greater than or equal to the current locked amount and greater than 0. - `newEndTime` must be greater than the current end time and the current block timestamp. Emits a {LockUpdated} event with relevant data. |

### unlockTokens

```solidity
function unlockTokens(uint256 lockId) external returns (bool)
```

This function unlocks tokens that were previously locked.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lockId | uint256 | The ID of the lock to be unlocked. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the tokens were successfully unlocked. Requirements: - `lockId` must be less than or equal to the total number of locks. - The caller must be the owner of the lock. - The locked amount must be greater than 0. - The end time of the lock must be less than or equal to the current block timestamp. Emits a {LockUpdated} event with relevant data, and deletes the lock from the `locks` mapping. |

## ILock

### lockTokens

```solidity
function lockTokens(address _currency, address _owner, uint256 amount, uint256 endTime, bool isLPToken) external returns (bool)
```

## Pool

### Stats

```solidity
struct Stats {
  uint256 totalContributed;
  uint256 totalTokenAmount;
  uint256 totalClaimed;
  bool isFinalized;
  bool isCancelled;
}
```

### Contribute

```solidity
event Contribute(address contributor, uint256 amount, uint256 timestamp)
```

### Claimed

```solidity
event Claimed(address contributor, uint256 amount, uint256 timestamp)
```

### EmergencyWithdrawal

```solidity
event EmergencyWithdrawal(address contributor, uint256 amount, uint256 timestamp)
```

### Finalized

```solidity
event Finalized(uint256 timestamp)
```

### Cancelled

```solidity
event Cancelled(uint256 timestam)
```

### AddedWhitelist

```solidity
event AddedWhitelist(uint256 addresses, uint256 timestamp)
```

### Withdrawn

```solidity
event Withdrawn(address user, uint256 amount, uint256 timestamp)
```

### ClaimError

```solidity
error ClaimError(address user)
```

### isInitialized

```solidity
modifier isInitialized()
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### onlyFactory

```solidity
modifier onlyFactory()
```

### constructor

```solidity
constructor(address lock) public
```

### receive

```solidity
receive() external payable
```

### fallback

```solidity
fallback() external payable
```

### initialize

```solidity
function initialize(address owner) external returns (bool)
```

This function initializes the contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The address of the owner of the contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the initialization was successful. Sets the contract `_factory` to the caller of the function and the contract `_owner` to the provided owner address. |

### setVesting

```solidity
function setVesting(struct Vesting vesting) external
```

This function sets the vesting schedule for the proxy contract.

_The function can only be called by the factory._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| vesting | struct Vesting | A `Vesting` struct containing the vesting schedule details. |

### setPresale

```solidity
function setPresale(struct Presale saleInfo) external returns (uint256)
```

This function sets the presale details for the proxy contract.

_The function can only be called by the factory._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| saleInfo | struct Presale | A `Presale` struct containing the presale details. |

### withdraw

```solidity
function withdraw() external
```

Allows for withdrawal of contributed funds if the presale is cancelled.

_This function can only be executed if the presale has been cancelled. The function is protected against reentrancy attacks._

### cancel

```solidity
function cancel() external returns (bool)
```

Cancels the presale and transfers the total token amount back to the owner.

_This function can only be executed by the owner._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the operation succeeded. |

### finalize

```solidity
function finalize() external returns (bool)
```

Finalizes the presale based on the defined conditions and distributes the funds accordingly.

_This function can only be executed by the owner._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating whether the operation succeeded. |

### setWhitelist

```solidity
function setWhitelist(address[] whitelistAddresses) external
```

Sets the whitelist of addresses allowed to participate in the presale.

_This function can only be executed by the owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| whitelistAddresses | address[] | An array of addresses to be added to the whitelist. |

### changeFactoryAddress

```solidity
function changeFactoryAddress(address factory) external
```

Changes the factory address used for the presale.

_This function can only be executed by the current factory address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| factory | address | The new factory address to be set. |

### claim

```solidity
function claim() external
```

Claims the vested tokens or available tokens for the caller.

_If the presale has vesting enabled, it calls the `_vestingClaim` function to claim the vested tokens.
Otherwise, it calls the `_claim` function to claim the available tokens.
If the claim is unsuccessful, it reverts with a `ClaimError` indicating the caller's address._

### emergencyWithdrawal

```solidity
function emergencyWithdrawal() external
```

Performs an emergency withdrawal for the caller.

_Allows a contributor to perform an emergency withdrawal of their contributed funds.
It can only be called before the presale is finalized.
The contributor's total contribution is deducted from the presale's total contributed amount.
20% of the total contribution is transferred to the caller as the withdrawal amount.
The remaining 80% is transferred to the caller as a fee.
The contributor's total contribution and claimable amount are set to 0._

### contribute

```solidity
function contribute() public payable returns (bool)
```

Contributes funds to the presale.

_Allows a user to contribute funds to the presale by sending Ether to the contract.
The function performs various checks before accepting the contribution:
- If the presale has a whitelist, the caller must be whitelisted.
- The presale must not be cancelled or finalized.
- The current block timestamp must be within the presale's start and end time.
- The total contributed amount plus the sent value must not exceed the presale's hardcap.
- The caller's total contribution plus the sent value must not exceed the presale's max buy limit.
- The sent value must be greater than or equal to the presale's min buy limit.
If all checks pass, the contribution is recorded:
- The sent value is added to the presale's total contributed amount.
- The sent value is added to the caller's total contribution amount.
- The caller's claimable amount is increased based on the presale rate._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean value indicating the success of the contribution. |

### getPoolData

```solidity
function getPoolData() public view returns (struct Presale, struct Vesting)
```

Retrieves the pool data including the presale and vesting information.

_Only the factory address can call this function._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Presale | A tuple containing the presale and vesting information. |
| [1] | struct Vesting |  |

## PoolManager

### PresaleCreated

```solidity
event PresaleCreated(address presaleAddress, address currency, uint256 amount, uint256 startTime, uint256 endTime)
```

### constructor

```solidity
constructor(address _signer, address poolAddress) public
```

### createPresale

```solidity
function createPresale(struct Presale newPresale, struct Vesting vesting, bytes signature) external returns (address)
```

Creates a new presale contract with the given presale details.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newPresale | struct Presale | The presale details to be set for the new presale contract. |
| vesting | struct Vesting | The vesting details to be set for the new presale contract. |
| signature | bytes | The signature for the presale details, used for signature verification. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the newly created presale contract. |

### withdrawAll

```solidity
function withdrawAll() external
```

Withdraws all the remaining ETH balance from the contract to the owner's address.

### presales

```solidity
function presales(uint256 index) external view returns (address poolAddress)
```

Returns the address of the presale contract at the specified index in the `_presales` array.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | The index of the presale contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The address of the presale contract. |

### getAllPresales

```solidity
function getAllPresales() external view returns (address[] poolAddress)
```

Returns an array of all presale contract addresses created by the owner.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address[] | An array of presale contract addresses. |

### getPresalesData

```solidity
function getPresalesData(contract IPool poolAddress) external view returns (struct Presale presaleDatas, struct Vesting vestingDatas)
```

Returns the presale and vesting data of a specific presale contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | contract IPool | The address of the presale contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| presaleDatas | struct Presale | The presale data of the specified presale contract. |
| vestingDatas | struct Vesting | The vesting data of the specified presale contract. |

### getPoolAddress

```solidity
function getPoolAddress(address poolOwner, address currency) external view returns (address poolAddress)
```

Returns the predicted address of a presale pool based on the pool owner and currency.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolOwner | address | The address of the presale pool owner. |
| currency | address | The address of the presale currency. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | The predicted address of the presale pool. |

## SignatureChecker

### constructor

```solidity
constructor(address signer) internal
```

Initializes the contract with the specified signer address and creates the domain separator.

_The signer address cannot be the zero address.
The domain separator is generated using the EIP-712 standard and includes the contract's name, version, chain ID, and verifying contract address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signer | address | The address of the signer. |

### changeSigner

```solidity
function changeSigner(address newSigner) external returns (bool)
```

Changes the signer address.

_Only the contract owner can change the signer address.
The new signer address cannot be the zero address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newSigner | address | The new signer address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean indicating whether the signer address was successfully changed. |

### recover

```solidity
function recover(struct Presale presale, bytes signature) public view returns (bool)
```

Recovers the signer address from the provided signature.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| presale | struct Presale | The Presale struct containing the data to be signed. |
| signature | bytes | The signature to recover the signer address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean indicating whether the signature is valid and matches the signer address. |

### split

```solidity
function split(bytes signature) public pure returns (uint8, bytes32, bytes32)
```

Splits the provided signature into its components: v, r, and s.

_Assumes that the signature is in the correct format (65 bytes)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| signature | bytes | The signature to split. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | The components v, r, and s of the signature. |
| [1] | bytes32 |  |
| [2] | bytes32 |  |

## MockERC20

### constructor

```solidity
constructor() public
```

## Ownable

### owner

```solidity
address owner
```

### OwnershipTransferred

```solidity
event OwnershipTransferred(address user, address newOwner)
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### constructor

```solidity
constructor() internal
```

### transferOwnership

```solidity
function transferOwnership(address newOwner) public virtual
```

### renounceOwnership

```solidity
function renounceOwnership() public virtual
```

## MockERC20

### constructor

```solidity
constructor() public
```

## ReentrancyGuard

### nonReentrant

```solidity
modifier nonReentrant()
```

## IERC20Minimal

Contains a subset of the full ERC20 interface that is used in Uniswap V3

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

Returns the balance of a token

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account for which to look up the number of tokens it has, i.e. its balance |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of tokens held by the account |

### factory

```solidity
function factory() external view returns (address)
```

### getReserves

```solidity
function getReserves() external view returns (uint256, uint256, uint256)
```

### transfer

```solidity
function transfer(address recipient, uint256 amount) external returns (bool)
```

Transfers the amount of token from the `msg.sender` to the recipient

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The account that will receive the amount transferred |
| amount | uint256 | The number of tokens to send from the sender to the recipient |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful transfer, false for an unsuccessful transfer |

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

Returns the current allowance given to a spender by an owner

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The account of the token owner |
| spender | address | The account of the token spender |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current allowance granted by `owner` to `spender` |

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

Sets the allowance of a spender from the `msg.sender` to the value `amount`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | The account which will be allowed to spend a given amount of the owners tokens |
| amount | uint256 | The amount of tokens allowed to be used by `spender` |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful approval, false for unsuccessful |

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
```

Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | The account from which the transfer will be initiated |
| recipient | address | The recipient of the transfer |
| amount | uint256 | The amount of the transfer |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Returns true for a successful transfer, false for unsuccessful |

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The account from which the tokens were sent, i.e. the balance decreased |
| to | address | The account to which the tokens were sent, i.e. the balance increased |
| value | uint256 | The amount of tokens that were transferred |

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

Event emitted when the approval amount for the spender of a given owner's tokens changes.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The account that approved spending of its tokens |
| spender | address | The account for which the spending allowance was modified |
| value | uint256 | The new allowance from the owner to the spender |

