// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {Executor} from '../../src/contracts/payloads/Executor.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';

abstract contract BaseDeployExecutorLvl1 is GovBaseScript {
  function getExecutorOwner() public view virtual returns (address) {
    return msg.sender;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    addresses.executorLvl1 = address(new Executor());

    if (addresses.chainId == ChainIds.ETHEREUM) {
      Ownable(addresses.executorLvl1).transferOwnership(getExecutorOwner());
    }
  }
}

contract Ethereum is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }
}

contract Avalanche is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Polygon is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Optimism is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Arbitrum is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Metis is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }
}

contract Base is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }

  function getExecutorOwner() public pure override returns (address) {
    return AaveGovernanceV2.SHORT_EXECUTOR;
  }
}

contract Binance is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Gnosis is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Zksync is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Scroll is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Sonic is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONIC;
  }
}

contract Mantle is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }
}

contract Ink is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.INK;
  }
}

contract Soneium is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SONEIUM;
  }
}

contract Ethereum_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Polygon_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Optimism_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_SEPOLIA;
  }
}

contract Arbitrum_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_SEPOLIA;
  }
}

contract Metis_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Zksync_testnet is BaseDeployExecutorLvl1 {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZKSYNC_SEPOLIA;
  }
}
