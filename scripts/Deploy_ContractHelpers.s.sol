// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {GovernanceDataHelper} from '../src/contracts/dataHelpers/GovernanceDataHelper.sol';
import {PayloadsControllerDataHelper} from '../src/contracts/dataHelpers/PayloadsControllerDataHelper.sol';
import {VotingMachineDataHelper} from '../src/contracts/dataHelpers/VotingMachineDataHelper.sol';
import {MetaDelegateHelper} from '../src/contracts/dataHelpers/MetaDelegateHelper.sol';
import './GovBaseScript.sol';

abstract contract BaseContractHelpers is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    if (addresses.governance != address(0)) {
      addresses.governanceDataHelper = address(new GovernanceDataHelper());
      addresses.metaDelegateHelper = address(new MetaDelegateHelper());
    }

    if (addresses.votingMachine != address(0)) {
      addresses.votingMachineDataHelper = address(
        new VotingMachineDataHelper()
      );
    }

    if (addresses.payloadsController != address(0)) {
      addresses.payloadsControllerDataHelper = address(
        new PayloadsControllerDataHelper()
      );
    }
  }
}

contract Ethereum is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Avalanche is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Arbitrum is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ARBITRUM;
  }
}

contract Optimism is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.OPTIMISM;
  }
}

contract Metis is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.METIS;
  }
}

contract Binance is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Base is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BASE;
  }
}

contract Gnosis is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.GNOSIS;
  }
}

contract Zkevm is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON_ZK_EVM;
  }
}

contract Scroll is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.SCROLL;
  }
}

contract Zksync is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ZKSYNC;
  }
}

contract Linea is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.LINEA;
  }
}

contract Celo is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.CELO;
  }
}

contract Mantle is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.MANTLE;
  }
}

contract Ethereum_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Polygon_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_AMOY;
  }
}

contract Avalanche_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Arbitrum_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_SEPOLIA;
  }
}

contract Optimism_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_SEPOLIA;
  }
}

contract Metis_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.METIS_TESTNET;
  }
}

contract Binance_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Zksync_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ZKSYNC_SEPOLIA;
  }
}
