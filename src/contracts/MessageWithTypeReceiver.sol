// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import 'forge-std/console.sol';
import {BridgingHelper, IMessageWithTypeReceiver, IBaseReceiverPortal} from '../interfaces/IMessageWithTypeReceiver.sol';

abstract contract MessageWithTypeReceiver is IMessageWithTypeReceiver {
  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
    _checkOrigin(msg.sender, originSender, originChainId);

    try this.decodeMessage(messageWithType) returns (
      BridgingHelper.MessageType messageType,
      bytes memory message
    ) {
      _parseReceivedMessage(originSender, originChainId, messageType, message);
    } catch (bytes memory decodingError) {
      console.logBytes(decodingError);
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
    return BridgingHelper.decodeMessageWithType(message);
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
