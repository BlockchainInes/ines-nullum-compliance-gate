// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleComplianceRegistry} from "./MerkleComplianceRegistry.sol";

abstract contract ComplianceGate {
    MerkleComplianceRegistry public immutable complianceRegistry;

    error NotCompliant(address account);

    constructor(address _complianceRegistry) {
        complianceRegistry = MerkleComplianceRegistry(_complianceRegistry);
    }

    modifier onlyCompliant(bytes32[] calldata _proof) {
        if (!complianceRegistry.verifyCompliance(msg.sender, _proof)) {
            revert NotCompliant(msg.sender);
        }
        _;
    }
}