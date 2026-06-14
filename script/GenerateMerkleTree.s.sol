// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract GenerateMerkleTreeScript is Script {
    function run() external pure {
        address userAddress = 0x3bFcD0Ad593Fa31b469127d9a5F21B075F85897e;
        address demoAddress1 = address(uint160(0xdead));
        address demoAddress2 = address(uint160(0xbeef));
        address demoAddress3 = address(uint160(0xc0de));

        bytes32 leafUser = keccak256(abi.encodePacked(userAddress));
        bytes32 leaf1 = keccak256(abi.encodePacked(demoAddress1));
        bytes32 leaf2 = keccak256(abi.encodePacked(demoAddress2));
        bytes32 leaf3 = keccak256(abi.encodePacked(demoAddress3));

        bytes32 nodeUser1 = _hashPair(leafUser, leaf1);
        bytes32 node23 = _hashPair(leaf2, leaf3);
        bytes32 root = _hashPair(nodeUser1, node23);

        console.log("=== Merkle Tree Generated ===");
        console.log("");
        console.log("User Address:", userAddress);
        console.log("Demo Address 1:", demoAddress1);
        console.log("Demo Address 2:", demoAddress2);
        console.log("Demo Address 3:", demoAddress3);
        console.log("");
        console.log("MERKLE ROOT (use as INITIAL_COMPLIANCE_ROOT):");
        console.logBytes32(root);
        console.log("");
        console.log("PROOF FOR USER ADDRESS (2 elements):");
        console.log("Proof[0]:");
        console.logBytes32(leaf1);
        console.log("Proof[1]:");
        console.logBytes32(node23);
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}