// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import {GovernancePowerStrategy} from '../../src/contracts/GovernancePowerStrategy.sol';

contract VotingStrategyTest is VotingStrategy {
  constructor(address dataWarehouse) VotingStrategy(dataWarehouse) {}

  function AAVE() public pure override returns (address) {
    return 0x64033B2270fd9D6bbFc35736d2aC812942cE75fE;
  }

  function STK_AAVE() public pure override returns (address) {
    return 0xA4FDAbdE9eF3045F0dcF9221bab436B784B7e42D;
  }

  function A_AAVE() public pure override returns (address) {
    return 0x7d9EB767eEc260d1bCe8C518276a894aE5535F04;
  }
}

contract GovernancePowerStrategyTest is GovernancePowerStrategy {
  function AAVE() public pure override returns (address) {
    return 0x64033B2270fd9D6bbFc35736d2aC812942cE75fE;
  }

  function STK_AAVE() public pure override returns (address) {
    return 0xA4FDAbdE9eF3045F0dcF9221bab436B784B7e42D;
  }

  function A_AAVE() public pure override returns (address) {
    return 0x7d9EB767eEc260d1bCe8C518276a894aE5535F04;
  }
}
