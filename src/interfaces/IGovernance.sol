// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerStrategy} from './IGovernancePowerStrategy.sol';
import {IGovernanceCore} from './IGovernanceCore.sol';

/**
 * @title IGovernance
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Governance contract
 */
interface IGovernance {
  /**
   * @notice emitted when gas limit gets updated
   * @param gasLimit the new gas limit
   */
  event GasLimitUpdated(uint256 indexed gasLimit);

  /**
   * @notice method to get the CrossChainController contract address of the currently deployed address
   * @return address of CrossChainController contract
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice method to initialize governance v3 on first deploy
   * @param owner address of the new owner of governance
   * @param guardian address of the new guardian of governance
   * @param powerStrategy address of the governance chain voting strategy
   * @param votingConfigs objects containing the information of different voting configurations depending on access level
   * @param votingPortals objects containing the information of different voting machines depending on chain id
   * @param gasLimit gas needed to send a payload for execution
   * @param cancellationFee fee amount to collateralize against proposal cancellation
   */
  function initialize(
    address owner,
    address guardian,
    IGovernancePowerStrategy powerStrategy,
    IGovernanceCore.SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals,
    uint256 gasLimit,
    uint256 cancellationFee
  ) external;

  /**
   * @notice method to initialize revision 3 of governance v3
   * @param gasLimit updated gas limit needed for payload execution on PayloadsController
   */
  function initializeWithRevision(uint256 gasLimit) external;

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   * @dev this method should have a owner gated permission. But responsibility is relegated to inheritance
   */
  function updateGasLimit(uint256 gasLimit) external;

  /**
   * @notice method to get the gasLimit
   * @return gasLimit the new gas limit
   */
  function getGasLimit() external view returns (uint256);
}
