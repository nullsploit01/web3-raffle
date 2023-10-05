// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol';

error Raffle__NotEnoughEth();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 balance, uint256 participants);

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
  enum RaffleState {
    OPEN,
    CALCULATING
  }

  uint256 private immutable i_ticketPrice;
  address payable[] private s_participants;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint32 private immutable i_gasLimit;
  uint32 private constant NUM_WORDS = 1;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;

  address private s_recentWinner;
  RaffleState private s_raffleState;
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  event Enter(address indexed participant);
  event WinnerPicked(uint256 requestId);
  event AllWinnersPicked(address winner);

  constructor(
    address vrfCoordinatorV2,
    uint256 ticketPrice,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_ticketPrice = ticketPrice;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_gasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval;
  }

  function enter() public payable {
    if (msg.value < i_ticketPrice) {
      revert Raffle__NotEnoughEth();
    }

    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__NotOpen();
    }

    s_participants.push(payable(msg.sender));

    emit Enter(msg.sender);
  }

  function fulfillRandomWords(
    uint256 /*requestId */,
    uint256[] memory randomWords
  ) internal override {
    uint256 winnerIndex = randomWords[0] % s_participants.length;
    address payable winner = s_participants[winnerIndex];

    s_recentWinner = winner;
    s_raffleState = RaffleState.OPEN;
    s_participants = new address payable[](0);
    s_lastTimeStamp = block.timestamp;

    //send money
    (bool success, ) = winner.call{value: address(this).balance}('');

    if (!success) {
      revert Raffle__TransferFailed();
    }

    emit AllWinnersPicked(winner);
  }

  function checkUpkeep(
    bytes memory /* checkData */
  ) public override returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool isOpen = RaffleState.OPEN == s_raffleState;
    bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
    bool hasPlayers = s_participants.length > 0;
    bool hasBalance = address(this).balance > 0;

    upkeepNeeded = isOpen && timePassed && hasPlayers && hasBalance;
  }

  function performUpkeep(bytes calldata /* performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep('');

    if (!upkeepNeeded) {
      revert Raffle__UpkeepNotNeeded(address(this).balance, s_participants.length);
    }

    s_raffleState = RaffleState.CALCULATING;

    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_gasLimit,
      NUM_WORDS
    );

    emit WinnerPicked(requestId);
  }

  function getTicketPrice() public view returns (uint256) {
    return i_ticketPrice;
  }

  function getParticipant(uint256 index) public view returns (address) {
    return s_participants[index];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  function getNumWords() public pure returns (uint32) {
    return NUM_WORDS;
  }

  function getNumParticipants() public view returns (uint256) {
    return s_participants.length;
  }

  function getLatestTimestamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns (uint16) {
    return REQUEST_CONFIRMATIONS;
  }
}
