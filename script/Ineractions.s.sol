// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {IVRFCoordinatorV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function run() public {
        createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;

        //create sub
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint256, address) {
        console.log("Creating subscription... on chianId: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = IVRFCoordinatorV2Plus(_vrfCoordinator)
            .createSubscription();
        console.log("Subscription ID: ", subId);
        console.log(
            "Please update the subscription ID in the HelperConfig contract"
        );
        vm.stopBroadcast();
        return (subId, _vrfCoordinator);
    }
}
