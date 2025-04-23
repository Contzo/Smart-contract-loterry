/**
 * - Inside a sol file contrat elements should be laid like this:
	1. Pragma statements
	2. Import statements
	3. Events
	4. Errors
	5. Interfaces
	6. Libraries
	7. Contracts
- Inside each contract we have this order of declaration:
	1. Type declaration
	2. State variables
	3. Events
	4. Errors
	5. Modifiers
	6. Functions
- Also functions inside a contract should be declared like this:
	1. constructor
	2. receive function (if exists)
	3. fallback function (if exists)
	4. external
	5. public
	6. internal
	7. private
	8. view & pure functions
 */
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle contract
 * @author Ilie Razvan - theGOAT
 * @notice This contract is creating a simple raffle
 * @dev Implements Chianlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**Type declaration */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** State variables */
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**Constants */
    uint32 private constant NUMWORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    //**Immutable and constatns */
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    // @dev The dudration of the lottery in seconds
    uint256 private immutable i_interval;

    /**Events */
    event RaffleEntered(address indexed player);

    /**Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCooridnator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCooridnator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_lastTimeStamp = block.timestamp; // set the last time stamp to the current block timestamp
        s_raffleState = RaffleState.OPEN; // set the raffle state to open
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender)); // update storage
        emit RaffleEntered(msg.sender); // emit and event after storage update
    }

    function pickWinner() external {
        // check to see if enoug time has passed.
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING; // set the raffle state to calculating
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /**Internal functions */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        s_raffleState = RaffleState.OPEN; // set the raffle state to open
    }

    /**Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
