// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BridgingHelper, IMessageWithTypeReceiver, IBaseReceiverPortal} from '../interfaces/IMessageWithTypeReceiver.sol';

abstract contract MessageWithTypeReceiver is IMessageWithTypeReceiver {
  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType // TODO: not sure if i can change the name here when interface is different
  ) external {
    _checkOrigin(msg.sender, originSender, originChainId);

    try this.decodeMessage(messageWithType) returns (
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
  function decodeMessage(
    bytes memory message
  ) external pure returns (BridgingHelper.MessageType, bytes memory) {
    return abi.decode(message, (BridgingHelper.MessageType, bytes));
  }

  function _checkOrigin(
    address caller,
    address originSender,
    uint256 originChainId
  ) internal view virtual;

  function _parseReceivedMessage(
    address originSender,
    uint256 originChainId,
    BridgingHelper.MessageType messageType,
    bytes memory message
  ) internal virtual;
}
