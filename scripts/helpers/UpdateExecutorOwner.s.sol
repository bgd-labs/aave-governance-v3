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

contract UpdateExecutorPermissionsSonic is UpdateExecutorOwner {
  function targetOwner() public pure override returns (address) {
    return 0x0846C28Dd54DEA4Fd7Fb31bcc5EB81673D68c695; // PC
  }

  function executor() public pure override returns (address) {
    return 0x7b62461a3570c6AC8a9f8330421576e417B71EE7; // Executor Lvl 1
  }

}

contract Sonic is Script, UpdateExecutorPermissionsSonic {
  function run() external {
    vm.startBroadcast();
    
    _changeOwner();
    
    vm.stopBroadcast();
  }
}