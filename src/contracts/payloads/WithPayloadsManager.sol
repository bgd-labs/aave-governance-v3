// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWithPayloadsManager} from './interfaces/IWithPayloadsManager.sol';
import {OwnableWithGuardian} from 'aave-delivery-infrastructure/contracts/old-oz/OwnableWithGuardian.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title WithPayloadsManager
 * @author BGD Labs
 * @dev Contract module which provides a basic access control mechanism, where
 * there are accounts (owner, guardian, and payloads manager) which can be granted
 * exclusive access to specific functions.
 * @notice By default, all the roles will be assigned to the one that deploys the contract. This
 * can later be changed with appropriate functions.
 */
contract WithPayloadsManager is OwnableWithGuardian, IWithPayloadsManager {
  address private _payloadsManager;

  constructor() {
    _updatePayloadsManager(_msgSender());
  }

  modifier onlyPayloadsManager() {
    require(_msgSender() == payloadsManager(), Errors.ONLY_BY_PAYLOADS_MANAGER);
    _;
  }

  modifier onlyPayloadsManagerOrGuardian() {
    require(
      _msgSender() == payloadsManager() || _msgSender() == guardian(),
      Errors.ONLY_BY_PAYLOADS_MANAGER_OR_GUARDIAN
    );
    _;
  }

  /// @inheritdoc IWithPayloadsManager
  function payloadsManager() public view returns (address) {
    return _payloadsManager;
  }

  /// @inheritdoc IWithPayloadsManager
  function updatePayloadsManager(
    address newPayloadsManager
  ) external onlyOwnerOrGuardian {
    _updatePayloadsManager(newPayloadsManager);
  }

  /**
   * @dev updates the address of the payloads manager
   * @param newPayloadsManager the new address of the payloads manager.
   */
  function _updatePayloadsManager(address newPayloadsManager) internal {
    _payloadsManager = newPayloadsManager;
    emit PayloadsManagerUpdated(newPayloadsManager);
  }
}
