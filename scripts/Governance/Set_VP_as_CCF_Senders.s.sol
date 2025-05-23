// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseSetCCFApprovedSenders} from 'adi-deploy/scripts/ccc/Set_CCF_Approved_Senders.s.sol';
import '../GovBaseScript.sol';

abstract contract BaseSetVPAsCCFSender is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    GovDeployerHelpers.Addresses memory govAddresses = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm);

    address[] memory sendersToApprove = new address[](3);
    sendersToApprove[0] = govAddresses.votingPortal_Eth_Eth;
    sendersToApprove[1] = govAddresses.votingPortal_Eth_Avax;
    sendersToApprove[2] = govAddresses.votingPortal_Eth_Pol;

    return sendersToApprove;
  }
}

contract Ethereum is BaseSetVPAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is BaseSetVPAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}
