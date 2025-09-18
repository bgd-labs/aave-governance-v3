// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {IVotingStrategy} from '../../src/contracts/voting/interfaces/IVotingStrategy.sol';
import {VotingMachine, IVotingMachine} from '../../src/contracts/voting/VotingMachine.sol';

abstract contract BaseDeployVotingMachine is GovBaseScript {
  function getSendVoteResultsGasLimit() public view virtual returns (uint256) {
    return 250_000;
  }

  function GOVERNANCE_NETWORK() public view virtual returns (uint256);

  function VOTING_PORTAL_SALT() public view virtual returns (bytes32);

  function _getVotingPortal(address caller) internal view returns (address) {
    return
      Create3.addressOfWithPreDeployedFactory(
        keccak256(abi.encodePacked(msg.sender, VOTING_PORTAL_SALT())),
        caller
      );
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    GovDeployerHelpers.Addresses memory govAddresses = _getAddresses(
      GOVERNANCE_NETWORK()
    );

    // deploy voting machine
    addresses.votingMachine = address(
      new VotingMachine(
        addresses.crossChainController,
        getSendVoteResultsGasLimit(),
        govAddresses.chainId,
        IVotingStrategy(addresses.votingStrategy),
        _getVotingPortal(govAddresses.create3Factory),
        govAddresses.governance
      )
    );
  }
}

contract Ethereum is BaseDeployVotingMachine {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_ETH_SALT;
  }
}

contract Avalanche is BaseDeployVotingMachine {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_AVAX_SALT;
  }
}

contract Polygon is BaseDeployVotingMachine {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_POL_SALT;
  }
}

contract Binance is BaseDeployVotingMachine {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function GOVERNANCE_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function VOTING_PORTAL_SALT() public pure override returns (bytes32) {
    return Constants.VOTING_PORTAL_ETH_BNB_SALT;
  }
}
