// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

contract DeployRaffleScript is Script {
    function run() external {
        vm.startBroadcast();
        if (block.chainid == 31337) {
            vm.roll(1); // Ensure the block is at least 1
        }
        HelperConfig helperConfig = new HelperConfig(); // Create config after block roll
        (
            address vrfCoordinator,
            bytes32 keyHash,
            uint256 subId,
            address linkToken
        ) = helperConfig.i_activeNetworkConfig();

        // Add some logging to ensure correct state here
        console.log("VRF Coordinator Address: ", vrfCoordinator);
        console.log("Key Hash:");
        console.logBytes32(keyHash);
        console.log("Subscription ID: ", subId);

        Raffle raffle = new Raffle(
            0.1 ether,
            30,
            vrfCoordinator,
            keyHash,
            uint64(subId),
            100000
        );
        console.log(address(raffle));
        if (block.chainid == 1 || block.chainid == 11155111) {
            IVRFCoordinatorV2Plus(vrfCoordinator).addConsumer(
                subId,
                address(raffle)
            );
            LinkTokenInterface(linkToken).transferAndCall(
                vrfCoordinator,
                1e17, // 0.1 LINK
                abi.encode(subId)
            );
        } else {
            helperConfig.addConsumer(address(raffle));
            helperConfig.fundSubscrition(1e17); // Fund the subscription with 0.1 LINK
        }
        vm.stopBroadcast();
        console.log("Raffle deployed to: ", address(raffle));
    }
}
