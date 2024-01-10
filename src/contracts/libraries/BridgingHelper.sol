// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';

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

  function decodeMessageWithType(
    bytes memory messageWithType
  ) internal pure returns (BridgingHelper.MessageType, bytes memory) {
    return abi.decode(messageWithType, (BridgingHelper.MessageType, bytes));
  }

  function decodeStartProposalVoteMessage(
    bytes memory message
  ) internal pure returns (uint256, bytes32, uint24) {
    return abi.decode(message, (uint256, bytes32, uint24));
  }

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

  function decodeVoteResultMessage(
    bytes memory message
  ) internal pure returns (uint256, uint128, uint128) {
    return abi.decode(message, (uint256, uint128, uint128));
  }

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
