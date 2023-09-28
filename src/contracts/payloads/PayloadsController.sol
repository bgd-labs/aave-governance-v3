// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {PayloadsControllerCore, PayloadsControllerUtils} from './PayloadsControllerCore.sol';
import {IPayloadsController, IBaseReceiverPortal} from './interfaces/IPayloadsController.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title PayloadsController
 * @author BGD Labs
 * @notice Contract with the logic to manage receiving cross chain messages. This contract knows how to receive and
           decode messages from CrossChainController
 */
contract PayloadsController is PayloadsControllerCore, IPayloadsController {
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

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == CROSS_CHAIN_CONTROLLER &&
        originSender == MESSAGE_ORIGINATOR &&
        originChainId == ORIGIN_CHAIN_ID,
      Errors.WRONG_MESSAGE_ORIGIN
    );

    try this.decodeMessage(message) returns (
      uint40 payloadId,
      PayloadsControllerUtils.AccessControl accessLevel,
      uint40 proposalVoteActivationTimestamp
    ) {
      _queuePayload(payloadId, accessLevel, proposalVoteActivationTimestamp);
      bytes memory empty;
      emit PayloadExecutionMessageReceived(
        originSender,
        originChainId,
        true,
        message,
        empty
      );
    } catch (bytes memory decodingError) {
      emit PayloadExecutionMessageReceived(
        originSender,
        originChainId,
        false,
        message,
        decodingError
      );
    }
  }

  /// @inheritdoc IPayloadsController
  function decodeMessage(
    bytes memory message
  )
    external
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40)
  {
    return
      abi.decode(
        message,
        (uint40, PayloadsControllerUtils.AccessControl, uint40)
      );
  }
}
