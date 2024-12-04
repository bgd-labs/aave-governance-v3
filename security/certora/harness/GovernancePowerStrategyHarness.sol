pragma solidity ^0.8.0;

import {GovernancePowerStrategy} from '../../../src/contracts/GovernancePowerStrategy.sol';

contract GovernancePowerStrategyHarness is GovernancePowerStrategy
{
  function getVotingAsset(uint256 index) public pure returns (address) {
    return getVotingAssetList()[index];
  }

  function getVotingAssetsNumber() public pure returns (uint256) {
    return getVotingAssetList().length;
  }
}
