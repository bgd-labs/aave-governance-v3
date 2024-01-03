// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {PayloadsControllerUtils} from '../../src/contracts/payloads/PayloadsControllerUtils.sol';
import {IMockGovernance} from './IMockGovernance.sol';
import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';

/**
 * @title MockGovernance
 * @author BGD Labs
 * @notice this contract contains the logic to communicate with execution chain.
 * @dev This contract is used for the pre production environment
 */

contract MockGovernance is Ownable, IMockGovernance {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IMockGovernance
  address public immutable CROSS_CHAIN_CONTROLLER;

  // gas limit used for sending the vote result
  uint256 private _gasLimit;

  // list of allowed addresses
  EnumerableSet.AddressSet internal _allowedAddresses;

  modifier onlyAllowedAddress() {
    require(_allowedAddresses.contains(msg.sender), 'ADDRESS_NOT_ALLOWED');
    _;
  }

  /**
   * @param crossChainController address of current network message controller (cross chain controller or same chain controller)
   * @param gasLimit the new gas limit
   * @param owner address that will be the owner of the contract
   * @param addressesToAllow list of addresses to allow
   */
  constructor(
    address crossChainController,
    uint256 gasLimit,
    address owner,
    address[] addressesToAllow
  ) {
    require(
      crossChainController != address(0),
      Errors.G_INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS
    );
    _transferOwnership(owner);
    _updateGasLimit(gasLimit);
    _allowAddresses(addressesToAllow);
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  /// @inheritdoc IMockGovernance
  function getGasLimit() external view returns (uint256) {
    return _gasLimit;
  }

  /// @inheritdoc IMockGovernance
  function updateGasLimit(uint256 gasLimit) external onlyAllowedAddress {
    _updateGasLimit(gasLimit);
  }

  /**
   * @notice method to send a payload to execution chain
   * @param payload object with the information needed for execution
   * @param proposalVoteActivationTimestamp proposal vote activation timestamp in seconds
   */
  function forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload,
    uint40 proposalVoteActivationTimestamp
  ) external onlyAllowedAddress {
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

  /// @inheritdoc IMockGovernance
  function allowAddresses(
    address[] memory addressesToAllow
  ) external onlyOwner {
    _allowAddresses(addressesToAllow);
  }

  /// @inheritdoc IMockGovernance
  function disallowAddresses(
    address[] memory addressesToDisallow
  ) external onlyOwner {
    _disallowAddresses(addressesToDisallow);
  }

  /// @inheritdoc IMockGovernance
  function getAllowedAddresses() external view returns (bytes32[] memory) {
    return _allowedAddresses.values();
  }

  /**
   * @notice method to allow a list of addresses
   */
  function _allowAddresses(address[] memory addressesToAllow) internal {
    for (uint256 i = 0; i < addressesToAllow.length; i++) {
      _allowedAddresses.add(addressesToAllow[i]);
    }
  }

  /**
   * @notice method to remove a list of addresses from the allowed list
   */
  function _disallowAddresses(address[] addressesToDisallow) internal {
    for (uint256 i = 0; i < addressesToAllow.length; i++) {
      _allowedAddresses.remove(addressesToDisallow[i]);
    }
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
