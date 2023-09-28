// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../../payloads/interfaces/IPayloadsControllerCore.sol';

/**
 * @title IPayloadsControllerDataHelper
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsControllerDataHelper contract
 */
interface IPayloadsControllerDataHelper {
  /**
   * @notice Object storing the payload data along with its id
   * @param id identifier of the payload
   * @param payloadData payload body
   */
  struct Payload {
    uint256 id;
    IPayloadsController.Payload data;
  }

  /**
   * @notice Object storing the config of the executor
   * @param accessLevel access level
   * @param config executor config
   */
  struct ExecutorConfig {
    PayloadsControllerUtils.AccessControl accessLevel;
    IPayloadsControllerCore.ExecutorConfig config;
  }

  /**
   * @notice method to get proposals list
   * @param payloadsController instance of the payloads controller
   * @param payloadsIds list of the ids of payloads to get
   * @return list of the payloads
   */
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory);

  /**
   * @notice method to get executor configs for certain accessLevels
   * @param payloadsController instance of the payloads controller
   * @param accessLevels list of the accessLevels for which configs should be returned
   * @return list of the executor configs
   */
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory);
}
