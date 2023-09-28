// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Rescuable, IRescuable} from 'solidity-utils/contracts/utils/Rescuable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';

import {IPayloadsControllerCore, PayloadsControllerUtils} from './interfaces/IPayloadsControllerCore.sol';
import {IExecutor} from './interfaces/IExecutor.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title PayloadsControllerCore
 * @author BGD Labs
 * @notice this contract contains the logic to create and execute a payload.
 * @dev To execute a created payload, the payload id must be bridged from governance chain.
 * @dev The methods to update the contract configuration are callable only by owner. Owner being the registered
        lvl1 Executor. So to update the PayloadsController configuration, a proposal will need to pass in gov chain and
        be executed by the appropriate executor.
 */
abstract contract PayloadsControllerCore is
  OwnableWithGuardian,
  Rescuable,
  IPayloadsControllerCore,
  Initializable
{
  using SafeCast for uint256;
  using SafeERC20 for IERC20;

  // should be always set with respect to the proposal flow duration
  // for example: voting takes 5 days + 2 days for bridging + 3 days for cooldown + 2 days of safety gap
  // then expirationDelay should be not less then 12 days.
  // As expiration delay of proposal is 30 days, payload needs to be able to live longer as its created before and
  // will be executed after.
  // so nobody should be able to set expiration delay less then that
  uint40 public constant EXPIRATION_DELAY = 35 days;

  /// @inheritdoc IPayloadsControllerCore
  uint40 public constant GRACE_PERIOD = 7 days;

  uint40 internal _payloadsCount;

  // stores the executor configuration for every lvl of access control
  mapping(PayloadsControllerUtils.AccessControl => ExecutorConfig)
    internal _accessLevelToExecutorConfig;

  mapping(uint40 => Payload) internal _payloads;

  /// @inheritdoc IPayloadsControllerCore
  function MIN_EXECUTION_DELAY() public view virtual returns (uint40) {
    return 1 days;
  }

  /// @inheritdoc IPayloadsControllerCore
  function MAX_EXECUTION_DELAY() public view virtual returns (uint40) {
    return 10 days;
  }

  function initialize(
    address owner,
    address guardian,
    UpdateExecutorInput[] calldata executors
  ) external initializer {
    require(executors.length != 0, Errors.SHOULD_BE_AT_LEAST_ONE_EXECUTOR);

    _updateExecutors(executors);

    _updateGuardian(guardian);
    _transferOwnership(owner);
  }

  /// @inheritdoc IPayloadsControllerCore
  function createPayload(
    ExecutionAction[] calldata actions
  ) external returns (uint40) {
    require(actions.length != 0, Errors.INVALID_EMPTY_TARGETS);

    uint40 payloadId = _payloadsCount++;
    uint40 creationTime = uint40(block.timestamp);
    Payload storage newPayload = _payloads[payloadId];
    newPayload.creator = msg.sender;
    newPayload.state = PayloadState.Created;
    newPayload.createdAt = creationTime;
    newPayload.expirationTime = creationTime + EXPIRATION_DELAY;
    newPayload.gracePeriod = GRACE_PERIOD;

    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired;
    for (uint256 i = 0; i < actions.length; i++) {
      require(actions[i].target != address(0), Errors.INVALID_ACTION_TARGET);
      require(
        actions[i].accessLevel >
          PayloadsControllerUtils.AccessControl.Level_null,
        Errors.INVALID_ACTION_ACCESS_LEVEL
      );
      require(
        _accessLevelToExecutorConfig[actions[i].accessLevel].executor !=
          address(0),
        Errors.EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL
      );

      newPayload.actions.push(actions[i]);

      if (actions[i].accessLevel > maximumAccessLevelRequired) {
        maximumAccessLevelRequired = actions[i].accessLevel;
      }
    }
    newPayload.maximumAccessLevelRequired = maximumAccessLevelRequired;
    ExecutorConfig
      memory maxRequiredExecutorConfig = _accessLevelToExecutorConfig[
        maximumAccessLevelRequired
      ];
    newPayload.delay = maxRequiredExecutorConfig.delay;

    emit PayloadCreated(
      payloadId,
      msg.sender,
      actions,
      maximumAccessLevelRequired
    );
    return payloadId;
  }

  /// @inheritdoc IPayloadsControllerCore
  function executePayload(uint40 payloadId) external payable {
    Payload storage payload = _payloads[payloadId];

    require(
      _getPayloadState(payload) == PayloadState.Queued,
      Errors.PAYLOAD_NOT_IN_QUEUED_STATE
    );

    uint256 executionTime = payload.queuedAt + payload.delay;
    require(block.timestamp > executionTime, Errors.TIMELOCK_NOT_FINISHED);

    payload.state = PayloadState.Executed;
    payload.executedAt = uint40(block.timestamp);

    for (uint256 i = 0; i < payload.actions.length; i++) {
      ExecutionAction storage action = payload.actions[i];
      IExecutor executor = IExecutor(
        _accessLevelToExecutorConfig[action.accessLevel].executor
      );

      executor.executeTransaction{value: action.value}(
        action.target,
        action.value,
        action.signature,
        action.callData,
        action.withDelegateCall
      );
    }

    emit PayloadExecuted(payloadId);
  }

  /// @inheritdoc IPayloadsControllerCore
  function cancelPayload(uint40 payloadId) external onlyGuardian {
    Payload storage payload = _payloads[payloadId];

    PayloadState payloadState = _getPayloadState(payload);
    require(
      payloadState < PayloadState.Executed &&
        payloadState >= PayloadState.Created,
      Errors.PAYLOAD_NOT_IN_THE_CORRECT_STATE
    );
    payload.state = PayloadState.Cancelled;
    payload.cancelledAt = uint40(block.timestamp);

    emit PayloadCancelled(payloadId);
  }

  /// @inheritdoc IPayloadsControllerCore
  function updateExecutors(
    UpdateExecutorInput[] calldata executors
  ) external onlyOwner {
    _updateExecutors(executors);
  }

  /// @inheritdoc IPayloadsControllerCore
  function getPayloadById(
    uint40 payloadId
  ) external view returns (Payload memory) {
    Payload memory payload = _payloads[payloadId];
    payload.state = _getPayloadState(payload);
    return payload;
  }

  /// @inheritdoc IPayloadsControllerCore
  function getPayloadState(
    uint40 payloadId
  ) external view returns (PayloadState) {
    return _getPayloadState(_payloads[payloadId]);
  }

  /// @inheritdoc IPayloadsControllerCore
  function getPayloadsCount() external view returns (uint40) {
    return _payloadsCount;
  }

  /// @inheritdoc IPayloadsControllerCore
  function getExecutorSettingsByAccessControl(
    PayloadsControllerUtils.AccessControl accessControl
  ) external view returns (ExecutorConfig memory) {
    return _accessLevelToExecutorConfig[accessControl];
  }

  /// @inheritdoc IRescuable
  function whoCanRescue()
    public
    view
    override(IRescuable, Rescuable)
    returns (address)
  {
    return owner();
  }

  receive() external payable {}

  /**
   * @notice method to get the current state of a payload
   * @param payload object with all pertinent payload information
   * @return current state of the payload
   */
  function _getPayloadState(
    Payload memory payload
  ) internal view returns (PayloadState) {
    PayloadState state = payload.state;
    if (state == PayloadState.None || state >= PayloadState.Executed) {
      return state;
    }

    if (
      (state == PayloadState.Created &&
        block.timestamp >= payload.expirationTime) ||
      (state == PayloadState.Queued &&
        block.timestamp >=
        payload.queuedAt + payload.delay + payload.gracePeriod)
    ) {
      return PayloadState.Expired;
    }

    return state;
  }

  /**
   * @notice method to queue a payload
   * @param payloadId id of the payload that needs to be queued
   * @param accessLevel access level used for the proposal voting
   * @param proposalVoteActivationTimestamp proposal vote activation timestamp in seconds
   * @dev this method will be called when a payload is bridged from governance chain
   */
  function _queuePayload(
    uint40 payloadId,
    PayloadsControllerUtils.AccessControl accessLevel,
    uint40 proposalVoteActivationTimestamp
  ) internal {
    Payload storage payload = _payloads[payloadId];
    require(
      _getPayloadState(payload) == PayloadState.Created,
      Errors.PAYLOAD_NOT_IN_CREATED_STATE
    );

    // by allowing >= it enables the proposal to use a higher level of voting configuration
    // than the one set by the payload actions
    require(
      accessLevel >= payload.maximumAccessLevelRequired,
      Errors.INVALID_PROPOSAL_ACCESS_LEVEL
    );
    // this checks that the payload has been created before the proposal vote started.
    // this ensures that the voters where able to check the content of the payload they voted on
    require(
      proposalVoteActivationTimestamp > payload.createdAt,
      Errors.PAYLOAD_NOT_CREATED_BEFORE_PROPOSAL
    );

    payload.state = PayloadState.Queued;
    payload.queuedAt = uint40(block.timestamp);

    emit PayloadQueued(payloadId);
  }

  /**
   * @notice add new executor configs
   * @param executors array of UpdateExecutorInput with needed executor configurations
   */
  function _updateExecutors(UpdateExecutorInput[] memory executors) internal {
    for (uint256 i = 0; i < executors.length; i++) {
      UpdateExecutorInput memory newExecutorConfig = executors[i];

      require(
        newExecutorConfig.executorConfig.executor != address(0),
        Errors.INVALID_EXECUTOR_ADDRESS
      );

      require(
        newExecutorConfig.accessLevel >
          PayloadsControllerUtils.AccessControl.Level_null,
        Errors.INVALID_EXECUTOR_ACCESS_LEVEL
      );

      require(
        newExecutorConfig.executorConfig.delay >= MIN_EXECUTION_DELAY() &&
          newExecutorConfig.executorConfig.delay <= MAX_EXECUTION_DELAY(),
        Errors.INVALID_EXECUTOR_DELAY
      );

      // check that the new executor is not already being used in a different level
      PayloadsControllerUtils.AccessControl levelToCheck = newExecutorConfig
        .accessLevel == PayloadsControllerUtils.AccessControl.Level_1
        ? PayloadsControllerUtils.AccessControl.Level_2
        : PayloadsControllerUtils.AccessControl.Level_1;
      require(
        _accessLevelToExecutorConfig[levelToCheck].executor !=
          newExecutorConfig.executorConfig.executor,
        Errors.EXECUTOR_ALREADY_SET_IN_DIFFERENT_LEVEL
      );

      _accessLevelToExecutorConfig[
        newExecutorConfig.accessLevel
      ] = newExecutorConfig.executorConfig;

      emit ExecutorSet(
        newExecutorConfig.accessLevel,
        newExecutorConfig.executorConfig.executor,
        newExecutorConfig.executorConfig.delay
      );
    }
  }
}
