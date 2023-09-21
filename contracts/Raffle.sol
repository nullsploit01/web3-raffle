// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

error Raffle__NotEnoughEth();

contract Raffle {
  uint256 private immutable i_ticketPrice;
  address payable[] private s_participants;

  constructor(uint256 ticketPrice) {
    i_ticketPrice = ticketPrice;
  }

  function enter() public payable {
    if (msg.value < i_ticketPrice) {
      revert Raffle__NotEnoughEth();
    }
    s_participants.push(payable(msg.sender));
  }

  function getTicketPrice() public view returns (uint256) {
    return i_ticketPrice;
  }

  function getParticipant(uint256 index) public view returns (address) {
    return s_participants[index];
  }
}
