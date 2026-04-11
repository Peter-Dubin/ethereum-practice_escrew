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
}
