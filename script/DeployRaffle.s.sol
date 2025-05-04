// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle) {
        (raffle, ) = deployContract();
    }

    function deployContract()
        public
        returns (Raffle raffle, HelperConfig activeNetworkConfig)
    {
        HelperConfig helperConfig = new HelperConfig();
        // for local network deploy a mock and get local config
        // sepolia gets the sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig
            .getNetworkConfig();
        vm.startBroadcast();
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
