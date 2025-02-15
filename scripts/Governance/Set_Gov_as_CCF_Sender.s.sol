// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import {BaseSetCCFApprovedSenders} from 'adi-deploy/scripts/ccc/Set_CCF_Approved_Senders.s.sol';
import '../GovBaseScript.sol';

abstract contract BaseSetGovAsCCFSender is BaseSetCCFApprovedSenders {
  function getSendersToApprove()
    public
    view
    override
    returns (address[] memory)
  {
    address governance = GovDeployerHelpers
      .getAddresses(TRANSACTION_NETWORK(), vm)
      .governance;
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = governance;

    return sendersToApprove;
  }
}

contract Ethereum is BaseSetGovAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is BaseSetGovAsCCFSender {
  function TRANSACTION_NETWORK() internal pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}
