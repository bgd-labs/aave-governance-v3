// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BridgingHelper, IMessageWithTypeReceiver, IBaseReceiverPortal} from '../interfaces/IMessageWithTypeReceiver.sol';

/**
 * @title MessageWithTypeReceiver
 * @author BGD Labs
 * @notice Abstract contract implementing the base method to receive messages from the CrossChainController.
 * @dev Contracts that inherit from here, must implement the _checkOrigin and _parseReceivedMessage to be able to
        work with the bridged message
 */
abstract contract MessageWithTypeReceiver is IMessageWithTypeReceiver {
  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
    _checkOrigin(msg.sender, originSender, originChainId);

    try this.decodeMessageWithType(messageWithType) returns (
      BridgingHelper.MessageType messageType,
      bytes memory message
    ) {
      _parseReceivedMessage(originSender, originChainId, messageType, message);
    } catch (bytes memory decodingError) {
      emit IncorrectTypeMessageReceived(
        originSender,
        originChainId,
        messageWithType,
        decodingError
      );
    }
  }

  /// @inheritdoc IMessageWithTypeReceiver
  function decodeMessageWithType(
    bytes memory message
  ) external pure returns (BridgingHelper.MessageType, bytes memory) {
    return BridgingHelper.decodeMessageWithType(message);
  }

  /**
   * @notice method that implements necessary checks to validate the origin of the bridged message
   * @param caller address that is calling this method
   * @param originSender address where the message originated
   * @param originChainId id of the chain where the message originated
   */
  function _checkOrigin(
    address caller,
    address originSender,
    uint256 originChainId
  ) internal view virtual;

  /**
   * @notice method that implements the logic to work with the bridged message of expected type
   * @param originSender address where the message originated
   * @param originChainId id of the chain where the message originated
   * @param messageType type of the bridged message
   * @param message bridged data
   */
  function _parseReceivedMessage(
    address originSender,
    uint256 originChainId,
    BridgingHelper.MessageType messageType,
    bytes memory message
  ) internal virtual;
}
