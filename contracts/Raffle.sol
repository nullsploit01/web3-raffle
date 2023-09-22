// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';

error Raffle__NotEnoughEth();

contract Raffle is VRFConsumerBaseV2 {
  uint256 private immutable i_ticketPrice;
  address payable[] private s_participants;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable i_gasLimit;
  uint32 private constant NUM_WORDS = 1;

  event Enter(address indexed participant);
  event WinnerPicked(uint256 requestId);

  constructor(
    address vrfCoordinatorV2,
    uint256 ticketPrice,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_ticketPrice = ticketPrice;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_gasLimit = callbackGasLimit;
  }

  function enter() public payable {
    if (msg.value < i_ticketPrice) {
      revert Raffle__NotEnoughEth();
    }
    s_participants.push(payable(msg.sender));

    emit Enter(msg.sender);
  }

  function pickWinner() external {
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_gasLimit,
      NUM_WORDS
    );

    emit WinnerPicked(requestId);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}

  function getTicketPrice() public view returns (uint256) {
    return i_ticketPrice;
  }

  function getParticipant(uint256 index) public view returns (address) {
    return s_participants[index];
  }
}
