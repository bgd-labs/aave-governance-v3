// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {VotingPortal, IVotingPortal} from '../../src/contracts/VotingPortal.sol';
import '../GovBaseScript.sol';

// voting portal for eth - op
abstract contract BaseDeployVotingPortals is GovBaseScript {
  function VOTING_MACHINE_NETWORK() public view virtual returns (uint256);

  function getProposalGasLimit() public view virtual returns (uint128) {
    return 300_000;
  }

  function VOTING_PORTAL_SALT() public view virtual returns (bytes32);

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    // ----------------- Persist addresses -----------------------------------------------------------------------------
    GovDeployerHelpers.Addresses memory votingAddresses = _getAddresses(
      VOTING_MACHINE_NETWORK()
    );

    bytes memory encodedParams = abi.encode(
      addresses.crossChainController,
      addresses.governance,
      votingAddresses.votingMachine,
      votingAddresses.chainId,
      getProposalGasLimit(),
      addresses.owner
    );
    bytes memory code = type(VotingPortal).creationCode;

    // deploy Voting portal
    address votingPortal = ICreate3Factory(addresses.create3Factory).create(
      VOTING_PORTAL_SALT(),
      abi.encodePacked(code, encodedParams)
    );

    if (
      VOTING_MACHINE_NETWORK() == ChainIds.AVALANCHE ||
      VOTING_MACHINE_NETWORK() == TestNetChainIds.AVALANCHE_FUJI
    ) {
      addresses.votingPortal_Eth_Avax = address(votingPortal);
    } else if (
      VOTING_MACHINE_NETWORK() == ChainIds.POLYGON ||
      VOTING_MACHINE_NETWORK() == TestNetChainIds.POLYGON_AMOY
    ) {
      addresses.votingPortal_Eth_Pol = address(votingPortal);
    } else if (
      VOTING_MACHINE_NETWORK() == ChainIds.ETHEREUM ||
      VOTING_MACHINE_NETWORK() == TestNetChainIds.ETHEREUM_SEPOLIA
    ) {
      addresses.votingPortal_Eth_Eth = address(votingPortal);
    } else if (
      VOTING_MACHINE_NETWORK() == ChainIds.BNB ||
      VOTING_MACHINE_NETWORK() == TestNetChainIds.BNB_TESTNET
    ) {
      addresses.votingPortal_Eth_BNB = address(votingPortal);
    }
  }
}

contract Ethereum_Ethereum is BaseDeployVotingPortals {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_MACHINE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_ETH_SALT;
  }
}

contract Ethereum_Avalanche is BaseDeployVotingPortals {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_MACHINE_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_AVAX_SALT;
  }
}

contract Ethereum_Polygon is BaseDeployVotingPortals {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_MACHINE_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_POL_SALT;
  }
}

contract Ethereum_Binance is BaseDeployVotingPortals {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_MACHINE_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_BNB_SALT;
  }
}
