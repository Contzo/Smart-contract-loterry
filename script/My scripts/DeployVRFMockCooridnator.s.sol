// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployVRFMockCooridnator is Script {
    function run(
        uint96 _baseFee,
        uint96 _gasPrice,
        int256 _weiPerUnitLink
    ) external returns (VRFCoordinatorV2_5Mock) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            _baseFee,
            _gasPrice,
            _weiPerUnitLink
        );
        vm.stopBroadcast();
        return vrfCoordinator;
    }
}
