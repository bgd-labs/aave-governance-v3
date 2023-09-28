// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
//
//import 'forge-std/Script.sol';
//import 'forge-std/Vm.sol';
//import {BaseScript} from '../GovBaseScript.sol';
//import {DeployerHelpers} from './DeployerHelpers.sol';
//import {GovernancePowerStrategy} from '../../src/contracts/GovernancePowerStrategy.sol';
//import {IGovernanceCore, IGovernancePowerStrategy} from '../../src/interfaces/IGovernanceCore.sol';
//
//contract UpdateGovernancePowerStrategy is BaseScript {
//  string path = './deployments/eth-deployments.json';
//
//  function run() external broadcast {
//    // ----------------- Persist addresses -----------------------------------------------------------------------------
//    DeployerHelpers.Addresses memory addresses = DeployerHelpers.decodeJson(
//      path,
//      vm
//    );
//    // -----------------------------------------------------------------------------------------------------------------
//
//    IGovernancePowerStrategy governancePowerStrategy = new GovernancePowerStrategy();
//    IGovernanceCore(addresses.governance).setPowerStrategy(
//      governancePowerStrategy
//    );
//
//    // ----------------- Persist addresses -----------------------------------------------------------------------------
//    addresses.governancePowerStrategy = address(governancePowerStrategy);
//    DeployerHelpers.encodeJson(path, addresses, vm);
//    // -----------------------------------------------------------------------------------------------------------------
//  }
//}
