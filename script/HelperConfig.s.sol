// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

contract HelperConfig {
    struct NetworkConfig {
        address VRFCoordinator;
        bytes32 keyHash;
    }
}
