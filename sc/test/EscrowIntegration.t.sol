// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {MockERC20} from "../src/MockERC20.sol";

/// @notice End-to-end integration tests covering multi-step workflows for the Escrow contract.
///         Each test deploys a fresh environment and exercises complete user journeys.
contract EscrowIntegrationTest is Test {
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
    // Full workflow tests
    // =========================================================

    /// @notice Deploy → whitelist → create → complete. Verifies all four final balances.
    function test_Integration_FullSwapWorkflow() public {
        // user1 creates 100 TKA → 50 TKB swap
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        // user2 completes the swap
        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        // user1: started 1000 TKA, gave 100, received 50 TKB
        assertEq(tokenA.balanceOf(user1), 900 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
        // user2: started 1000 TKB, gave 50, received 100 TKA
        assertEq(tokenA.balanceOf(user2), 100 ether);
        assertEq(tokenB.balanceOf(user2), 950 ether);
        // Escrow holds nothing
        assertEq(tokenA.balanceOf(address(escrow)), 0);
        assertEq(tokenB.balanceOf(address(escrow)), 0);

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 1);
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));
    }

    /// @notice Three operations created; only the middle one is completed.
    ///         The others must remain Active and escrow must still hold their tokenA.
    function test_Integration_MultipleOps_OneCompleted() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 300 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 0
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 1
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 2
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Active));
        assertEq(uint(ops[1].status), uint(Escrow.OperationStatus.Closed));
        assertEq(uint(ops[2].status), uint(Escrow.OperationStatus.Active));

        // Escrow still holds tokenA for ops 0 and 2
        assertEq(tokenA.balanceOf(address(escrow)), 200 ether);
    }

    /// @notice Create 3 ops, cancel two, complete one. Net balance check for user1.
    function test_Integration_CancelAndComplete_Mixed() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 300 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 0 — cancel
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 1 — complete
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 2 — cancel
        escrow.cancelOperation(0);
        escrow.cancelOperation(2);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        // user1 cancelled ops 0 and 2 (refunded 200 TKA), completed op1 (gave 100 TKA, got 50 TKB)
        // Started with 1000 TKA: -300 (deposited) +200 (refunded) = 900 TKA remaining
        assertEq(tokenA.balanceOf(user1), 900 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    /// @notice Owner whitelists a third token while an existing operation is active.
    ///         Existing op is unaffected; new op with the third token works fine.
    function test_Integration_OwnerAddsTokenMidSession() public {
        // Create an active op with tokenA/tokenB
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        // Owner adds tokenC mid-session
        vm.startPrank(owner);
        MockERC20 tokenC = new MockERC20("Token C", "TKC");
        escrow.addToken(address(tokenC));
        vm.stopPrank();

        // Existing op is still Active
        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Active));

        // New op using tokenC can be created
        tokenC.mint(user1, 100 ether);
        vm.startPrank(user1);
        tokenC.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenC), address(tokenA), 100 ether, 10 ether);
        vm.stopPrank();

        assertEq(escrow.getAllOperations().length, 2);
        assertTrue(escrow.allowedTokens(address(tokenC)));
    }

    /// @notice All three operation statuses in a single session; escrow holds only the Active one.
    function test_Integration_AllStatuses_InOneSession() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 300 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 0
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 1
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 2
        escrow.cancelOperation(0);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        // op 2 left Active
        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Cancelled));
        assertEq(uint(ops[1].status), uint(Escrow.OperationStatus.Closed));
        assertEq(uint(ops[2].status), uint(Escrow.OperationStatus.Active));

        // Escrow holds only the 100 TKA from op 2
        assertEq(tokenA.balanceOf(address(escrow)), 100 ether);
    }

    /// @notice Swap with very large amounts (1 000 000 ether). No overflow or rounding issues.
    function test_Integration_LargeAmounts() public {
        uint256 bigAmount = 1_000_000 ether;
        tokenA.mint(user1, bigAmount);
        tokenB.mint(user2, bigAmount);

        vm.startPrank(user1);
        tokenA.approve(address(escrow), bigAmount);
        escrow.createOperation(address(tokenA), address(tokenB), bigAmount, bigAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), bigAmount);
        escrow.completeOperation(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user2), bigAmount);
        assertEq(tokenB.balanceOf(user1), bigAmount);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    /// @notice Swap with minimum possible amounts (1 wei each).
    function test_Integration_MinimumAmounts_OneWei() public {
        tokenA.mint(user1, 1);
        tokenB.mint(user2, 1);

        vm.startPrank(user1);
        tokenA.approve(address(escrow), 1);
        escrow.createOperation(address(tokenA), address(tokenB), 1, 1);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 1);
        escrow.completeOperation(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user2), 1);
        assertEq(tokenB.balanceOf(user1), 1);
        assertEq(tokenA.balanceOf(address(escrow)), 0);
    }

    /// @notice Operation IDs are always sequential from 0, even after cancellations.
    function test_Integration_SequentialIds_AfterMixedOps() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 300 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // id 0
        escrow.cancelOperation(0);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // id 1
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        vm.startPrank(user1);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // id 2
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(ops.length, 3);
        assertEq(ops[0].id, 0);
        assertEq(ops[1].id, 1);
        assertEq(ops[2].id, 2);
    }

    /// @notice User1 creates both A→B and B→A operations; user2 completes both.
    function test_Integration_UserSwapsBothDirections() public {
        tokenB.mint(user1, 200 ether);

        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        tokenB.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether); // op 0: A→B
        escrow.createOperation(address(tokenB), address(tokenA), 100 ether, 75 ether); // op 1: B→A
        vm.stopPrank();

        tokenA.mint(user2, 75 ether);
        vm.startPrank(user2);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0); // user2 gives 50 TKB, gets 100 TKA

        tokenA.approve(address(escrow), 75 ether);
        escrow.completeOperation(1); // user2 gives 75 TKA, gets 100 TKB
        vm.stopPrank();

        // Both operations Closed
        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));
        assertEq(uint(ops[1].status), uint(Escrow.OperationStatus.Closed));

        // Escrow holds nothing
        assertEq(tokenA.balanceOf(address(escrow)), 0);
        assertEq(tokenB.balanceOf(address(escrow)), 0);
    }

    /// @notice The owner (not creator) can complete an operation — no role restriction on completer.
    function test_Integration_OwnerCanComplete_IfNotCreator() public {
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 50 ether);
        vm.stopPrank();

        tokenB.mint(owner, 50 ether);
        vm.startPrank(owner);
        tokenB.approve(address(escrow), 50 ether);
        escrow.completeOperation(0); // owner is not the creator, so this is allowed
        vm.stopPrank();

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));
        assertEq(tokenA.balanceOf(owner), 100 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
    }

    /// @notice Multiple users create operations; partial completions verified independently.
    function test_Integration_MultipleCreators_IndependentOps() public {
        tokenA.mint(user2, 200 ether);
        tokenB.mint(user1, 200 ether);

        // user1 creates op 0 (A→B), user2 creates op 1 (A→B)
        vm.startPrank(user1);
        tokenA.approve(address(escrow), 100 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 100 ether, 60 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(escrow), 200 ether);
        escrow.createOperation(address(tokenA), address(tokenB), 200 ether, 80 ether);
        vm.stopPrank();

        // user1 completes user2's op; user2 completes user1's op
        vm.startPrank(user1);
        tokenB.approve(address(escrow), 80 ether);
        escrow.completeOperation(1);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenB.approve(address(escrow), 60 ether);
        escrow.completeOperation(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(address(escrow)), 0);
        assertEq(tokenB.balanceOf(address(escrow)), 0);

        Escrow.Operation[] memory ops = escrow.getAllOperations();
        assertEq(uint(ops[0].status), uint(Escrow.OperationStatus.Closed));
        assertEq(uint(ops[1].status), uint(Escrow.OperationStatus.Closed));
    }
}
