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
      addresses.governanceDataHelper = address(
        new GovernanceDataHelper{salt: Constants.GOV_DATA_HELPER_SALT}()
      );
      addresses.metaDelegateHelper = address(
        new MetaDelegateHelper{salt: Constants.MD_DATA_HELPER_SALT}()
      );
    }

    if (addresses.votingMachine != address(0)) {
      addresses.votingMachineDataHelper = address(
        new VotingMachineDataHelper{salt: Constants.VM_DATA_HELPER_SALT}()
      );
    }

    if (addresses.payloadsController != address(0)) {
      addresses.payloadsControllerDataHelper = address(
        new PayloadsControllerDataHelper{salt: Constants.PC_DATA_HELPER_SALT}()
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

contract Ethereum_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Polygon_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Avalanche_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}

contract Arbitrum_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ARBITRUM_GOERLI;
  }
}

contract Optimism_testnet is BaseContractHelpers {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.OPTIMISM_GOERLI;
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
