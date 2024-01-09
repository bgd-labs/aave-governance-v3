// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BridgingHelper {
  /**
   * @notice enum containing the different type of messages that can be bridged
   * @param Null empty state
   * @param Proposal_Vote indicates that the message is to bridge a proposal configuration
   * @param Vote_Results indicates that the message is to bridge the results of a vote on a proposal
   * @param Payload_Execution indicates that the message is to bridge a payload for execution
   */
  enum MessageType {
    Null,
    Proposal_Vote,
    Vote_Results,
    Payload_Execution
  }
}
