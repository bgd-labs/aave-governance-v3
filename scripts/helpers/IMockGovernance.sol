// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IMockGovernance
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Mock Governance contract
 */
interface IMockGovernance {
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

  /**
   * @notice method to allow a list of addresses
   */
  function allowAddresses(address[] memory addressesToAllow) external;

  /**
   * @notice method to remove a list of addresses from the allowed list
   */
  function disallowAddresses(address[] memory addressesToDisallow) external;

  /**
   * @notice method to get the allowed addresses
   */
  function getAllowedAddresses() external view returns (bytes32[] memory);
}
