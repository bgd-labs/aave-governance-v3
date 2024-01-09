// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract MessageWithTypeReceiver is IMessageWithTypeReceiver {
  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
require(
msg.sender == CROSS_CHAIN_CONTROLLER &&
originSender == L1_VOTING_PORTAL &&
originChainId == L1_VOTING_PORTAL_CHAIN_ID,
Errors.WRONG_MESSAGE_ORIGIN
);

try this.decodeMessage(messageWithType) returns (
BridgingHelper.MessageType messageType,
bytes memory message
) {
bytes memory empty;
}
  }
}
