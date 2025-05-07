// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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

    function test_DontAllowEntranceWhenRaffleIsCalculating() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}(); // have at least one player enter the raffle, in order to have some players and balance
        vm.warp(block.timestamp + interval + 1); // warp the block timestamp to be greater than the interval
        vm.roll(block.number + 1); // roll the block number to be greater than the current block number
        //Act/Asssert
        raffle.performUpkeep(""); // call performUpkeep to set the raffle state to calculating
        vm.expectRevert(Raffle.Raffle__NotOpen.selector); // expect the revert
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}(); // try to enter the raffle again
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/
    function test_CheckUpkeepReturnsFalseIfHasNoBalance() external {
        //Arrange
        vm.warp(block.timestamp + interval + 1); // warp the block timestamp to be greater than the interval
        vm.roll(block.number + 1); // roll the block number to be greater than the current block number
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // call checkUpkeep to check if upkeep is needed
        //Assert
        assert(!upkeepNeeded);
    }

    function test_checkUpkeepReturnsFalsIfRaffleIsntOpen() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee + 1 ether}(); // have at least one player enter the raffle, in order to have some players and balance
        vm.warp(block.timestamp + interval + 1); // warp the block timestamp to be greater than the interval
        vm.roll(block.number + 1); // roll the block number to be greater than the current block number
        raffle.performUpkeep(""); // call performUpkeep to set the raffle state to calculating, this should close the raffle
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // call checkUpkeep to check if upkeep is needed
        //Assert
        assert(!upkeepNeeded);
    }

    function test_checkUpkeepRetrunsFalseIfNotEnoughTimePassed() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee + 1 ether}(); // have at least one player enter the raffle, in order to have some players and balance
        vm.warp(block.timestamp + interval - 2); // warp the block timestamp to be less than the interval
        vm.roll(block.number + 1); // roll the block number to be greater than the current block number
        //Acct
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // call checkUpkeep to check if upkeep is needed
        //Assert
        assert(!upkeepNeeded);
    }

    function test_checkUpKeepReturnsTrueIfAllConditionsAreMet() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee + 1 ether}(); // have at least one player enter the raffle, in order to have some players and balance
        vm.warp(block.timestamp + interval + 1); // warp the block timestamp to be greater than the interval
        vm.roll(block.number + 1); // roll the block number to be greater than the current block number
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // call checkUpkeep to check if upkeep is needed
        //Assert
        assert(upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFOMR UPKEEP
    //////////////////////////////////////////////////////////////*/
    function test_checkPerformUpkeepRevertsIfNotEnoughTimeHasPassed() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + interval - 1);

        //Acct/assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                entranceFee, // contract balance = 1 entrant × entranceFee
                1, // one player entered
                Raffle.RaffleState.OPEN // raffle state is OPEN
            )
        );
        vm.prank(player);
        raffle.performUpkeep("");
    }

    function test_checkPerformUpkeepRevertsIfNoPlayerAndBalance() external {
        //Arrange
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + interval + 1);

        //Acct/assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                address(raffle).balance, // contract balance = 0
                0, // no players entered
                Raffle.RaffleState.OPEN // raffle state is OPEN
            )
        );
        vm.prank(player);
        raffle.performUpkeep("");
    }

    function test_chekcIfPerformUpkeepRevertsIfRaffleIsNotOpen() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Acct/assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                address(raffle).balance, // contract balance = 1 entrant × entranceFee
                1, // one player entered
                uint256(Raffle.RaffleState.CALCULATING) // raffle state is CALCULATING
            )
        );
        vm.prank(player);
        raffle.performUpkeep("");
    }

    function test_checkPerformUpkeepChangesRaffleState() external {
        //Arrange
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        raffle.performUpkeep("");

        //Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    modifier raffleEntered() {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_PerformUpkeepEmitsRequestEvent() external raffleEntered {
        //Arrange

        //Act
        vm.recordLogs(); // record the logs of the next transaction
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // store the logs into an an array of Log strcutures
        bytes32 requestId = entries[1].topics[1];

        //assert
        assert(uint256(requestId) > 0);
    }

    /*//////////////////////////////////////////////////////////////
                          FULFILL RANDOM WORDS
    //////////////////////////////////////////////////////////////*/
    function test_FulfillRandomWordsCanBecCalledOnlyAfterPerformUpkeep(
        uint256 randomRequestId
    ) external raffleEntered {
        //Arrange already done by modifier
        // Act and Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function test_FulfillRandomWordsPicksWinnerResetsAndSendsMoney()
        external
        raffleEntered
    {
        //Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTimestamp = raffle.getLastTimeStamp(); // get the staring timeStamp
        //Act
        vm.recordLogs(); // record the logs of the next transaction
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // store the logs into an an array of Log strcutures
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
    }
}
