// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VotingStrategy} from '../../src/contracts/voting/VotingStrategy.sol';
import '../GovBaseScript.sol';
import {VotingStrategyTest} from '../extendedContracts/StrategiesTest.sol';

abstract contract BaseDeployVotingStrategy is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    if (
      TRANSACTION_NETWORK() == ChainIds.ETHEREUM ||
      TRANSACTION_NETWORK() == ChainIds.AVALANCHE ||
      TRANSACTION_NETWORK() == ChainIds.POLYGON ||
      TRANSACTION_NETWORK() == ChainIds.BNB
    ) {
      addresses.votingStrategy = address(
        new VotingStrategy{salt: Constants.VOTING_STRATEGY_SALT}(
          addresses.dataWarehouse
        )
      );
    } else {
      addresses.votingStrategy = address(
        new VotingStrategyTest{salt: Constants.VOTING_STRATEGY_SALT}(
          addresses.dataWarehouse
        )
      );
    }
  }
}

contract Ethereum is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Binance is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Ethereum_testnet is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Binance_testnet is BaseDeployVotingStrategy {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}
