// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract Escrow is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum OperationStatus { Active, Closed, Cancelled }

    struct Operation {
        uint256 id;
        address creator;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        OperationStatus status;
    }

    mapping(address => bool) public allowedTokens;
    address[] public allowedTokensList;
    
    Operation[] public operations;

    event TokenAdded(address indexed token);
    event OperationCreated(uint256 indexed id, address indexed creator, address tokenA, address tokenB, uint256 amountA, uint256 amountB);
    event OperationCompleted(uint256 indexed id, address indexed completer);
    event OperationCancelled(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    function addToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!allowedTokens[token], "Token already allowed");
        
        allowedTokens[token] = true;
        allowedTokensList.push(token);
        
        emit TokenAdded(token);
    }

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

    function cancelOperation(uint256 operationId) external nonReentrant {
        require(operationId < operations.length, "Invalid operation ID");
        Operation storage op = operations[operationId];
        require(op.status == OperationStatus.Active, "Operation not active");
        require(msg.sender == op.creator, "Only creator can cancel");

        op.status = OperationStatus.Cancelled;

        IERC20(op.tokenA).safeTransfer(msg.sender, op.amountA);

        emit OperationCancelled(operationId);
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokensList;
    }

    function getAllOperations() external view returns (Operation[] memory) {
        return operations;
    }
}
