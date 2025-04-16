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

/**
 * @title Raffle contract
 * @author Ilie Razvan - theGOAT
 * @notice This contract is creating a simple raffle
 * @dev Implements Chianlink VRFv2.5
 */
contract Raffle {
    /** State variables */
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    //**Immutable and constatns */
    uint256 private immutable i_entranceFee;
    // @dev The dudration of the lottery in seconds
    uint256 private immutable i_interval;

    /**Events */
    event RaffleEntered(address indexed player);

    /**Errors */
    error Raffle__SendMoreToEnterRaffle();

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp; // set the last time stamp to the current block timestamp
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender)); // update storage
        emit RaffleEntered(msg.sender); // emit and event after storage update
    }

    function pickWinner() external {
        // check to see if enoug time has passed.
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
    }

    /**Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
