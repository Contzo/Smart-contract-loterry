// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Ineractions.s.sol";

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
        if (config.subscriptionId == 0) {
            //create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, ) = createSubscription.createSubscription(
                config.vrfCoordinator,
                config.subscriptionOwnerAccount
            );
            //fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionOwnerAccount,
                config.subscriptionId,
                config.linkToken
            );
        }
        vm.startBroadcast(config.subscriptionOwnerAccount);
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        // add the newly created raffle contract as a consumer to the subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.subscriptionOwnerAccount
        );
        return (raffle, helperConfig);
    }
}
