// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {GovernanceCore, PayloadsControllerUtils} from './GovernanceCore.sol';
import {IGovernance, IGovernancePowerStrategy, IGovernanceCore} from '../interfaces/IGovernance.sol';
import {Errors} from './libraries/Errors.sol';

/**
 * @title Governance
 * @author BGD Labs
 * @notice this contract contains the logic to communicate with execution chain.
 * @dev This contract implements the abstract contract GovernanceCore
 */
contract Governance is GovernanceCore, IGovernance {
  /// @inheritdoc IGovernance
  address public immutable CROSS_CHAIN_CONTROLLER;

  // gas limit used for sending the vote result
  uint256 private _gasLimit;

  /**
   * @param crossChainController address of current network message controller (cross chain controller or same chain controller)
   * @param coolDownPeriod time that should pass before proposal will be moved to vote, in seconds
   * @param cancellationFeeCollector address of the Aave collector to send cancellation fee
   */
  constructor(
    address crossChainController,
    uint256 coolDownPeriod,
    address cancellationFeeCollector
  ) GovernanceCore(coolDownPeriod, cancellationFeeCollector) {
    require(
      crossChainController != address(0),
      Errors.G_INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS
    );
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  /// @inheritdoc IGovernance
  function initializeWithRevision(uint256 gasLimit) external reinitializer(3) {
    _updateGasLimit(gasLimit);
    IGovernanceCore.SetVotingConfigInput[]
      memory votingConfigs = new IGovernanceCore.SetVotingConfigInput[](2);

    SetVotingConfigInput memory level1Config = SetVotingConfigInput({
      accessLevel: PayloadsControllerUtils.AccessControl.Level_1,
      coolDownBeforeVotingStart: 1 days,
      votingDuration: 3 days,
      yesThreshold: 320_000 ether,
      yesNoDifferential: 80_000 ether,
      minPropositionPower: 80_000 ether
    });
    votingConfigs[0] = level1Config;

    IGovernanceCore.SetVotingConfigInput memory level2Config = IGovernanceCore
      .SetVotingConfigInput({
        accessLevel: PayloadsControllerUtils.AccessControl.Level_2,
        coolDownBeforeVotingStart: 1 days,
        votingDuration: 10 days,
        yesThreshold: 1_040_000 ether,
        yesNoDifferential: 1_040_000 ether,
        minPropositionPower: 200_000 ether
      });
    votingConfigs[1] = level2Config;

    _setVotingConfigs(votingConfigs);
  }

  /// @inheritdoc IGovernance
  function initialize(
    address owner,
    address guardian,
    IGovernancePowerStrategy powerStrategy,
    IGovernanceCore.SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals,
    uint256 gasLimit,
    uint256 cancellationFee
  ) external initializer {
    _initializeCore(
      owner,
      guardian,
      powerStrategy,
      votingConfigs,
      votingPortals,
      cancellationFee
    );
    _updateGasLimit(gasLimit);
  }

  /// @inheritdoc IGovernance
  function getGasLimit() external view returns (uint256) {
    return _gasLimit;
  }

  /// @inheritdoc IGovernance
  function updateGasLimit(uint256 gasLimit) external onlyOwner {
    _updateGasLimit(gasLimit);
  }

  /**
   * @notice method to send a payload to execution chain
   * @param payload object with the information needed for execution
   * @param proposalVoteActivationTimestamp proposal vote activation timestamp in seconds
   */
  function _forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload,
    uint40 proposalVoteActivationTimestamp
  ) internal override {
    ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).forwardMessage(
      payload.chain,
      payload.payloadsController,
      _gasLimit,
      abi.encode(
        payload.payloadId,
        payload.accessLevel,
        proposalVoteActivationTimestamp
      )
    );
  }

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   */
  function _updateGasLimit(uint256 gasLimit) internal {
    _gasLimit = gasLimit;

    emit GasLimitUpdated(gasLimit);
  }
}
