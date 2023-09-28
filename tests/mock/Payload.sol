// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

contract CrossChainTestPayload {
  event CrossChainTestPayloadExecuted(string text);

  function execute() external {
    emit CrossChainTestPayloadExecuted('Test execution');
  }
}
