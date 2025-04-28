// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployVRFMockCooridnator} from "./DeployVRFMockCooridnator.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffleScript is Script {
    function run() external {
        DeployVRFMockCooridnator deployVRFMock = new DeployVRFMockCooridnator();
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = deployVRFMock.run(
            0.25 ether,
            1e9,
            1e18
        );
        uint256 subscriptionId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subscriptionId, 1e19);

        vm.stopBroadcast();
    }
}
