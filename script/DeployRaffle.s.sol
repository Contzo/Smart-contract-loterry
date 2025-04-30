// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run(address vrfCoordinator, bytes32 keyHash) external {
        uint256 entranceFee = 0.01 ether;
        uint256 interval = 30;
        uint256 subscriptionId = 18500869138955725108857677099332487437398769831833209741250157808138339028342;
        uint32 callbackGasLimit = 100000;

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
    }
}
