// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MerkleComplianceRegistry} from "../src/MerkleComplianceRegistry.sol";
import {MockLendingPool} from "../src/MockLendingPool.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        bytes32 initialRoot = vm.envBytes32("INITIAL_COMPLIANCE_ROOT");

        vm.startBroadcast(deployerPrivateKey);

        MerkleComplianceRegistry registry = new MerkleComplianceRegistry(initialRoot, deployer);
        console.log("MerkleComplianceRegistry deployed at:", address(registry));

        MockLendingPool pool = new MockLendingPool(address(registry));
        console.log("MockLendingPool deployed at:", address(pool));

        vm.stopBroadcast();
    }
}