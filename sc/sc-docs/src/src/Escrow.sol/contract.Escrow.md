# Escrow
[Git Source](https://github.com/Peter-Dubin/ethereum-practice_escrew/blob/8fbb9cccf1eb0f4882f3677d19c2dc9b84f03cdd/src/Escrow.sol)

**Inherits:**
Ownable, ReentrancyGuard

**Title:**
Escrow — Trustless peer-to-peer ERC20 token swap contract

**Author:**
Peter Dubin

Allows two parties to atomically swap whitelisted ERC20 tokens without a trusted intermediary.
The contract owner controls which tokens are eligible. Any user can create a swap offer;
any other user can fulfill it.

Inherits OpenZeppelin Ownable (v5) and ReentrancyGuard. Uses SafeERC20 for all token transfers
to handle non-standard ERC20 implementations safely.


## State Variables
### allowedTokens
Returns true if the token address has been whitelisted by the owner.


```solidity
mapping(address => bool) public allowedTokens
```


### allowedTokensList
Ordered list of all whitelisted token addresses.

Append-only; tokens are never removed from the whitelist once added.


```solidity
address[] public allowedTokensList
```


### operations
Array of all swap operations indexed by operation ID.

New operations are pushed; existing entries are never deleted, only their status changes.


```solidity
Operation[] public operations
```


## Functions
### constructor


```solidity
constructor() Ownable(msg.sender);
```

### addToken

Adds an ERC20 token to the whitelist, enabling its use in swap operations.

Only callable by the contract owner. The token address must be non-zero and not
already whitelisted. Once added, tokens cannot be removed.


```solidity
function addToken(address token) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the ERC20 token to whitelist.|


### createOperation

Creates a new swap operation by depositing tokenA into the escrow.

The caller must have approved at least `amountA` of `tokenA` to this contract
before calling this function. Both tokens must be whitelisted and amounts must be
greater than zero. Protected by nonReentrant.


```solidity
function createOperation(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenA`|`address`| Address of the ERC20 token the caller is offering.|
|`tokenB`|`address`| Address of the ERC20 token the caller is requesting.|
|`amountA`|`uint256`|Amount of tokenA to deposit into escrow.|
|`amountB`|`uint256`|Amount of tokenB required from the completer to fulfill the swap.|


### completeOperation

Completes an active swap: the caller provides tokenB and receives tokenA.

The caller must have approved at least `op.amountB` of `op.tokenB` to this contract.
The operation must be Active. The caller cannot be the original creator.
tokenB is transferred directly from the caller to the creator (not through escrow).
tokenA is transferred from escrow to the caller. Protected by nonReentrant.


```solidity
function completeOperation(uint256 operationId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operationId`|`uint256`|The ID of the operation to complete.|


### cancelOperation

Cancels an active operation and refunds tokenA to the creator.

Only the original creator of the operation may cancel it. The operation must be Active.
tokenA is returned from escrow to the creator. Protected by nonReentrant.


```solidity
function cancelOperation(uint256 operationId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`operationId`|`uint256`|The ID of the operation to cancel.|


### getAllowedTokens

Returns the complete list of whitelisted token addresses.


```solidity
function getAllowedTokens() external view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|Array of all ERC20 token addresses that have been approved by the owner.|


### getAllOperations

Returns all swap operations ever created, regardless of status.


```solidity
function getAllOperations() external view returns (Operation[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Operation[]`|Array of all Operation structs (Active, Closed, and Cancelled).|


## Events
### TokenAdded
Emitted when the owner adds a new token to the whitelist.


```solidity
event TokenAdded(address indexed token);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the ERC20 token that was whitelisted.|

### OperationCreated
Emitted when a user creates a new swap operation.


```solidity
event OperationCreated(
    uint256 indexed id, address indexed creator, address tokenA, address tokenB, uint256 amountA, uint256 amountB
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|     Unique sequential identifier of the new operation.|
|`creator`|`address`|Address that created the operation and deposited tokenA.|
|`tokenA`|`address`| Address of the token deposited by the creator.|
|`tokenB`|`address`| Address of the token requested from the completer.|
|`amountA`|`uint256`|Amount of tokenA deposited into the escrow.|
|`amountB`|`uint256`|Amount of tokenB required to complete the swap.|

### OperationCompleted
Emitted when a swap operation is successfully fulfilled.


```solidity
event OperationCompleted(uint256 indexed id, address indexed completer);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|       Identifier of the completed operation.|
|`completer`|`address`|Address that provided tokenB and received tokenA.|

### OperationCancelled
Emitted when a creator cancels their own active operation.


```solidity
event OperationCancelled(uint256 indexed id);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`uint256`|Identifier of the cancelled operation.|

## Structs
### Operation
Represents a single pending or completed token swap.

Stored in the `operations` array; the array index equals the operation ID.
All fields are set at creation and immutable except for `status`.


```solidity
struct Operation {
    uint256 id; // Sequential identifier assigned at creation time
    address creator; // Address that created the operation and deposited tokenA
    address tokenA; // Token deposited by the creator
    address tokenB; // Token requested from the completer
    uint256 amountA; // Exact amount of tokenA deposited and held in escrow
    uint256 amountB; // Exact amount of tokenB required to complete the swap
    OperationStatus status; // Current lifecycle state of this operation
}
```

## Enums
### OperationStatus
Lifecycle states of a swap operation.

Operations start as Active and transition to either Closed (completed) or Cancelled.
State transitions are one-way and cannot be reversed.


```solidity
enum OperationStatus {
    Active,
    Closed,
    Cancelled
}
```

