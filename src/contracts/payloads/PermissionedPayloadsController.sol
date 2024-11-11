// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from './interfaces/IPayloadsControllerCore.sol';
import {PayloadsControllerCore} from './PayloadsControllerCore.sol';
import {PayloadsControllerUtils} from './PayloadsControllerUtils.sol';
import {WithPayloadsManager} from './WithPayloadsManager.sol';
import {IPermissionedPayloadsController} from './interfaces/IPermissionedPayloadsController.sol';

/**
 * @title PermissionedPayloadsController
 * @author BGD Labs
 * @notice this contract contains the logic to execute payloads
 * without governance cycle but leaving the gap to review and cancel payloads.
 * @dev this contract is permissioned, only the payloads manager can create
 * and queue payloads. Also, not only guardian but also the payloads manager can cancel payloads.
 * @dev constants were adjusted as the governance cycle is no longer needed.
 */
contract PermissionedPayloadsController is
  PayloadsControllerCore,
  WithPayloadsManager,
  IPermissionedPayloadsController
{
  function initialize(
    address owner,
    address guardian,
    address initialPayloadsManager,
    UpdateExecutorInput[] calldata executors
  ) external {
    initialize(owner, guardian, executors);
    _updatePayloadsManager(initialPayloadsManager);
  }

  function EXPIRATION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 10 days;
  }

  function GRACE_PERIOD()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 5 days;
  }

  function MIN_EXECUTION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 0;
  }

  function MAX_EXECUTION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 2 days;
  }

  function cancelPayload(
    uint40 payloadId
  )
    external
    override(PayloadsControllerCore, IPayloadsControllerCore)
    onlyPayloadsManagerOrGuardian
  {
    _cancelPayload(payloadId);
  }

  function createPayload(
    ExecutionAction[] calldata actions
  )
    public
    override(PayloadsControllerCore, IPayloadsControllerCore)
    onlyPayloadsManager
    returns (uint40 payloadId)
  {
    payloadId = super.createPayload(actions);
    _queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1, type(uint40).max);
  }
}
