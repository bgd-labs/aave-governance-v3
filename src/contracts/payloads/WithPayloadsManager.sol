// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWithPayloadsManager} from './interfaces/IWithPayloadsManager.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there are accounts(owner, guardian and payloads manager) which can be granted
 * exclusive access to specific functions.
 *
 * By default, all the roles will be assigned to the one that deploys the contract. This
 * can later be changed with appropriate functions.
 */
contract WithPayloadsManager is OwnableWithGuardian, IWithPayloadsManager {
  address private _payloadsManager;

  constructor() {
    _updatePayloadsManager(_msgSender());
  }

  modifier onlyPayloadsManager() {
    _checkPayloadsManager();
    _;
  }

  modifier onlyPayloadsManagerOrGuardian() {
    _checkPayloadsManagerOrGuardian();
    _;
  }

  /// @inheritdoc IWithPayloadsManager
  function payloadsManager() public view override returns (address) {
    return _payloadsManager;
  }

  /// @inheritdoc IWithPayloadsManager
  function updatePayloadsManager(address newPayloadsManager) external override onlyOwnerOrGuardian {
    _updatePayloadsManager(newPayloadsManager);
  }

  function _updatePayloadsManager(address newPayloadsManager) internal {
    _payloadsManager = newPayloadsManager;
    emit PayloadsManagerUpdated(newPayloadsManager);
  }

  function _checkPayloadsManager() internal view {
    require(_msgSender() == payloadsManager(), 'ONLY_BY_PAYLOADS_MANAGER');
  }

  function _checkPayloadsManagerOrGuardian() internal view {
    require(
      _msgSender() == payloadsManager() || _msgSender() == guardian(),
      'ONLY_BY_PAYLOADS_MANAGER_OR_GUARDIAN'
    );
  }
}
