// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract HelperConfig is Script {
    /**Types Declaration */
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        address linkToken;
    }
    /**Immutable variables */
    NetworkConfig public i_activeNetworkConfig;

    /**Constructor */
    constructor() {
        console.log(block.chainid);
        if (block.chainid == 1) {
            // need to manually provide VRF coordinator address, keyhash and subscriptionId becauuse
            // only EOA accnount can create VRF subscriptions
            // i_activeNetworkConfig = getOrCreateMainNetworkConfigSubscription();
        } else if (block.chainid == 11155111) {
            i_activeNetworkConfig = NetworkConfig({
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 18500869138955725108857677099332487437398769831833209741250157808138339028342,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
        } else {
            i_activeNetworkConfig = getOrCreateAnvilSubscription();
        }
    }

    function getOrCreateAnvilSubscription()
        internal
        returns (NetworkConfig memory)
    {
        if (i_activeNetworkConfig.vrfCoordinator != address(0)) {
            return i_activeNetworkConfig;
        }
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            0.25 ether,
            1e9,
            1e18
        );
        uint256 subscriptionId = vrfCoordinator.createSubscription();
        console.log(
            "Subscription ID: ",
            subscriptionId,
            "VRF Coordinator: ",
            address(vrfCoordinator)
        );
        return
            NetworkConfig({
                vrfCoordinator: address(vrfCoordinator),
                keyHash: bytes32(0),
                subscriptionId: subscriptionId,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function fundSubscrition(uint256 amountInJules) external {
        if (i_activeNetworkConfig.subscriptionId == 0) {
            revert("Subscription ID is not set");
        }
        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock(i_activeNetworkConfig.vrfCoordinator)
                .fundSubscription(
                    i_activeNetworkConfig.subscriptionId,
                    amountInJules
                );
        } else {
            LinkTokenInterface(i_activeNetworkConfig.linkToken).transferAndCall(
                    i_activeNetworkConfig.vrfCoordinator,
                    amountInJules,
                    abi.encode(uint64(i_activeNetworkConfig.subscriptionId))
                );
            console.log(
                "Funded subscription with: ",
                amountInJules,
                " LINK tokens"
            );
        }
    }

    function addConsumer(address consumer) external {
        if (i_activeNetworkConfig.subscriptionId == 0) {
            revert("Subscription ID is not set");
        }
        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock(i_activeNetworkConfig.vrfCoordinator)
                .addConsumer(i_activeNetworkConfig.subscriptionId, consumer);
        } else {
            VRFCoordinatorV2Interface(i_activeNetworkConfig.vrfCoordinator)
                .addConsumer(
                    uint64(i_activeNetworkConfig.subscriptionId),
                    consumer
                );
        }
    }
}
