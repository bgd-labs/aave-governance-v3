// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from "./IPayloadsControllerCore.sol";
import {IWithPayloadsManager} from "./IWithPayloadsManager.sol";
import {PayloadsControllerUtils} from "../PayloadsControllerUtils.sol";

interface IPermissionedPayloadsController is IPayloadsControllerCore, IWithPayloadsManager {  
  /**
   * @notice method to initialize the contract with starter params. Only callable by proxy
   * @param owner address of the owner of the contract. with permissions to call certain methods
   * @param guardian address of the guardian. With permissions to call certain methods
   * @param executors array of executor configurations
   * @param initialPayloadsManager address of the initial payload manager
   */
  function initialize(
    address owner,
    address guardian,
    address initialPayloadsManager,
    UpdateExecutorInput[] calldata executors
  ) external;

  function queuePayload(uint40 payloadId, PayloadsControllerUtils.AccessControl accessLevel) external;
}