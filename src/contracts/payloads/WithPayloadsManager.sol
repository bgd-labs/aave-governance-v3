// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWithPayloadsManager} from './interfaces/IWithPayloadsManager.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

abstract contract WithPayloadsManager is OwnableWithGuardian, IWithPayloadsManager {
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

  function payloadsManager() public view override returns (address) {
    return _payloadsManager;
  }

  function updatePayloadsManager(address newPayloadsManager) external override onlyOwnerOrGuardian {
    _updatePayloadsManager(newPayloadsManager);
  }

  function _updatePayloadsManager(address newPayloadsManager) internal {
    address oldPayloadsManager = _payloadsManager;
    _payloadsManager = newPayloadsManager;
    emit PayloadsManagerUpdated(oldPayloadsManager, newPayloadsManager);
  }

  function _checkPayloadsManager() internal view {
    require(_msgSender() == payloadsManager(), 'ONLY_BY_PAYLOAD_MANAGER');
  }

  function _checkPayloadsManagerOrGuardian() internal view {
    require(
      _msgSender() == payloadsManager() || _msgSender() == guardian(),
      'ONLY_BY_PAYLOAD_MANAGER_OR_GUARDIAN'
    );
  }
}
