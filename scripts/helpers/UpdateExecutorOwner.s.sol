// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';

abstract contract UpdateExecutorOwner {
  function targetOwner() public pure virtual returns (address);

  function executor() public pure virtual returns (address);

  function _changeOwner(
  ) internal {
    require(targetOwner() != address(0), 'NEW_OWNER_CANT_BE_0');
    require(executor() != address(0), 'PAYLOADS_CONTROLLER_CANT_BE_0');

      if (Ownable(executor()).owner() != targetOwner()) {
        Ownable(executor()).transferOwnership(targetOwner());
      }
  }
}

contract UpdateExecutorPermissionsMantle is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0xF089f77173A3009A98c45f49D547BF714A7B1e01; // PC
  }

  function executor() public pure override returns (address) {
    return 0x70884634D0098782592111A2A6B8d223be31CB7b; // Executor Lvl 1
  }

}

contract Mantle is Script, UpdateExecutorPermissionsMantle {
  function run() external {
    vm.startBroadcast();
    
    _changeOwner();
    
    vm.stopBroadcast();
  }
}

contract UpdateExecutorPermissionsSoneium is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x44D73D7C4b2f98F426Bf8B5e87628d9eE38ef0Cf; // PC
  }

  function executor() public pure override returns (address) {
    return 0x47aAdaAE1F05C978E6aBb7568d11B7F6e0FC4d6A; // Executor Lvl 1
  }

}

contract Soneium is Script, UpdateExecutorPermissionsSoneium {
  function run() external {
    vm.startBroadcast();

    _changeOwner();
    
    vm.stopBroadcast();
  }
}