// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleComplianceRegistry is Ownable {
    bytes32 public complianceRoot;

    mapping(bytes32 => bool) public revokedRoots;

    event ComplianceRootUpdated(bytes32 indexed oldRoot, bytes32 indexed newRoot, uint256 timestamp);
    event RootRevoked(bytes32 indexed root, uint256 timestamp);

    error InvalidRoot();
    error RootIsRevoked();

    constructor(bytes32 _initialRoot, address _owner) Ownable(_owner) {
        if (_initialRoot == bytes32(0)) revert InvalidRoot();
        complianceRoot = _initialRoot;
    }

    function updateComplianceRoot(bytes32 _newRoot) external onlyOwner {
        if (_newRoot == bytes32(0)) revert InvalidRoot();
        if (revokedRoots[_newRoot]) revert RootIsRevoked();

        bytes32 oldRoot = complianceRoot;
        complianceRoot = _newRoot;

        emit ComplianceRootUpdated(oldRoot, _newRoot, block.timestamp);
    }

    function revokeRoot(bytes32 _root) external onlyOwner {
        revokedRoots[_root] = true;
        emit RootRevoked(_root, block.timestamp);
    }

    function verifyCompliance(address _account, bytes32[] calldata _proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_proof, complianceRoot, leaf);
    }

    function verifyComplianceWithRoot(address _account, bytes32[] calldata _proof, bytes32 _root)
        external
        view
        returns (bool)
    {
        if (revokedRoots[_root]) return false;
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProof.verify(_proof, _root, leaf);
    }
}