// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    address player = makeAddr("player");
    uint256 constant STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    event RaffleEntered(address indexed player);
    event PickedWinner(address indexed winner);

    function setUp() external {
        vm.deal(player, STARTING_PLAYER_BALANCE);
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getNetworkConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializesInOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function test_RaffleRevertsWhenNotEnoughETHEntered() external {
        //Arange
        vm.prank(player);
        //Act/Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function test_RaffleRecordsPlayersWhenTheyEnter() external {
        //Arrange
        vm.prank(player);
        console.log("Entrance fee: ", entranceFee);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //assert
        address mostRecentPlayer = raffle.getPlayerAtIndex(0);
        assertEq(mostRecentPlayer, player);
    }

    function test_EnteringRaffleEmitsEvent() external {
        //Arrange
        vm.prank(player);
        //Act/Assert
        vm.expectEmit(true, false, false, false, address(raffle)); // the strcuture of the event we want to check and the address of the contract that emits it
        emit RaffleEntered(player); // we let the test know what event we expect to be emitted by emiting it, I know it is weird
        raffle.enterRaffle{value: entranceFee}();
    }
}
