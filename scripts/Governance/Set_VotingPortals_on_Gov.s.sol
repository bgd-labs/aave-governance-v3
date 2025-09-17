// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Governance} from '../../src/contracts/Governance.sol';
import '../GovBaseScript.sol';

abstract contract BaseSetVotingPortals is GovBaseScript {
  function _execute(
    GovDeployerHelpers.Addresses memory addresses
  ) internal override {
    // add voting portal to governance
    address[] memory votingPortalsToAdd = new address[](3);
    votingPortalsToAdd[0] = addresses.votingPortal_Eth_Eth;
    votingPortalsToAdd[1] = addresses.votingPortal_Eth_Avax;
    votingPortalsToAdd[2] = addresses.votingPortal_Eth_Pol;

    Governance(payable(addresses.governance)).addVotingPortals(
      votingPortalsToAdd
    );
  }
}

contract Ethereum is BaseSetVotingPortals {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}
