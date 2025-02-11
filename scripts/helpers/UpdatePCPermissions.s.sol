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


contract UpdatePCPermissionsSonic is UpdatePayloadsControllerPermissions {
  function targetOwner() public pure override returns (address) {
    return 0x7b62461a3570c6AC8a9f8330421576e417B71EE7; // Executor Lvl 1
  }

  function targetGovernanceGuardian() public pure override returns (address) {
    return 0x63C4422D6cc849549daeb600B7EcE52bD18fAd7f;
  }

  function govContractsToUpdate() public pure override returns (address[] memory) {
    address[] memory contracts = new address[](1);
    contracts[0] = address(0x0846C28Dd54DEA4Fd7Fb31bcc5EB81673D68c695); // PC
    return contracts;
  }
}

contract Sonic is Script, UpdatePCPermissionsSonic {
  function run() external {
    vm.startBroadcast();
    
    _changeOwnerAndGuardian();
    
    vm.stopBroadcast();
  }
}