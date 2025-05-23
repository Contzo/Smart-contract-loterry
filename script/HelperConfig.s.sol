// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /**VRF mock values */
    uint96 public constant BASE_FEE = 0.25 ether; //0.25 LINK per request
    uint96 public constant GAS_PRICE_LINK = 1e9; //1 GWEI LINK per gas
    int256 public constant WEI_PER_UNIT_LINK = 1e18; //1 LINK = 1e18 wei

    uint256 public constant ETH_SEPOLIA_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChianId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        address subscriptionOwnerAccount;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chianId => NetworkConfig networkConfig)
        public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_ID] = getSepoliaConfig();
    }

    function getConfigByChianId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChianId();
        }
    }

    function getNetworkConfig() public returns (NetworkConfig memory) {
        return getConfigByChianId(block.chainid);
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, //30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 100000,
                subscriptionId: 18500869138955725108857677099332487437398769831833209741250157808138339028342,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                subscriptionOwnerAccount: 0xEcA5e7FaDF270376Af5e6f9bD06124BdE90b58d3
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE_LINK,
            WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken(); // deploy link token mock
        vm.stopBroadcast();
        networkConfigs[LOCAL_CHAIN_ID] = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //30 seconds
            vrfCoordinator: address(vrfCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 100000,
            subscriptionId: 0,
            linkToken: address(linkToken),
            subscriptionOwnerAccount: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return networkConfigs[LOCAL_CHAIN_ID];
    }

    function setSubId(uint256 subId, uint256 chainId) public {
        networkConfigs[chainId].subscriptionId = subId;
    }
}
