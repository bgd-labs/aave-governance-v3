// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import {OwnableWithGuardian, IWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

abstract contract UpdatePayloadsControllerPermissions {
  function targetOwner() public pure virtual returns (address);

  function targetGovernanceGuardian() public pure virtual returns (address);

  function govContractsToUpdate() public pure virtual returns (address[] memory);

  function _changeOwnerAndGuardian(
    address owner,
    address guardian,
    address[] memory contracts
  ) internal {
    require(owner != address(0), 'NEW_OWNER_CANT_BE_0');
    require(guardian != address(0), 'NEW_GUARDIAN_CANT_BE_0');

    for (uint256 i = 0; i < contracts.length; i++) {
      OwnableWithGuardian contractWithAC = OwnableWithGuardian(contracts[i]);
      try contractWithAC.guardian() returns (address currentGuardian) {
        if (currentGuardian != guardian) {
          IWithGuardian(contracts[i]).updateGuardian(guardian);
        }
      } catch {}

      if (contractWithAC.owner() != owner) {
        contractWithAC.transferOwnership(owner);
      }
    }
  }

  function _changeOwnerAndGuardian() internal {
    _changeOwnerAndGuardian(targetOwner(), targetGovernanceGuardian(), govContractsToUpdate());
  }
}


contract UpdatePCPermissionsCelo is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x1dF462e2712496373A347f8ad10802a5E95f053D;
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x056E4C4E80D1D14a637ccbD0412CDAAEc5B51F4E;
  }

  function govContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0xE48E10834C04E394A04BF22a565D063D40b9FA42);
    return contracts;
  }
}

contract Celo is Script, UpdatePCPermissionsCelo {
  function run() external {
    vm.startBroadcast();
    
    _changeOwnerAndGuardian();
    
    vm.stopBroadcast();
  }
}