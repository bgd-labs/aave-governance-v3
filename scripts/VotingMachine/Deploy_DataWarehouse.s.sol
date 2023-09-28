// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {DataWarehouse} from '../../src/contracts/voting/DataWarehouse.sol';

abstract contract BaseDeployDataWarehouse is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.dataWarehouse = address(new DataWarehouse());
  }
}

contract Ethereum is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Avalanche is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Binance is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Ethereum_testnet is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Binance_testnet is BaseDeployDataWarehouse {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}
