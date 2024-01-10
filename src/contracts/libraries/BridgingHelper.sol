// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';

/**
 * @title BridgingHelper
 * @author BGD Labs
 * @notice Library with helper methods for the bridging of messages
 */
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

  /**
   * @notice method to decode a bridged message with type
   * @param messageWithType bytes containing a MessageType and a message
   * @return MessageType and the underlying message
   */
  function decodeMessageWithType(
    bytes memory messageWithType
  ) internal pure returns (BridgingHelper.MessageType, bytes memory) {
    return abi.decode(messageWithType, (BridgingHelper.MessageType, bytes));
  }

  /**
   * @notice method to decode an underlying message containing the start proposal vote information
   * @param message bytes containing the information
   * @return proposalId, blockHash and voting duration
   */
  function decodeStartProposalVoteMessage(
    bytes memory message
  ) internal pure returns (uint256, bytes32, uint24) {
    return abi.decode(message, (uint256, bytes32, uint24));
  }

  /**
   * @notice method to decode an underlying message containing the information for payload execution
   * @param message bytes containing the information
   * @return payloadId, accessLevel and proposalVoteActivationTimestamp
   */
  function decodePayloadExecutionMessage(
    bytes memory message
  )
    internal
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40)
  {
    return
      abi.decode(
        message,
        (uint40, PayloadsControllerUtils.AccessControl, uint40)
      );
  }

  /**
   * @notice method to decode an underlying message containing the results of a vote on a proposal
   * @param message bytes containing the information
   * @return proposalId, forVotes and againstVotes
   */
  function decodeVoteResultMessage(
    bytes memory message
  ) internal pure returns (uint256, uint128, uint128) {
    return abi.decode(message, (uint256, uint128, uint128));
  }

  /**
   * @notice method to encode a message for bridging, containing a message type and the necessary information for
             the execution of a payload
   * @param payload information of the payload to be executed
   * @param proposalVoteActivationTimestamp timestamp in seconds indicating the time of vote activation
   * @return bytes containing the encoded messageWithType
   */
  function encodePayloadExecutionMessage(
    PayloadsControllerUtils.Payload memory payload,
    uint40 proposalVoteActivationTimestamp
  ) internal pure returns (bytes memory) {
    bytes memory message = abi.encode(
      payload.payloadId,
      payload.accessLevel,
      proposalVoteActivationTimestamp
    );
    bytes memory messageWithType = abi.encode(
      MessageType.Payload_Execution,
      message
    );

    return messageWithType;
  }

  /**
   * @notice method to encode a message for bridging, containing a message type and the necessary information of
                   the proposal vote results
   * @param proposalId id of the proposal voted on
   * @param forVotes number of votes in favor of the proposal
   * @param againstVotes number of votes against of the proposal
   * @return bytes containing the encoded messageWithType
   */
  function encodeVoteResultsMessage(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal pure returns (bytes memory) {
    bytes memory message = abi.encode(proposalId, forVotes, againstVotes);

    bytes memory messageWithType = abi.encode(
      MessageType.Vote_Results,
      message
    );

    return messageWithType;
  }

  /**
   * @notice method to encode a message for bridging, containing a message type and the necessary information to start
             a vote on a proposal
   * @param proposalId id of the proposal to vote on
   * @param blockHash hash of the block when the vote was activated
   * @param votingDuration duration in seconds of the vote
   * @return bytes containing the encoded messageWithType
   */
  function encodeStartProposalVoteMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) internal pure returns (bytes memory) {
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);

    bytes memory messageWithType = abi.encode(
      MessageType.Proposal_Vote,
      message
    );

    return messageWithType;
  }
}
