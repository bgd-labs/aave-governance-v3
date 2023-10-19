// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {IGovernance_V2_5, Governance_V2_5} from '../../src/contracts/governance_2_5/Governance_V2_5.sol';

abstract contract BaseDeployGovernance is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    // deploy governance.
    IGovernance_V2_5 governanceImpl = new Governance_V2_5();
  }
}

contract Ethereum is BaseDeployGovernance {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}
