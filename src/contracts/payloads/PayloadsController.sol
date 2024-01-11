// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {PayloadsControllerCore, PayloadsControllerUtils} from './PayloadsControllerCore.sol';
import {IPayloadsController} from './interfaces/IPayloadsController.sol';
import {Errors} from '../libraries/Errors.sol';
import {BridgingHelper, MessageWithTypeReceiver} from '../MessageWithTypeReceiver.sol';

/**
 * @title PayloadsController
 * @author BGD Labs
 * @notice Contract with the logic to manage receiving cross chain messages. This contract knows how to receive and
           decode messages from CrossChainController
 */
contract PayloadsController is
  PayloadsControllerCore,
  MessageWithTypeReceiver,
  IPayloadsController
{
  /// @inheritdoc IPayloadsController
  address public immutable MESSAGE_ORIGINATOR;

  /// @inheritdoc IPayloadsController
  address public immutable CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IPayloadsController
  uint256 public immutable ORIGIN_CHAIN_ID;

  /**
   * @param crossChainController address of the CrossChainController contract deployed on current chain. This contract
            is the one responsible to send here the voting configurations once they are bridged.
   * @param messageOriginator address of the contract where the message originates (mainnet governance)
   * @param originChainId the id of the network where the messages originate from
   */
  constructor(
    address crossChainController,
    address messageOriginator,
    uint256 originChainId
  ) {
    require(
      crossChainController != address(0),
      Errors.INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS
    );
    require(
      messageOriginator != address(0),
      Errors.INVALID_MESSAGE_ORIGINATOR_ADDRESS
    );
    require(originChainId > 0, Errors.INVALID_ORIGIN_CHAIN_ID);

    CROSS_CHAIN_CONTROLLER = crossChainController;
    MESSAGE_ORIGINATOR = messageOriginator;
    ORIGIN_CHAIN_ID = originChainId;
  }

  /// @inheritdoc IPayloadsController
  function decodePayloadExecutionMessage(
    bytes memory message
  )
    external
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40)
  {
    return BridgingHelper.decodePayloadExecutionMessage(message);
  }

  function _checkOrigin(
    address caller,
    address originSender,
    uint256 originChainId
  ) internal view override returns (bool) {
    return
      caller == CROSS_CHAIN_CONTROLLER &&
      originSender == MESSAGE_ORIGINATOR &&
      originChainId == ORIGIN_CHAIN_ID;
  }

  /// @dev queues the payload id
  function _parseReceivedMessage(
    address originSender,
    uint256 originChainId,
    BridgingHelper.MessageType messageType,
    bytes memory message
  ) internal override {
    bytes memory empty;
    if (messageType == BridgingHelper.MessageType.Payload_Execution) {
      try this.decodePayloadExecutionMessage(message) returns (
        uint40 payloadId,
        PayloadsControllerUtils.AccessControl accessLevel,
        uint40 proposalVoteActivationTimestamp
      ) {
        _queuePayload(payloadId, accessLevel, proposalVoteActivationTimestamp);
        emit MessageReceived(
          originSender,
          originChainId,
          true,
          messageType,
          message,
          empty
        );
      } catch (bytes memory decodingError) {
        emit MessageReceived(
          originSender,
          originChainId,
          false,
          messageType,
          message,
          decodingError
        );
      }
    } else {
      emit IncorrectTypeMessageReceived(
        originSender,
        originChainId,
        message,
        abi.encodePacked('unsupported message type: ', messageType)
      );
    }
  }
}
