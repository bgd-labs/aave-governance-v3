// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
//
//import 'forge-std/Script.sol';
//import 'forge-std/Vm.sol';
//import {IGovernanceCore} from '../../src/interfaces/IGovernanceCore.sol';
//import {DeployerHelpers} from './DeployerHelpers.sol';
//
//contract ActivateVoting {
//  uint256 PROPOSAL_ID = 5;
//
//  function _deploy(string memory path, Vm vm) public {
//    // ----------------- Persist addresses -----------------------------------------------------------------------------
//    DeployerHelpers.Addresses memory addresses = DeployerHelpers.decodeJson(
//      path,
//      vm
//    );
//    // -----------------------------------------------------------------------------------------------------------------
//
//    IGovernanceCore(addresses.governance).activateVoting(PROPOSAL_ID);
//  }
//}
//
//contract Ethereum is ActivateVoting, Script {
//  string path = './deployments/eth-deployments.json';
//
//  function run() public {
//    vm.startBroadcast();
//
//    _deploy(path, vm);
//
//    vm.stopBroadcast();
//  }
//}
//
//contract Avalanche is ActivateVoting, Script {
//  string path = './deployments/avax-deployments.json';
//
//  function run() public {
//    vm.startBroadcast();
//
//    _deploy(path, vm);
//
//    vm.stopBroadcast();
//  }
//}
//
//contract Optimism is ActivateVoting, Script {
//  string path = './deployments/op-deployments.json';
//
//  function run() public {
//    vm.startBroadcast();
//
//    _deploy(path, vm);
//
//    vm.stopBroadcast();
//  }
//}
