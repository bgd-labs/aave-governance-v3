// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';
import {PayloadsControllerUtils} from '../PayloadsControllerUtils.sol';
import {ICrossChainControllerAdapter} from '../../../interfaces/ICrossChainControllerAdapter.sol';

/**
 * @title IPayloadsController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsController contract
 */
interface IPayloadsController is
  ICrossChainControllerAdapter,
  IPayloadsControllerCore
{
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
   * @notice method to decode a message from governance chain
   * @param message encoded message with message type
   * @return payloadId, accessLevel, proposalVoteActivationTimestamp from the decoded message
   */
  function decodePayloadExecutionMessage(
    bytes memory message
  )
    external
    pure
    returns (uint40, PayloadsControllerUtils.AccessControl, uint40);
}
