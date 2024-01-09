// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from 'aave-delivery-infrastructure/contracts/interfaces/IBaseReceiverPortal.sol';
import {BridgingHelper} from '../contracts/libraries/BridgingHelper.sol';

interface IMessageWithTypeReceiver is IBaseReceiverPortal {
  /**
   * @notice emitted when a cross chain message gets received
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param delivered flag indicating if message has been delivered
   * @param messageType type of the received message
   * @param message bytes containing the necessary information of a user vote
   * @param reason bytes with the revert information
   */
  event MessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    BridgingHelper.MessageType messageType,
    bytes message,
    bytes reason
  );

  /**
   * @notice emitted when a cross chain message does not have the correct type
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param message bytes containing the necessary information of a proposal vote
   * @param reason bytes with the revert information
   */
  event IncorrectTypeMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bytes message,
    bytes reason
  );

  /**
   * @notice method to decode a message from governance chain
   * @param message encoded message with message type
   * @return messageType and governance underlying message
   */
  function decodeMessage(
    bytes memory message
  ) external view returns (BridgingHelper.MessageType, bytes memory);
}
