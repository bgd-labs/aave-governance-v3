// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPayloadsControllerCore} from './interfaces/IPayloadsControllerCore.sol';
import {PayloadsControllerCore} from './PayloadsControllerCore.sol';
import {PayloadsControllerUtils} from './PayloadsControllerUtils.sol';
import {WithPayloadsManager} from './WithPayloadsManager.sol';
import {IPermissionedPayloadsController} from './interfaces/IPermissionedPayloadsController.sol';

contract PermissionedPayloadsController is
  PayloadsControllerCore,
  WithPayloadsManager,
  IPermissionedPayloadsController
{
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
    returns (uint40)
  {
    return super.createPayload(actions);
  }

  function initialize(
    address owner,
    address guardian,
    address initialPayloadsManager,
    UpdateExecutorInput[] calldata executors
  ) external {
    initialize(owner, guardian, executors);
    _updatePayloadsManager(initialPayloadsManager);
  }

  function queuePayload(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel
  ) external onlyPayloadsManager {
    _queuePayload(payloadId, accessLevel, type(uint40).max);
  }
}
