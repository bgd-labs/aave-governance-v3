// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from "./IPayloadsControllerCore.sol";
import {IWithPayloadsManager} from "./IWithPayloadsManager.sol";
import {PayloadsControllerUtils} from "../PayloadsControllerUtils.sol";

/**
 * @title IPermissionedPayloadsController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the IPermissionedPayloadsController contract
 */
interface IPermissionedPayloadsController is IPayloadsControllerCore, IWithPayloadsManager {
  /**
   * @notice method to initialize the contract with starter params. Only callable by proxy
   * @param owner address of the owner. With permission to change the delay and rescue
   * @param guardian address of the guardian. With permission to cancel payloads
   * @param initialPayloadsManager address of the initial payload manager. With permission to create payloads
   * @param executors array of executor configurations
   */
  function initialize(
    address owner,
    address guardian,
    address initialPayloadsManager,
    UpdateExecutorInput[] calldata executors
  ) external;

  function setExecutionDelay(uint40 delay) external;
}
