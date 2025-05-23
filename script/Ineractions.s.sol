// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {IVRFCoordinatorV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script, console, console2} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() public {
        createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;
        address subOwner = helperConfig
            .getNetworkConfig()
            .subscriptionOwnerAccount;

        //create sub
        (uint256 subId, ) = createSubscription(vrfCoordinator, subOwner);
        helperConfig.setSubId(subId, block.chainid); //
        return (subId, vrfCoordinator);
    }

    function createSubscription(
        address _vrfCoordinator,
        address _subOwner
    ) public returns (uint256, address) {
        console.log("Creating subscription... on chianId: ", block.chainid);
        vm.startBroadcast(_subOwner);
        uint256 subId = IVRFCoordinatorV2Plus(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID: ", subId);
        console.log(
            "Please update the subscription ID in the HelperConfig contract"
        );
        return (subId, _vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;
        uint256 subId = helperConfig.getNetworkConfig().subscriptionId;
        address link = helperConfig.getNetworkConfig().linkToken;
        address subOwner = helperConfig
            .getNetworkConfig()
            .subscriptionOwnerAccount;
        fundSubscription(vrfCoordinator, subOwner, subId, link);
    }

    function fundSubscription(
        address _vrfCoordinator,
        address _subOwner,
        uint256 _subId,
        address _link
    ) public {
        console.log("Funding subscription: ", _subId);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On chainId: ", block.chainid);
        // The mock function has a simple fund subscription function
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(_subOwner);
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(_subOwner);
            LinkToken(_link).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        // get the most recent deployed contract
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentDeployed);
    }

    function addConsumerUsingConfig(address _mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getNetworkConfig().vrfCoordinator;
        uint256 subId = helperConfig.getNetworkConfig().subscriptionId;
        address subOwner = helperConfig
            .getNetworkConfig()
            .subscriptionOwnerAccount;
        addConsumer(_mostRecentlyDeployed, vrfCoordinator, subId, subOwner);
    }

    function addConsumer(
        address _contractToAddToVRF,
        address _vrfCoordinator,
        uint256 _subId,
        address _subOwner
    ) public {
        console.log("Adding consumer contract: ", _contractToAddToVRF);
        console.log("To VRF coordinator: ", _vrfCoordinator);
        console2.log("On chainId: ", block.chainid);

        vm.startBroadcast(_subOwner);
        IVRFCoordinatorV2Plus(_vrfCoordinator).addConsumer(
            _subId,
            _contractToAddToVRF
        );
        vm.stopBroadcast();
    }
}
