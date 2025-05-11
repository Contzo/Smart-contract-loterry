// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract IntegrationsTest is Test, CodeConstants {
    HelperConfig private helperConfig;

    function setUp() external {
        helperConfig = new HelperConfig();
    }

    /*//////////////////////////////////////////////////////////////
                           HELPER CONFIG TESTS
    //////////////////////////////////////////////////////////////*/

    modifier skipLocalChain() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function test_ReturnsExistingSepoliaConfig() external skipLocalChain {
        // Arrange and Act
        address vrfCoordinator = helperConfig
            .getConfigByChianId(block.chainid)
            .vrfCoordinator;
        //Assert ;
        assert(
            vrfCoordinator == helperConfig.getSepoliaConfig().vrfCoordinator
        );
    }

    function test_RevertIfChainIdNotValid() external {
        // Arrange and Act
        vm.expectRevert(HelperConfig.HelperConfig__InvalidChianId.selector);
        helperConfig.getConfigByChianId(100);
    }

    function test_ReturnsExistingLocalNetworkConfig() external {
        //Arrange
        address vrfCoordinator = helperConfig
            .getOrCreateAnvilEthConfig()
            .vrfCoordinator; // create an network config

        //Act
        address newVrfCoordinator = helperConfig
            .getOrCreateAnvilEthConfig()
            .vrfCoordinator;

        //Assert
        assert(vrfCoordinator == newVrfCoordinator);
    }
}
