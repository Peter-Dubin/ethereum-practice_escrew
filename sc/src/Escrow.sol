// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Escrow — Trustless peer-to-peer ERC20 token swap contract
/// @author Peter Dubin
/// @notice Allows two parties to atomically swap whitelisted ERC20 tokens without a trusted intermediary.
///         The contract owner controls which tokens are eligible. Any user can create a swap offer;
///         any other user can fulfill it.
/// @dev Inherits OpenZeppelin Ownable (v5) and ReentrancyGuard. Uses SafeERC20 for all token transfers
///      to handle non-standard ERC20 implementations safely.
contract Escrow is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Lifecycle states of a swap operation.
    /// @dev Operations start as Active and transition to either Closed (completed) or Cancelled.
    ///      State transitions are one-way and cannot be reversed.
    enum OperationStatus { Active, Closed, Cancelled }

    /// @notice Represents a single pending or completed token swap.
    /// @dev Stored in the `operations` array; the array index equals the operation ID.
    ///      All fields are set at creation and immutable except for `status`.
    struct Operation {
        uint256 id;             // Sequential identifier assigned at creation time
        address creator;        // Address that created the operation and deposited tokenA
        address tokenA;         // Token deposited by the creator
        address tokenB;         // Token requested from the completer
        uint256 amountA;        // Exact amount of tokenA deposited and held in escrow
        uint256 amountB;        // Exact amount of tokenB required to complete the swap
        OperationStatus status; // Current lifecycle state of this operation
    }

    /// @notice Returns true if the token address has been whitelisted by the owner.
    mapping(address => bool) public allowedTokens;

    /// @notice Ordered list of all whitelisted token addresses.
    /// @dev Append-only; tokens are never removed from the whitelist once added.
    address[] public allowedTokensList;

    /// @notice Array of all swap operations indexed by operation ID.
    /// @dev New operations are pushed; existing entries are never deleted, only their status changes.
    Operation[] public operations;

    /// @notice Emitted when the owner adds a new token to the whitelist.
    /// @param token Address of the ERC20 token that was whitelisted.
    event TokenAdded(address indexed token);

    /// @notice Emitted when a user creates a new swap operation.
    /// @param id      Unique sequential identifier of the new operation.
    /// @param creator Address that created the operation and deposited tokenA.
    /// @param tokenA  Address of the token deposited by the creator.
    /// @param tokenB  Address of the token requested from the completer.
    /// @param amountA Amount of tokenA deposited into the escrow.
    /// @param amountB Amount of tokenB required to complete the swap.
    event OperationCreated(uint256 indexed id, address indexed creator, address tokenA, address tokenB, uint256 amountA, uint256 amountB);

    /// @notice Emitted when a swap operation is successfully fulfilled.
    /// @param id        Identifier of the completed operation.
    /// @param completer Address that provided tokenB and received tokenA.
    event OperationCompleted(uint256 indexed id, address indexed completer);

    /// @notice Emitted when a creator cancels their own active operation.
    /// @param id Identifier of the cancelled operation.
    event OperationCancelled(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    /// @notice Adds an ERC20 token to the whitelist, enabling its use in swap operations.
    /// @dev Only callable by the contract owner. The token address must be non-zero and not
    ///      already whitelisted. Once added, tokens cannot be removed.
    /// @param token Address of the ERC20 token to whitelist.
    function addToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!allowedTokens[token], "Token already allowed");

        allowedTokens[token] = true;
        allowedTokensList.push(token);

        emit TokenAdded(token);
    }

    /// @notice Creates a new swap operation by depositing tokenA into the escrow.
    /// @dev The caller must have approved at least `amountA` of `tokenA` to this contract
    ///      before calling this function. Both tokens must be whitelisted and amounts must be
    ///      greater than zero. Protected by nonReentrant.
    /// @param tokenA  Address of the ERC20 token the caller is offering.
    /// @param tokenB  Address of the ERC20 token the caller is requesting.
    /// @param amountA Amount of tokenA to deposit into escrow.
    /// @param amountB Amount of tokenB required from the completer to fulfill the swap.
    function createOperation(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external nonReentrant {
        require(allowedTokens[tokenA], "Token A not allowed");
        require(allowedTokens[tokenB], "Token B not allowed");
        require(amountA > 0, "Amount A must be specific");
        require(amountB > 0, "Amount B must be specific");

        uint256 operationId = operations.length;

        operations.push(Operation({
            id: operationId,
            creator: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            status: OperationStatus.Active
        }));

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);

        emit OperationCreated(operationId, msg.sender, tokenA, tokenB, amountA, amountB);
    }

    /// @notice Completes an active swap: the caller provides tokenB and receives tokenA.
    /// @dev The caller must have approved at least `op.amountB` of `op.tokenB` to this contract.
    ///      The operation must be Active. The caller cannot be the original creator.
    ///      tokenB is transferred directly from the caller to the creator (not through escrow).
    ///      tokenA is transferred from escrow to the caller. Protected by nonReentrant.
    /// @param operationId The ID of the operation to complete.
    function completeOperation(uint256 operationId) external nonReentrant {
        require(operationId < operations.length, "Invalid operation ID");
        Operation storage op = operations[operationId];
        require(op.status == OperationStatus.Active, "Operation not active");
        require(msg.sender != op.creator, "Cannot complete your own operation");

        op.status = OperationStatus.Closed;

        IERC20(op.tokenB).safeTransferFrom(msg.sender, op.creator, op.amountB);
        IERC20(op.tokenA).safeTransfer(msg.sender, op.amountA);

        emit OperationCompleted(operationId, msg.sender);
    }

    /// @notice Cancels an active operation and refunds tokenA to the creator.
    /// @dev Only the original creator of the operation may cancel it. The operation must be Active.
    ///      tokenA is returned from escrow to the creator. Protected by nonReentrant.
    /// @param operationId The ID of the operation to cancel.
    function cancelOperation(uint256 operationId) external nonReentrant {
        require(operationId < operations.length, "Invalid operation ID");
        Operation storage op = operations[operationId];
        require(op.status == OperationStatus.Active, "Operation not active");
        require(msg.sender == op.creator, "Only creator can cancel");

        op.status = OperationStatus.Cancelled;

        IERC20(op.tokenA).safeTransfer(msg.sender, op.amountA);

        emit OperationCancelled(operationId);
    }

    /// @notice Returns the complete list of whitelisted token addresses.
    /// @return Array of all ERC20 token addresses that have been approved by the owner.
    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokensList;
    }

    /// @notice Returns all swap operations ever created, regardless of status.
    /// @return Array of all Operation structs (Active, Closed, and Cancelled).
    function getAllOperations() external view returns (Operation[] memory) {
        return operations;
    }
}
