// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MerkleComplianceRegistry} from "../src/MerkleComplianceRegistry.sol";
import {ComplianceGate} from "../src/ComplianceGate.sol";
import {MockLendingPool} from "../src/MockLendingPool.sol";

contract NullumComplianceGateTest is Test {
    MerkleComplianceRegistry public registry;
    MockLendingPool public pool;

    address public owner = address(this);
    address public alice = address(0x1111);
    address public bob = address(0x2222);
    address public carol = address(0x3333);
    address public dave = address(0x4444);
    address public eve = address(0x5555);

    bytes32 public leafAlice;
    bytes32 public leafBob;
    bytes32 public leafCarol;
    bytes32 public leafDave;

    bytes32 public root;

    function setUp() public {
        leafAlice = keccak256(abi.encodePacked(alice));
        leafBob = keccak256(abi.encodePacked(bob));
        leafCarol = keccak256(abi.encodePacked(carol));
        leafDave = keccak256(abi.encodePacked(dave));

        bytes32 nodeAB = _hashPair(leafAlice, leafBob);
        bytes32 nodeCD = _hashPair(leafCarol, leafDave);
        root = _hashPair(nodeAB, nodeCD);

        registry = new MerkleComplianceRegistry(root, owner);
        pool = new MockLendingPool(address(registry));

        vm.deal(alice, 10 ether);
        vm.deal(eve, 10 ether);
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function _proofForAlice() internal view returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leafBob;
        proof[1] = _hashPair(leafCarol, leafDave);
        return proof;
    }

    function _proofForBob() internal view returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leafAlice;
        proof[1] = _hashPair(leafCarol, leafDave);
        return proof;
    }

    function test_VerifyCompliance_ValidProof_ReturnsTrue() public view {
        bytes32[] memory proof = _proofForAlice();
        bool result = registry.verifyCompliance(alice, proof);
        assertTrue(result);
    }

    function test_VerifyCompliance_WrongAccount_ReturnsFalse() public view {
        bytes32[] memory proof = _proofForAlice();
        bool result = registry.verifyCompliance(eve, proof);
        assertFalse(result);
    }

    function test_VerifyCompliance_InvalidProof_ReturnsFalse() public view {
        bytes32[] memory proof = _proofForBob();
        bool result = registry.verifyCompliance(alice, proof);
        assertFalse(result);
    }

    function test_UpdateComplianceRoot_OnlyOwner() public {
        bytes32 newRoot = keccak256("new root");

        vm.prank(eve);
        vm.expectRevert();
        registry.updateComplianceRoot(newRoot);

        registry.updateComplianceRoot(newRoot);
        assertEq(registry.complianceRoot(), newRoot);
    }

    function test_UpdateComplianceRoot_ZeroRoot_Reverts() public {
        vm.expectRevert(MerkleComplianceRegistry.InvalidRoot.selector);
        registry.updateComplianceRoot(bytes32(0));
    }

    function test_RevokeRoot_BlocksVerification() public {
        registry.revokeRoot(root);

        bytes32[] memory proof = _proofForAlice();
        bool result = registry.verifyComplianceWithRoot(alice, proof, root);
        assertFalse(result);
    }

    function test_Deposit_CompliantUser_Succeeds() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(alice);
        pool.deposit{value: 1 ether}(proof);

        assertEq(pool.deposits(alice), 1 ether);
        assertEq(pool.totalDeposits(), 1 ether);
    }

    function test_Deposit_NonCompliantUser_Reverts() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(eve);
        vm.expectRevert(abi.encodeWithSelector(ComplianceGate.NotCompliant.selector, eve));
        pool.deposit{value: 1 ether}(proof);
    }

    function test_Deposit_ZeroAmount_Reverts() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(alice);
        vm.expectRevert(MockLendingPool.ZeroAmount.selector);
        pool.deposit{value: 0}(proof);
    }

    function test_WithdrawAfterDeposit_Succeeds() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(alice);
        pool.deposit{value: 2 ether}(proof);

        vm.prank(alice);
        pool.withdraw(1 ether, proof);

        assertEq(pool.deposits(alice), 1 ether);
        assertEq(alice.balance, 9 ether);
    }

    function test_Withdraw_InsufficientBalance_Reverts() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(alice);
        pool.deposit{value: 1 ether}(proof);

        vm.prank(alice);
        vm.expectRevert(MockLendingPool.InsufficientBalance.selector);
        pool.withdraw(2 ether, proof);
    }

    function test_Borrow_InsufficientLiquidity_Reverts() public {
        bytes32[] memory proof = _proofForAlice();

        vm.prank(alice);
        vm.expectRevert(MockLendingPool.InsufficientLiquidity.selector);
        pool.borrow(1 ether, proof);
    }

    function test_BorrowAndRepay_Succeeds() public {
        bytes32[] memory proofAlice = _proofForAlice();

        vm.prank(alice);
        pool.deposit{value: 5 ether}(proofAlice);

        vm.prank(alice);
        pool.borrow(1 ether, proofAlice);

        assertEq(pool.borrowed(alice), 1 ether);

        vm.prank(alice);
        pool.repay{value: 1 ether}(proofAlice);

        assertEq(pool.borrowed(alice), 0);
    }
}