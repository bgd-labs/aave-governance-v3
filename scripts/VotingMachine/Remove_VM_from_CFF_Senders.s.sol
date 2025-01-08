// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseRemoveCCFApprovedSenders} from 'adi-deploy/scripts/ccc/Remove_CCF_Approved_Senders.s.sol';
import '../GovBaseScript.sol';

abstract contract BaseRemoveVMAsCCFSender is BaseRemoveCCFApprovedSenders {
  function getSendersToRemove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory govAddresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);

    address[] memory sendersToRemove = new address[](1);
    sendersToRemove[0] = govAddresses.votingMachine;

    return sendersToRemove;
  }
}

contract Ethereum is BaseRemoveVMAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is BaseRemoveVMAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Avalanche is BaseRemoveVMAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return ChainIds.AVALANCHE;
  }
}

contract Avalanche_testnet is BaseRemoveVMAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.AVALANCHE_FUJI;
  }
}
