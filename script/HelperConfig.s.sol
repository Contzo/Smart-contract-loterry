// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {DeployVRFMockCooridnator} from "./DeployVRFMockCooridnator.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {IVRFSubscriptionV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFSubscriptionV2Plus.sol";

contract HelperConfig is Script {
    /**Types Declaration */
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
    }
    /**Immutable variables */
    NetworkConfig public i_activeNetworkConfig;

    /**Constructor */
    constructor() {
        i_activeNetworkConfig = getMainNetworkConfig();
    }

    /**Internal and pure functions */
    function getMainNetworkConfig()
        internal
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                vrfCoordinator: 0xAE975071Be8F8eE67addBC1A82488F1C24858067,
                keyHash: 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93, // 200 gwei
                subscriptionId: 0
            });
    }

    function getSepoliaConfig() internal view returns (NetworkConfig memory) {
        if (i_activeNetworkConfig.vrfCoordinator != address(0)) {
            return i_activeNetworkConfig;
        }

        IVRFSubscriptionV2Plus vrfCoordinator = IVRFSubscriptionV2Plus(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        );
        vm.startBroadcast();
        uint256 subscriptionId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        
        return(
            NetworkConfig{
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: subscriptionId
        });
    }

    function getOrCreateAnvilConfig() internal returns (NetworkConfig memory) {
        if (i_activeNetworkConfig.vrfCoordinator != address(0)) {
            return i_activeNetworkConfig;
        }
        DeployVRFMockCooridnator deployVRFMock = new DeployVRFMockCooridnator();
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = deployVRFMock.run(
            0.25 ether,
            1e9,
            1e18
        );
        uint256 subscriptionId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        return
            NetworkConfig({
                vrfCoordinator: address(vrfCoordinator),
                keyHash: bytes32(0),
                subscriptionId
            });
    }

    function fundSubscrition(uint256 amount) external {}
}
