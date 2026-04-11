// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        escrow = new Escrow();
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        escrow.addToken(address(tokenA));
        escrow.addToken(address(tokenB));
        vm.stopPrank();

        tokenA.mint(user1, 1000 ether);
        tokenB.mint(user2, 1000 ether);
    }

    // =========================================================
    // Original happy-path tests
    // =========================================================

    function test_AddToken() public {
        vm.startPrank(owner);
        MockERC20 tokenC = new MockERC20("Token C", "TKC");
        escrow.addToken(address(tokenC));
        vm.stopPrank();

        address[] memory allowed = escrow.getAllowedTokens();
        assertEq(allowed.length, 3);
        assertEq(allowed[2], address(tokenC));
    }

    function test_CreateOperation() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 1);
        assertEq(ops[0].creator, user1);
        assertEq(ops[0].tokenA, address(tokenA));
        assertEq(ops[0].tokenB, address(tokenB));
        assertEq(ops[0].amountA, 100 ether);
        assertEq(ops[0].amountB, 50 ether);
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Active));

        assertEq(tokenA.balanceOf(address(escrow)), 100 ether);
        assertEq(tokenA.balanceOf(user1), 900 ether);
    }

    function test_CompleteOperation() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));

        assertEq(tokenA.balanceOf(user2), 100 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    function test_CancelOperation() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.cancelOperation(0);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Cancelled));

        assertEq(tokenA.balanceOf(user1), 1000 ether);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    // =========================================================
    // Group A: addToken — access control and reverts
    // =========================================================

    function test_AddToken_OnlyOwner_Revert() public {
        MockERC20 tokenC = new MockERC20("Token C", "TKC");
        vm.prank(user1);
        vm.expectRevert();
        escrow.addToken(address(tokenC));
    }

    function test_AddToken_ZeroAddress_Revert() public {
        vm.prank(owner);
        vm.expectRevert("Invalid token address");
        escrow.addToken(address(0));
    }

    function test_AddToken_AlreadyAllowed_Revert() public {
        vm.prank(owner);
        vm.expectRevert("Token already allowed");
        escrow.addToken(address(tokenA));
    }

    function test_AddToken_UpdatesMappingAndList() public {
        assertTrue(escrow.allowedTokens(address(tokenA)));
        assertTrue(escrow.allowedTokens(address(tokenB)));

        address unregistered = address(0xDEAD);
        assertFalse(escrow.allowedTokens(unregistered));

        address[] memory allowed = escrow.getAllowedTokens();
        assertEq(allowed.length, 2);
        assertEq(allowed[0], address(tokenA));
        assertEq(allowed[1], address(tokenB));
    }

    function test_AddToken_EmitsTokenAdded() public {
        vm.startPrank(owner);
        MockERC20 tokenC = new MockERC20("Token C", "TKC");

        vm.expectEmit(true, false, false, false);
        emit Escrow.TokenAdded(address(tokenC));

        escrow.addToken(address(tokenC));
        vm.stopPrank();
    }

    // =========================================================
    // Group B: createOperation — reverts and state
    // =========================================================

    function test_CreateOperation_TokenA_NotAllowed_Revert() public {
        MockERC20 tokenX = new MockERC20("Token X", "TKX");
        vm.startPrank(user1);
        tokenX.mint(user1, 100 ether);
        tokenX.approve(address(escrow), 100 ether);
        vm.expectRevert("Token A not allowed");
        escrow.createOperation(address(tokenX), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();
    }

    function test_CreateOperation_TokenB_NotAllowed_Revert() public {
        MockERC20 tokenX = new MockERC20("Token X", "TKX");
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        vm.expectRevert("Token B not allowed");
        escrow.createOperation(address(tokenA), address(tokenX), 100 ether, 50 ether);
        vm.stopPrank();
    }

    function test_CreateOperation_AmountA_Zero_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        vm.expectRevert("Amount A must be specific");
        escrow.createOperation(address(tokenA), address(tokenB), 0, 50 ether);
        vm.stopPrank();
    }

    function test_CreateOperation_AmountB_Zero_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        vm.expectRevert("Amount B must be specific");
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 0);
        vm.stopPrank();
    }

    function test_CreateOperation_WithoutApproval_Revert() public {
        vm.prank(user1);
        vm.expectRevert();
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
    }

    function test_CreateOperation_EmitsOperationCreated() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);

        vm.expectEmit(true, true, false, true);
        emit Escrow.OperationCreated(0, user1, address(tokenA), address(tokenB), 100 ether, 50 ether);

        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();
    }

    function test_CreateOperation_SequentialIds() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 200 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 50 ether, 25 ether);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 2);
        assertEq(ops[0].id, 0);
        assertEq(ops[1].id, 1);
    }

    function test_CreateOperation_SameTokenBothSides() public {
        // No restriction on tokenA == tokenB — operation should be created successfully
        tokenA.mint(user1, 100 ether);
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenA), 100 ether, 50 ether);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 1);
        assertEq(ops[0].tokenA, address(tokenA));
        assertEq(ops[0].tokenB, address(tokenA));
    }

    // =========================================================
    // Group C: completeOperation — reverts and state
    // =========================================================

    function test_CompleteOperation_InvalidId_Revert() public {
        vm.prank(user2);
        vm.expectRevert("Invalid operation ID");
        escrow.completeOperation(999);
    }

    function test_CompleteOperation_NotActive_WhenClosed_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);

        // Attempt to complete again — now Closed
        tokenB.approve(address(escrow), 50 ether);
        vm.expectRevert("Operation not active");
        escrow.completeOperation(0);
        vm.stopPrank();
    }

    function test_CompleteOperation_NotActive_WhenCancelled_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.cancelOperation(0);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        vm.expectRevert("Operation not active");
        escrow.completeOperation(0);
        vm.stopPrank();
    }

    function test_CompleteOperation_CreatorCannotComplete_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);

        tokenB.mint(user1, 50 ether);
        tokenB.approve(address(escrow), 50 ether);
        vm.expectRevert("Cannot complete your own operation");
        escrow.completeOperation(0);
        vm.stopPrank();
    }

    function test_CompleteOperation_WithoutApproval_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert();
        escrow.completeOperation(0);
    }

    function test_CompleteOperation_EmitsOperationCompleted() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);

        vm.expectEmit(true, true, false, false);
        emit Escrow.OperationCompleted(0, user2);

        escrow.completeOperation(0);
        vm.stopPrank();
    }

    function test_CompleteOperation_CorrectBalancesAfterSwap() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user2), 100 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
        assertEq(tokenB.balanceOf(address(escrow)), 0);
    }

    function test_CompleteOperation_StatusIsClosed() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));
    }

    // =========================================================
    // Group D: cancelOperation — reverts and state
    // =========================================================

    function test_CancelOperation_InvalidId_Revert() public {
        vm.prank(user1);
        vm.expectRevert("Invalid operation ID");
        escrow.cancelOperation(999);
    }

    function test_CancelOperation_NotCreator_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.prank(user2);
        vm.expectRevert("Only creator can cancel");
        escrow.cancelOperation(0);
    }

    function test_CancelOperation_NotActive_WhenClosed_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert("Operation not active");
        escrow.cancelOperation(0);
    }

    function test_CancelOperation_NotActive_WhenCancelled_Revert() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.cancelOperation(0);

        vm.expectRevert("Operation not active");
        escrow.cancelOperation(0);
        vm.stopPrank();
    }

    function test_CancelOperation_EmitsOperationCancelled() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);

        vm.expectEmit(true, false, false, false);
        emit Escrow.OperationCancelled(0);

        escrow.cancelOperation(0);
        vm.stopPrank();
    }

    function test_CancelOperation_RefundsTokenA() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.cancelOperation(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user1), 1000 ether);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    function test_CancelOperation_StatusIsCancelled() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        escrow.cancelOperation(0);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Cancelled));
    }

    // =========================================================
    // Group E: view functions
    // =========================================================

    function test_GetAllowedTokens_ReturnsEmpty_Initially() public {
        Escrow freshEscrow = new Escrow();
        address[] memory allowed = freshEscrow.getAllowedTokens();
        assertEq(allowed.length, 0);
    }

    function test_GetAllOperations_ReturnsEmpty_Initially() public {
        Escrow freshEscrow = new Escrow();
        Escrow.Operation[] memory ops = freshEscrow.getAllOperations();
        assertEq(ops.length, 0);
    }

    function test_GetAllOperations_ReturnsAllStatuses() public {
        // Mint tokenB to user1 so they can create a B-side op too
        tokenB.mint(user1, 100 ether);

        // Create 3 operations all by user1
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 300 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 0
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 1
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 2

        // Cancel op 0
        escrow.cancelOperation(0);
        vm.stopPrank();

        // Complete op 1
        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        // op 2 remains Active
        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 3);
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Cancelled));
        assertEq(uint(ops[1].status), uint(Escrow.OperationStatus.Closed));
        assertEq(uint(ops[2].status), uint(Escrow.OperationStatus.Active));
    }

    // =========================================================
    // Group F: fuzz tests
    // =========================================================

    function test_Fuzz_CreateOperation_AmountA(uint256 amountA) public {
        vm.assume(amountA > 0 && amountA <= 1000 ether);
        tokenA.mint(user1, amountA);

        vm.startPrank(user1);
        tokenA.approve(address(escrow), amountA);
        escrow.createOperation(address(tokenA), address(tokenB), amountA, 1 ether);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops[0].amountA, amountA);
    }

    function test_Fuzz_AddToken_NonOwner(address caller) public {
        vm.assume(caller != owner && caller != address(0));
        MockERC20 tokenC = new MockERC20("Token C", "TKC");
        vm.prank(caller);
        vm.expectRevert();
        escrow.addToken(address(tokenC));
    }
}
