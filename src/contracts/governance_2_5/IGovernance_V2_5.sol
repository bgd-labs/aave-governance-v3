// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';

interface IGovernance_V2_5 {
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
   * @notice method to get the name of the contract
   * @return name string
   */
  function NAME() external view returns (string memory);

  /**
   * @notice method to send a payload to execution chain
   * @param payload object with the information needed for execution
   */
  function forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload
  ) external;

  /**
   * @notice method to initialize governance v2.5
   * @param owner address of the new owner of governance
   */
  function initialize(address owner) external;

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
