// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import {IGovernance_V2_5, Governance_V2_5} from '../../src/contracts/governance_2_5/Governance_V2_5.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';

contract Governance_V2_5_Test is Test {
  IGovernance_V2_5 govV2_5Impl;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'), 18376320);
    govV2_5Impl = new Governance_V2_5();

    hoax(AaveGovernanceV2.SHORT_EXECUTOR);
    //    ().upgradeToAndCall(
    //  address(govV2_5Impl),
    //
    //    );
  }
}
