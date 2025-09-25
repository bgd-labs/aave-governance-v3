// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../GovBaseScript.sol';
import {IGovernanceCore} from '../../src/interfaces/IGovernanceCore.sol';

contract Ethereum is GovBaseScript {
  function TRANSACTION_NETWORK()
    public
    pure
    virtual
    override
    returns (uint256)
  {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    address[] memory votingPortalsToRemove = new address[](2);

    votingPortalsToRemove[0] = addresses.votingPortal_Eth_Eth;
    votingPortalsToRemove[1] = addresses.votingPortal_Eth_Avax;

    IGovernanceCore(addresses.governance).removeVotingPortals(
      votingPortalsToRemove
    );

    addresses.votingPortal_Eth_Eth = address(0);
    addresses.votingPortal_Eth_Avax = address(0);
  }
}
