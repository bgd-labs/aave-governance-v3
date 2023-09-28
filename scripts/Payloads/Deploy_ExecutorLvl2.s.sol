// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveAddressBook.sol';

abstract contract BaseDeployExecutorLvl2 is GovBaseScript {
  function getExecutorOwner() public view virtual returns (address) {
    return msg.sender;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.executorLvl2 = address(new Executor());

    if (addresses.chainId == ChainIds.ETHEREUM) {
      Ownable(addresses.executorLvl2).transferOwnership(getExecutorOwner());
    }
  }
}

contract Ethereum is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.LONG_EXECUTOR;
  }
}

contract Avalanche is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Ethereum_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Optimism_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_GOERLI;
  }
}

contract Arbitrum_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_GOERLI;
  }
}

contract Metis_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseDeployExecutorLvl2 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}
