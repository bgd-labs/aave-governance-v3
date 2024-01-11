// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainController} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainController.sol';
import {BridgingHelper, ICrossChainControllerAdapter, IBaseReceiverPortal} from '../interfaces/ICrossChainControllerAdapter.sol';
import {Errors} from './libraries/Errors.sol';

/**
 * @title CrossChainControllerAdapter
 * @author BGD Labs
 * @notice Abstract contract implementing the base methods of communication with CrossChainController.
 * @dev Contracts that inherit from here, must implement the _checkOrigin and _parseReceivedMessage to be able to
        work with the bridged message
 */
abstract contract CrossChainControllerAdapter is ICrossChainControllerAdapter {
  /// @inheritdoc ICrossChainControllerAdapter
  address public immutable CROSS_CHAIN_CONTROLLER;

  /**
   * @param crossChainController address of current network message controller (cross chain controller or same chain controller)
   */
  constructor(address crossChainController) {
    require(
      crossChainController != address(0),
      Errors.INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS
    );
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
    require(msg.sender == CROSS_CHAIN_CONTROLLER);

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

  /// @inheritdoc ICrossChainControllerAdapter
  function decodeMessageWithType(
    bytes memory message
  ) external pure returns (BridgingHelper.MessageType, bytes memory) {
    return BridgingHelper.decodeMessageWithType(message);
  }

  /**
   * @notice method to pass a message to aDI for delivery
   * @param destinationChainId id of the chain where the message needs to be delivered
   * @param destination address where the message needs to be delivered
   * @param gasLimit upper limit of the gas used on destination chain to deliver the message
   * @param message bytes to bridge
   */
  function _forwardMessageToCrossChainController(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) internal {
    ICrossChainController(CROSS_CHAIN_CONTROLLER).forwardMessage(
      destinationChainId,
      destination,
      gasLimit,
      message
    );
  }

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
  ) internal virtual {}
}
