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
  /// @inheritdoc IPermissionedPayloadsController
  function initialize(
    address owner,
    address guardian,
    address initialPayloadsManager,
    UpdateExecutorInput[] calldata executors
  ) external initializer {
    initialize(owner, guardian, executors);
    _updatePayloadsManager(initialPayloadsManager);
  }

  /// @inheritdoc IPayloadsControllerCore
  function EXPIRATION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 10 days;
  }

  /// @inheritdoc IPayloadsControllerCore
  function GRACE_PERIOD()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 5 days;
  }

  /// @inheritdoc IPayloadsControllerCore
  function MIN_EXECUTION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 0;
  }

  /// @inheritdoc IPayloadsControllerCore
  function MAX_EXECUTION_DELAY()
    public
    pure
    override(PayloadsControllerCore, IPayloadsControllerCore)
    returns (uint40)
  {
    return 2 days;
  }

  /// @inheritdoc IPayloadsControllerCore
  function cancelPayload(
    uint40 payloadId
  )
    external
    override(PayloadsControllerCore, IPayloadsControllerCore)
    onlyPayloadsManagerOrGuardian
  {
    _cancelPayload(payloadId);
  }

  /// @inheritdoc IPayloadsControllerCore
  function createPayload(
    ExecutionAction[] calldata actions
  )
    public
    override(PayloadsControllerCore, IPayloadsControllerCore)
    onlyPayloadsManager
    returns (uint40)
  {
    uint40 payloadId = super.createPayload(actions);
    _queuePayload(payloadId, PayloadsControllerUtils.AccessControl.Level_1, type(uint40).max);
    return payloadId;
  }
}
