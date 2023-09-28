// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from 'aave-delivery-infrastructure/contracts/interfaces/IBaseReceiverPortal.sol';
import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';
import {PayloadsControllerUtils} from '../PayloadsControllerUtils.sol';

/**
 * @title IPayloadsController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsController contract
 */
interface IPayloadsController is IBaseReceiverPortal, IPayloadsControllerCore {
  /**
   * @notice get contract address from where the messages come
   * @return address of the message registry
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice get chain id of the message originator network
   * @return chain id of the originator network
   */
  function ORIGIN_CHAIN_ID() external view returns (uint256);

  /**
   * @notice get address of the message sender in originator network
   * @return address of the originator contract
   */
  function MESSAGE_ORIGINATOR() external view returns (address);

  /**
   * @notice method to decode a message from from governance chain
   * @param message encoded message with message type
   * @return payloadId, accessLevel, proposalVoteActivationTimestamp from the decoded message
   */
  function decodeMessage(
    bytes memory message
  )
    external
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40);
}
