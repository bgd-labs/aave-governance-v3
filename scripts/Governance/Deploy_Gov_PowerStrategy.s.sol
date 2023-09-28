// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {GovernancePowerStrategy} from '../../src/contracts/GovernancePowerStrategy.sol';
import {GovernancePowerStrategyTest} from '../extendedContracts/StrategiesTest.sol';

abstract contract BaseDeployGovPowerStrategy is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    if (TRANSACTION_NETWORK() == ChainIds.ETHEREUM) {
      addresses.governancePowerStrategy = address(
        new GovernancePowerStrategy()
      );
    } else {
      addresses.governancePowerStrategy = address(
        new GovernancePowerStrategyTest()
      );
    }
  }
}

contract Ethereum is BaseDeployGovPowerStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is BaseDeployGovPowerStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}
